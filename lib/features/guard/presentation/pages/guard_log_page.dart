import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../data/models/access_log_entry.dart';
import '../../../../state/app_notifier.dart';

class GuardLogPage extends ConsumerWidget {
  const GuardLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final logs = s.accessLog;

    // Group logs by day (entryAt) — keys are DateTime (day only).
    final Map<DateTime, List<AccessLogEntry>> byDay = {};
    for (final log in logs) {
      final day = DateTime(log.entryAt.year, log.entryAt.month, log.entryAt.day);
      byDay.putIfAbsent(day, () => []).add(log);
    }
    // Sort groups newest first (logs are already sorted per group by the API).
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: notifier.refreshGuard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          for (final day in sortedDays) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                _dayLabel(day),
                style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: McColors.bodyText),
              ),
            ),
            for (final log in byDay[day]!)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.visitor, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('In: ${log.entry}', style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                    Text('Out: ${log.exit ?? 'Still on site'}', style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Today → "Today", Yesterday → "Yesterday", otherwise a short date.
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(day);
  }
}