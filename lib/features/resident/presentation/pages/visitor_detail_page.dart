import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/visitor_pass.dart';
import '../../../../state/app_notifier.dart';

int _hash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return h;
}

List<Color> qrCells(String code) {
  final h = _hash(code);
  return List.generate(64, (i) => ((h >> (i % 24)) ^ (i * 7)) % 3 == 0 ? McColors.text : McColors.bg);
}

class VisitorDetailPage extends ConsumerStatefulWidget {
  const VisitorDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<VisitorDetailPage> createState() => _VisitorDetailPageState();
}

class _VisitorDetailPageState extends ConsumerState<VisitorDetailPage> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _revokePass(VisitorPass pass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke this pass?'),
        content: Text('${pass.name} will no longer be able to use this pass code. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: McColors.text),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: McColors.danger),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(appStateProvider.notifier).revokeVisitorPass(widget.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pass revoked')),
      );
    }
  }

  void _sharePass(VisitorPass pass) async {
    // This message goes to the visitor themselves (so they can present the
    // code at the gate) — status, vehicle, phone, and visit duration are
    // for the resident's own reference on this page, not something the
    // visitor needs to see.
    final message = StringBuffer()
      ..writeln('Visitor Pass for ${pass.name}')
      ..writeln('Code: ${pass.code}');
    try {
      // sharePositionOrigin is required on iPad (the share sheet has
      // nowhere to popover from without it) and harmless elsewhere — worth
      // always providing rather than only patching it in when an iPad
      // actually hits the missing-anchor failure.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      await Share.share(
        message.toString(),
        subject: 'Visitor Pass — ${pass.name}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      // The previous fallback message claimed "no share apps available",
      // which is essentially never true on a real device (Messages/Mail
      // are always present) — it was masking whatever the actual failure
      // was. Log the real reason so this is diagnosable next time, and
      // stop asserting a specific cause we can't actually confirm.
      debugPrint('Share.share failed for visitor pass ${pass.id}: $e');
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: message.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the share sheet — pass details copied to clipboard instead")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final passes = ref.watch(appStateProvider).visitorPasses;
    final pass = passes.firstWhere((p) => p.id == widget.id, orElse: () => passes.first);
    final cells = qrCells(pass.code);

    return Column(
      children: [
        const McGenericHeader(title: 'Visitor Pass'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.read(appStateProvider.notifier).refreshResident(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                    child: Column(
                      children: [
                        Text(pass.name, style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: pass.isInside ? McColors.accent2N(100) : McColors.neutralN(200),
                            borderRadius: BorderRadius.circular(McRadii.pill),
                          ),
                          child: Text(
                            _statusLabel(pass),
                            style: McTextStyles.body(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: pass.isInside ? McColors.accent2N(700) : McColors.bodyText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(pass.visitLabel, style: McTextStyles.body(fontSize: 13, color: McColors.bodyText)),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: McColors.surfaceSunken, borderRadius: BorderRadius.circular(McRadii.md)),
                          child: SizedBox(
                            width: context.rs(8 * 12),
                            height: context.rs(8 * 12),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 2, crossAxisSpacing: 2),
                              itemCount: 64,
                              itemBuilder: (context, i) => Container(color: cells[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Fallback code', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                        const SizedBox(height: 4),
                        Text(
                          pass.code,
                          style: McTextStyles.heading(fontSize: 24).copyWith(letterSpacing: 4),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _copyCode(pass.code),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(color: McColors.surfaceSunken, borderRadius: BorderRadius.circular(McRadii.pill)),
                                child: Text(
                                  _copied ? 'Copied!' : 'Copy Code',
                                  style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _sharePass(pass),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(color: McColors.accent2, borderRadius: BorderRadius.circular(McRadii.pill)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.share, size: 15, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Vehicle: ${pass.plate}\nPhone: ${pass.phone}',
                      style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                    ),
                  ),
                  if (pass.status == VisitorPassStatus.active)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: GestureDetector(
                        onTap: () => _revokePass(pass),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: McColors.danger,
                            borderRadius: BorderRadius.circular(McRadii.button),
                          ),
                          child: Text(
                            'Revoke Pass',
                            style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(VisitorPass p) {
    if (p.status == VisitorPassStatus.revoked) return 'REVOKED';
    if (p.status != VisitorPassStatus.active) return 'EXPIRED';
    return p.isInside ? 'INSIDE' : (p.hasEntered ? 'LEFT' : 'ACTIVE');
  }
}