import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class ComplaintLogPage extends ConsumerWidget {
  const ComplaintLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const ChGenericHeader(title: 'My Complaints'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.loadComplaints,
            child: s.complaints.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    children: [
                      Icon(Icons.report_gmailerrorred_outlined, size: 48, color: ChColors.neutralN(400)),
                      const SizedBox(height: 12),
                      Text(
                        'No complaints yet',
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complaints you submit will appear here with their ticket number and status.',
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: s.complaints.length,
                    itemBuilder: (context, i) {
                      final c = s.complaints[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: ChColors.surface,
                            borderRadius: BorderRadius.circular(ChRadii.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.category,
                                      style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  _StatusBadge(status: c.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Ticket #${c.ref}',
                                    style: ChTextStyles.body(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: ChColors.accentN(700),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    c.timeLabel,
                                    style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
                                  ),
                                ],
                              ),
                            ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'SUBMITTED' => ('Submitted', ChColors.accentN(700), ChColors.accentN(200)),
      'IN_REVIEW' => ('In Review', ChColors.accent2N(800), ChColors.accent2N(200)),
      'RESOLVED' => ('Resolved', ChColors.accent2N(800), ChColors.accent2N(200)),
      _ => (status, ChColors.neutralN(600), ChColors.neutralN(200)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ChRadii.pill)),
      child: Text(
        label,
        style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}