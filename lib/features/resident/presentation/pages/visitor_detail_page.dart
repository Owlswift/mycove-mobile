import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
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
  return List.generate(64, (i) => ((h >> (i % 24)) ^ (i * 7)) % 3 == 0 ? ChColors.text : ChColors.bg);
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ChColors.danger),
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
    final message = StringBuffer()
      ..writeln('Visitor Pass — ${pass.name}')
      ..writeln('Status: ${_statusLabel(pass)}')
      ..writeln('Code: ${pass.code}')
      ..writeln('Vehicle: ${pass.plate}')
      ..writeln('Phone: ${pass.phone}')
      ..writeln(pass.visitLabel);
    try {
      await Share.share(message.toString(), subject: 'Visitor Pass — ${pass.name}');
    } catch (e) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: message.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No share apps available — pass details copied to clipboard')),
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
        const ChGenericHeader(title: 'Visitor Pass'),
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
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                    child: Column(
                      children: [
                        Text(pass.name, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: pass.isInside ? ChColors.accent2N(100) : ChColors.neutralN(200),
                            borderRadius: BorderRadius.circular(ChRadii.pill),
                          ),
                          child: Text(
                            _statusLabel(pass),
                            style: ChTextStyles.body(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: pass.isInside ? ChColors.accent2N(700) : ChColors.neutralN(600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(pass.visitLabel, style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: ChColors.surfaceSunken, borderRadius: BorderRadius.circular(ChRadii.md)),
                          child: SizedBox(
                            width: 8 * 12,
                            height: 8 * 12,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 2, crossAxisSpacing: 2),
                              itemCount: 64,
                              itemBuilder: (context, i) => Container(color: cells[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Fallback code', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                        const SizedBox(height: 4),
                        Text(
                          pass.code,
                          style: ChTextStyles.heading(fontSize: 24).copyWith(letterSpacing: 4),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _copyCode(pass.code),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(color: ChColors.surfaceSunken, borderRadius: BorderRadius.circular(ChRadii.pill)),
                                child: Text(
                                  _copied ? 'Copied!' : 'Copy Code',
                                  style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _sharePass(pass),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.pill)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.share, size: 15, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
                      style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
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
                            color: ChColors.danger,
                            borderRadius: BorderRadius.circular(ChRadii.button),
                          ),
                          child: Text(
                            'Revoke Pass',
                            style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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