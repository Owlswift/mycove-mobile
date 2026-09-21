import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/detail_providers.dart';

/// When the guards let a domestic staff member in and out of the estate.
/// With a [staffId] it is that person's log; without, everyone's.
class DomesticLogPage extends ConsumerWidget {
  const DomesticLogPage({super.key, this.staffId, this.staffName});

  final String? staffId;
  final String? staffName;

  static String _duration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(domesticLogProvider(staffId));
    final day = DateFormat('EEE, d MMM');
    final time = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            McGenericHeader(
              title: 'Entry & exit log',
              centerTitle: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(domesticLogProvider(staffId).future),
                child: log.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: McColors.accent),
                  ),
                  error: (e, _) => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        extractMessage(e),
                        style: McTextStyles.body(
                          fontSize: 14,
                          color: McColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 44,
                            color: McColors.neutralN(400),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No visits yet',
                            textAlign: TextAlign.center,
                            style: McTextStyles.heading(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When a guard lets ${staffName ?? 'your staff'} in or out at the gate, it will show here.',
                            textAlign: TextAlign.center,
                            style: McTextStyles.body(
                              fontSize: 13,
                              color: McColors.bodyText,
                              height: 1.6,
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        if (staffName != null) ...[
                          Text(
                            staffName!,
                            style: McTextStyles.heading(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Every time a guard let them in or out of the estate.',
                            style: McTextStyles.body(
                              fontSize: 13,
                              color: McColors.bodyText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        for (final e in entries) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: McColors.surface,
                              borderRadius: BorderRadius.circular(McRadii.card),
                              boxShadow: McColors.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        staffId == null
                                            ? '${e['staffName']}'
                                            : day.format(
                                                DateTime.parse(
                                                  e['entryAt'] as String,
                                                ).toLocal(),
                                              ),
                                        style: McTextStyles.heading(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (e['insideNow'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: McColors.accent2N(100),
                                          borderRadius: BorderRadius.circular(
                                            McRadii.pill,
                                          ),
                                        ),
                                        child: Text(
                                          'INSIDE NOW',
                                          style: McTextStyles.body(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: McColors.accent2N(700),
                                          ),
                                        ),
                                      )
                                    else if (e['minutesInside'] != null)
                                      Text(
                                        _duration(
                                          (e['minutesInside'] as num).toInt(),
                                        ),
                                        style: McTextStyles.body(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: McColors.bodyText,
                                        ),
                                      ),
                                  ],
                                ),
                                if (staffId == null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    day.format(
                                      DateTime.parse(
                                        e['entryAt'] as String,
                                      ).toLocal(),
                                    ),
                                    style: McTextStyles.body(
                                      fontSize: 13,
                                      color: McColors.bodyText,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _row(
                                  Icons.login_rounded,
                                  'Entered',
                                  time.format(
                                    DateTime.parse(
                                      e['entryAt'] as String,
                                    ).toLocal(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _row(
                                  Icons.logout_rounded,
                                  'Left',
                                  e['exitAt'] == null
                                      ? 'Not yet'
                                      : time.format(
                                          DateTime.parse(
                                            e['exitAt'] as String,
                                          ).toLocal(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 19, color: McColors.bodyText),
      const SizedBox(width: 10),
      Text(
        label,
        style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
      ),
      const Spacer(),
      Text(
        value,
        style: McTextStyles.body(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: McColors.text,
        ),
      ),
    ],
  );
}
