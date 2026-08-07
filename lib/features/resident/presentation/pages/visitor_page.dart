import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/visitor_pass.dart';
import '../../../../state/app_notifier.dart';

class VisitorPage extends ConsumerWidget {
  const VisitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final passes = s.visitorPasses;

    // Group passes by day (createdAt) — keys are DateTime (day only).
    final Map<DateTime, List<VisitorPass>> byDay = {};
    for (final p in passes) {
      final day = DateTime(p.createdAt.year, p.createdAt.month, p.createdAt.day);
      byDay.putIfAbsent(day, () => []).add(p);
    }
    // Sort groups newest first (passes are already sorted per group).
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        ChGenericHeader(
          title: 'Visitor Passes',
          showBack: false,
          trailing: GestureDetector(
            onTap: () {
              notifier.resetVisitorForm();
              context.push('/resident/visitor/new');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 18, color: ChColors.bg),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                for (final day in sortedDays) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      _dayLabel(day),
                      style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.neutralN(600)),
                    ),
                  ),
                  for (final p in byDay[day]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => context.push('/resident/visitor/${p.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: p.isInside ? ChColors.accent2N(200) : ChColors.neutralN(200),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: 16,
                                  color: p.isInside ? ChColors.accent2N(800) : ChColors.neutralN(600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p.name, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: p.isInside ? ChColors.accent2N(100) : ChColors.neutralN(200),
                                            borderRadius: BorderRadius.circular(ChRadii.pill),
                                          ),
                                          child: Text(
                                            _statusLabel(p),
                                            style: ChTextStyles.body(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: p.isInside ? ChColors.accent2N(700) : ChColors.neutralN(600),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(p.visitLabel, style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                GestureDetector(
                  onTap: () {
                    notifier.resetVisitorForm();
                    context.push('/resident/visitor/new');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: ChColors.neutralN(400), width: 1.5),
                      borderRadius: BorderRadius.circular(ChRadii.md),
                    ),
                    child: Text(
                      '+ New Visitor Pass',
                      style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.accentN(700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  String _statusLabel(VisitorPass p) {
    if (p.status == VisitorPassStatus.revoked) return 'REVOKED';
    if (p.status != VisitorPassStatus.active) return 'EXPIRED';
    return p.isInside ? 'INSIDE' : (p.hasEntered ? 'LEFT' : 'ACTIVE');
  }
}