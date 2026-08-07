import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

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

              return RefreshIndicator(
                onRefresh: () async => notifier.refreshResident(),
                child: SingleChildScrollView(
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
                        ElevatedButton(
                          onPressed: () async {
                            final title = json['title'] as String;
                            final location = json['location'] as String;
                            final startDate = DateTime.parse(json['scheduledAt'] as String).toLocal();

                            final event = Event(
                              title: title,
                              description: 'CommunityHub Meeting',
                              location: location,
                              startDate: startDate,
                              endDate: startDate.add(const Duration(hours: 1)),
                            );

                            try {
                              await Add2Calendar.addEvent2Cal(event);
                              await notifier.addToCalendar(id);
                              ref.invalidate(meetingDetailProvider(id));
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not add this meeting to your calendar.')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ChColors.accent2,
                            foregroundColor: ChColors.bg,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChRadii.pill)),
                          ),
                          child: Text('Add to Calendar', style: ChTextStyles.heading(fontSize: 14)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}