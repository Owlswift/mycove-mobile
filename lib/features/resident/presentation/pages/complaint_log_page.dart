import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_underline_tabs.dart';
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
        McGenericHeader(
          title: 'Complaints',
          trailing: GestureDetector(
            onTap: () {
              notifier.resetComplaintForm();
              context.push('/resident/complaint');
            },
            child: Container(
              width: context.rs(32),
              height: context.rs(32),
              decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
              child: Icon(Icons.add, size: context.rs(18), color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: McUnderlineTabs(
            options: [
              McUnderlineTabOption(label: 'My Complaints (${s.complaints.length})', selected: _mineOnly, onSelect: () => setState(() => _mineOnly = true)),
              McUnderlineTabOption(label: 'All', selected: !_mineOnly, onSelect: () => setState(() => _mineOnly = false)),
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
                      Icon(Icons.report_gmailerrorred_outlined, size: 48, color: McColors.neutralN(400)),
                      const SizedBox(height: 12),
                      Text(
                        'No complaints yet',
                        textAlign: TextAlign.center,
                        style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complaints you submit will appear here with their ticket number and status.',
                        textAlign: TextAlign.center,
                        style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
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
                            boxShadow: McColors.cardShadow,
                            color: McColors.surface,
                            borderRadius: BorderRadius.circular(McRadii.card),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.category,
                                      style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700),
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
                                style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Ticket #${c.ref}',
                                    style: McTextStyles.body(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: McColors.accentN(700),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    c.timeLabel,
                                    style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
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
      'SUBMITTED' => ('Submitted', McColors.warning, McColors.warning.withValues(alpha: 0.14)),
      'IN_REVIEW' => ('In Review', McColors.warning, McColors.warning.withValues(alpha: 0.14)),
      'RESOLVED' => ('Resolved', McColors.accent2N(700), McColors.accent2N(100)),
      _ => (status, McColors.bodyText, McColors.neutralN(200)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(McRadii.pill)),
      child: Text(
        label,
        style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}