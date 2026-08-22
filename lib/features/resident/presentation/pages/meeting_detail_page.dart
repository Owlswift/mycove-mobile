import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../../../../state/detail_providers.dart';

class MeetingDetailPage extends ConsumerWidget {
  const MeetingDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(meetingDetailProvider(id));
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isThisReport = s.activeReportMeetingId == id;

    return Column(
      children: [
        const ChGenericHeader(title: 'Meeting'),
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ChColors.accent)),
            error: (e, _) => Center(
              child: Text(
                'Could not load this meeting.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.bodyText),
              ),
            ),
            data: (json) {
              final agenda = (json['agenda'] as List).cast<String>();
              final added = json['calendarAdded'] as bool;
              final report = (json['report'] as String?)?.trim();
              final topics = (json['aiTopics'] as List).cast<String>();

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
                        style: ChTextStyles.body(fontSize: 14, color: ChColors.bodyText),
                      ),
                      Text(json['location'] as String, style: ChTextStyles.body(fontSize: 14, color: ChColors.bodyText)),
                      const SizedBox(height: 16),
                      Text(
                        'AGENDA',
                        style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.bodyText)
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
                      if (report != null && report.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'MEETING REPORT',
                          style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.bodyText)
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(report, style: ChTextStyles.body(fontSize: 14, height: 1.5)),
                        const SizedBox(height: 12),
                        _ReportPlaybackControls(
                          state: isThisReport ? s.reportPlaybackState : ReportPlaybackState.stopped,
                          onPlay: () => notifier.playMeetingReport(id, report),
                          onPause: notifier.pauseMeetingReport,
                          onResume: notifier.resumeMeetingReport,
                          onStop: notifier.stopMeetingReport,
                        ),
                      ],
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in topics)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ChColors.surfaceSunken,
                                  borderRadius: BorderRadius.circular(ChRadii.pill),
                                ),
                                child: Text(
                                  t,
                                  style: ChTextStyles.body(fontSize: 11.5, color: ChColors.bodyText),
                                ),
                              ),
                          ],
                        ),
                      ],
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChRadii.button)),
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

/// Play/pause/resume/stop for having the report read aloud — deliberately
/// this simple, no scrubber or speed control, per the "don't make the
/// interface complicated" brief this feature was built from.
class _ReportPlaybackControls extends StatelessWidget {
  const _ReportPlaybackControls({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final ReportPlaybackState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: switch (state) {
        ReportPlaybackState.stopped => [_ControlButton(icon: Icons.play_arrow_rounded, label: 'Listen to Report', onTap: onPlay)],
        ReportPlaybackState.playing => [
          _ControlButton(icon: Icons.pause_rounded, label: 'Pause', onTap: onPause),
          const SizedBox(width: 10),
          _ControlButton(icon: Icons.stop_rounded, label: 'Stop', onTap: onStop, isSecondary: true),
        ],
        ReportPlaybackState.paused => [
          _ControlButton(icon: Icons.play_arrow_rounded, label: 'Resume', onTap: onResume),
          const SizedBox(width: 10),
          _ControlButton(icon: Icons.stop_rounded, label: 'Stop', onTap: onStop, isSecondary: true),
        ],
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChRadii.button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSecondary ? ChColors.surface : ChColors.accent2,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: isSecondary ? Border.all(color: ChColors.divider) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSecondary ? ChColors.bodyText : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: ChTextStyles.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSecondary ? ChColors.bodyText : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}