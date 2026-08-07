import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class MeetingsPage extends ConsumerWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    return Column(
      children: [
        const ChGenericHeader(title: 'Meetings', showBack: false),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: s.meetings.length,
            itemBuilder: (context, i) {
              final item = s.meetings[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => context.push('/resident/meetings/${item.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: ChColors.accent2N(100), shape: BoxShape.circle),
                          child: Icon(Icons.event_outlined, size: 16, color: ChColors.accent2N(700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                '${item.date} · ${item.time} · ${item.location}',
                                style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.countdown,
                                style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
          ),
        ),
      ],
    );
  }
}
