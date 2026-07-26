import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/detail_providers.dart';

class MeetingDetailPage extends ConsumerWidget {
  const MeetingDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(meetingDetailProvider(id));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const ChGenericHeader(title: 'Meeting'),
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ChColors.accent)),
            error: (e, _) => Center(
              child: Text(
                'Could not load this meeting.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
            ),
            data: (json) {
              final agenda = (json['agenda'] as List).cast<String>();
              final added = json['calendarAdded'] as bool;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(json['title'] as String, style: ChTextStyles.heading(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                      '${json['date']} at ${json['time']}',
                      style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
                    ),
                    Text(json['location'] as String, style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600))),
                    const SizedBox(height: 16),
                    Text(
                      'AGENDA',
                      style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                          .copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    for (final ag in agenda)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 8, right: 8),
                              decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
                            ),
                            Expanded(child: Text(ag, style: ChTextStyles.body(fontSize: 14))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (added)
                      Text(
                        '✓ Added to device calendar',
                        style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          await notifier.addToCalendar(id);
                          ref.invalidate(meetingDetailProvider(id));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.pill)),
                          child: Text('Add to Calendar', style: ChTextStyles.heading(fontSize: 14)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
