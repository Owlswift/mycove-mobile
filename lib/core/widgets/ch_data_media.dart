import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../theme/ch_colors.dart';

/// Renders a project's media — image or short video clip — stored as a
/// base64 data URL (e.g. "data:image/png;base64,..." or
/// "data:video/mp4;base64,..."). The backend returns the same field either
/// way; the MIME prefix decides how it's displayed.
class ChDataMedia extends StatelessWidget {
  const ChDataMedia({super.key, required this.dataUrl, this.height, this.borderRadius, this.fit = BoxFit.cover});

  final String dataUrl;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  bool get _isVideo => dataUrl.startsWith('data:video/');

  @override
  Widget build(BuildContext context) {
    final commaIndex = dataUrl.indexOf(',');
    final base64Part = commaIndex == -1 ? dataUrl : dataUrl.substring(commaIndex + 1);
    Uint8List bytes;
    try {
      bytes = base64Decode(base64Part);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final content = _isVideo
        ? _InlineVideo(bytes: bytes, cacheKey: dataUrl.hashCode, height: height)
        : Image.memory(
            bytes,
            height: height,
            width: double.infinity,
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );

    return borderRadius == null ? content : ClipRRect(borderRadius: borderRadius!, child: content);
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
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: ChColors.accent)),
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
