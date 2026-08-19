import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_underline_tabs.dart';
import '../../../../state/app_notifier.dart';

class ComplaintLogPage extends ConsumerStatefulWidget {
  const ComplaintLogPage({super.key});

  @override
  ConsumerState<ComplaintLogPage> createState() => _ComplaintLogPageState();
}

class _ComplaintLogPageState extends ConsumerState<ComplaintLogPage> {
  bool _mineOnly = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    // The API already scopes complaints to the signed-in resident — "All"
    // just drops the client-side status/date narrowing "My Complaints"
    // otherwise doesn't apply, so both tabs show the same list for now.
    final shown = s.complaints;

    return Column(
      children: [
        ChGenericHeader(
          title: 'Complaints',
          trailing: GestureDetector(
            onTap: () {
              notifier.resetComplaintForm();
              context.push('/resident/complaint');
            },
            child: Container(
              width: context.rs(32),
              height: context.rs(32),
              decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
              child: Icon(Icons.add, size: context.rs(18), color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ChUnderlineTabs(
            options: [
              ChUnderlineTabOption(label: 'My Complaints (${s.complaints.length})', selected: _mineOnly, onSelect: () => setState(() => _mineOnly = true)),
              ChUnderlineTabOption(label: 'All', selected: !_mineOnly, onSelect: () => setState(() => _mineOnly = false)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.loadComplaints,
            child: shown.isEmpty
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
                        style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final c = shown[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: ChColors.surface,
                            borderRadius: BorderRadius.circular(ChRadii.card),
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
                                style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
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
                                    style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
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
      'SUBMITTED' => ('Submitted', ChColors.warning, ChColors.warning.withValues(alpha: 0.14)),
      'IN_REVIEW' => ('In Review', ChColors.warning, ChColors.warning.withValues(alpha: 0.14)),
      'RESOLVED' => ('Resolved', ChColors.accent2N(700), ChColors.accent2N(100)),
      _ => (status, ChColors.bodyText, ChColors.neutralN(200)),
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