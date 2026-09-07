import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../theme/mc_colors.dart';

/// Renders a project's media — image or short video clip — stored as a
/// base64 data URL (e.g. "data:image/png;base64,..." or
/// "data:video/mp4;base64,..."). The backend returns the same field either
/// way; the MIME prefix decides how it's displayed.
class McDataMedia extends StatefulWidget {
  const McDataMedia({super.key, required this.dataUrl, this.height, this.borderRadius, this.fit = BoxFit.cover});

  final String dataUrl;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  State<McDataMedia> createState() => _McDataMediaState();
}

/// Decoding is cached per `dataUrl` string rather than redone in `build()`
/// (as a StatelessWidget would) — a parent rebuilding for an unrelated
/// reason (e.g. the login page's estate banner re-rendering on every
/// keystroke, since it and the phone/password fields share one watched
/// AppState) used to re-run `base64Decode` and hand `Image.memory` a
/// freshly-allocated `Uint8List` each time. `Uint8List` has no value
/// equality, so `MemoryImage` treated every rebuild as a brand-new image
/// to load rather than the same unchanged photo, causing a visible
/// flicker even though the bytes were byte-for-byte identical.
class _McDataMediaState extends State<McDataMedia> {
  Uint8List? _bytes;
  String? _decodedFor;

  bool get _isVideo => widget.dataUrl.startsWith('data:video/');

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant McDataMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataUrl != oldWidget.dataUrl) _decode();
  }

  void _decode() {
    final dataUrl = widget.dataUrl;
    final commaIndex = dataUrl.indexOf(',');
    final base64Part = commaIndex == -1 ? dataUrl : dataUrl.substring(commaIndex + 1);
    try {
      _bytes = base64Decode(base64Part);
    } catch (_) {
      _bytes = null;
    }
    _decodedFor = dataUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (_decodedFor != widget.dataUrl) _decode();
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();

    final content = _isVideo
        ? _InlineVideo(bytes: bytes, cacheKey: widget.dataUrl.hashCode, height: widget.height)
        : Image.memory(
            bytes,
            height: widget.height,
            width: double.infinity,
            fit: widget.fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );

    return widget.borderRadius == null ? content : ClipRRect(borderRadius: widget.borderRadius!, child: content);
  }
}

/// video_player has no "play from bytes" API, so the decoded clip is
/// written once to a cache file (keyed by content hash, so re-rendering the
/// same update — e.g. list card and detail page — reuses the same file
/// instead of rewriting it) and played from there.
class _InlineVideo extends StatefulWidget {
  const _InlineVideo({required this.bytes, required this.cacheKey, this.height});

  final Uint8List bytes;
  final int cacheKey;
  final double? height;

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ch_media_${widget.cacheKey}.mp4');
      if (!await file.exists()) {
        await file.writeAsBytes(widget.bytes, flush: true);
      }
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        unawaited(controller.dispose());
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final controller = _controller;
    if (controller == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: McColors.accent)),
      );
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (!controller.value.isPlaying)
                  Container(
                    decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
