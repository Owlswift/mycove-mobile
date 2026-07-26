import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

class GuardLogPage extends ConsumerWidget {
  const GuardLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: s.accessLog.length,
      itemBuilder: (context, i) {
        final log = s.accessLog[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.visitor, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('In: ${log.entry}', style: ChTextStyles.body(fontSize: 12.5, color: ChColors.neutralN(600))),
              Text('Out: ${log.exit ?? 'Still on site'}', style: ChTextStyles.body(fontSize: 12.5, color: ChColors.neutralN(600))),
            ],
          ),
        );
      },
    );
  }
}
