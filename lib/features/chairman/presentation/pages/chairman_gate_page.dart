import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/chairman_widgets.dart';

/// Who has come through the gate and who they were visiting — the same log
/// the guards keep, read-only.
class ChairmanGatePage extends ConsumerWidget {
  const ChairmanGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return ChairmanList(
      onRefresh: notifier.refreshChairman,
      emptyIcon: Icons.shield_outlined,
      emptyMessage: 'No gate activity recorded yet.',
      children: [
        for (final e in s.accessLog)
          ChairmanCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.visitor, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (e.residentName != null)
                        Text(
                          [
                            'Visiting ${e.residentName}',
                            if (e.residentHouse != null && e.residentHouse!.isNotEmpty) e.residentHouse!,
                          ].join(' · '),
                          style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        e.exit == null ? 'In ${e.entry}' : 'In ${e.entry}  ·  Out ${e.exit}',
                        style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                      ),
                    ],
                  ),
                ),
                if (e.exit == null) const StatusPill('Inside', color: McColors.accent2),
              ],
            ),
          ),
      ],
    );
  }
}
