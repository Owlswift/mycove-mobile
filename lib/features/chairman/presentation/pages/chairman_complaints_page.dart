import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/chairman_widgets.dart';

/// Every complaint residents have raised, newest first. Read-only — the
/// chairman can see what's open and unresolved but status changes stay with
/// the estate admin.
class ChairmanComplaintsPage extends ConsumerStatefulWidget {
  const ChairmanComplaintsPage({super.key});

  @override
  ConsumerState<ChairmanComplaintsPage> createState() => _ChairmanComplaintsPageState();
}

class _ChairmanComplaintsPageState extends ConsumerState<ChairmanComplaintsPage> {
  bool _openOnly = true;

  Color _statusColor(String status) => switch (status) {
    'RESOLVED' => McColors.accent2,
    'IN_REVIEW' => McColors.warning,
    _ => McColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final all = s.chairman.complaints;
    final shown = _openOnly ? all.where((c) => c.isOpen).toList() : all;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Open (${s.chairman.openComplaints})'),
                selected: _openOnly,
                onSelected: (_) => setState(() => _openOnly = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('All (${all.length})'),
                selected: !_openOnly,
                onSelected: (_) => setState(() => _openOnly = false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ChairmanList(
            onRefresh: notifier.refreshChairman,
            emptyIcon: Icons.check_circle_outline_rounded,
            emptyMessage: _openOnly ? 'No open complaints.' : 'No complaints yet.',
            children: [
              for (final c in shown)
                ChairmanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c.category,
                              style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          StatusPill(c.statusLabel, color: _statusColor(c.status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: McTextStyles.body(fontSize: 13.5, color: McColors.text, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          c.residentName,
                          if (c.house != null && c.house!.isNotEmpty) c.house!,
                          DateFormat('MMM d').format(c.createdAt.toLocal()),
                          c.ref,
                        ].join(' · '),
                        style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
