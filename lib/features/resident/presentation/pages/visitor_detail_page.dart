import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final passes = ref.watch(appStateProvider).visitorPasses;
    final pass = passes.firstWhere((p) => p.id == widget.id, orElse: () => passes.first);
    final cells = qrCells(pass.code);

    return Column(
      children: [
        const ChGenericHeader(title: 'Visitor Pass'),
        Expanded(
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
                      const SizedBox(height: 2),
                      Text(pass.window, style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: ChColors.bg, borderRadius: BorderRadius.circular(ChRadii.md)),
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
                      GestureDetector(
                        onTap: () => _copyCode(pass.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(color: ChColors.bg, borderRadius: BorderRadius.circular(ChRadii.pill)),
                          child: Text(
                            _copied ? 'Copied!' : 'Copy Code',
                            style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
