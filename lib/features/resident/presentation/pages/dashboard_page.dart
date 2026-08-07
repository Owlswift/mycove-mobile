import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../data/models/my_pledge.dart';
import '../../../../data/models/poll.dart';
import '../../../../data/models/spotlight.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final ongoingProjects = s.projects.where((p) => !p.isCompleted).toList();
    final featuredProject = ongoingProjects.isEmpty ? null : ongoingProjects.first;
    // Prefer a poll that's still open — otherwise a closed poll can sit here
    // indefinitely and hide newer ones a resident hasn't seen yet.
    final Poll? poll = s.polls.isEmpty
        ? null
        : s.polls.firstWhere((p) => p.closesIn != 'Closed', orElse: () => s.polls.first);
    final pendingComplaints = s.complaints.where((c) => c.status != 'RESOLVED').length;

    return RefreshIndicator(
      onRefresh: notifier.refreshResident,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good afternoon', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                    Text(s.currentUser?.first ?? '', style: ChTextStyles.heading(fontSize: 24)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/resident/notifications'),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(color: ChColors.surfaceSunken, shape: BoxShape.circle),
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.notifications_outlined, size: 18, color: ChColors.text)),
                      if (!s.allNotifsRead)
                        Positioned(
                          top: 6,
                          right: 7,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: ChColors.danger, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/resident/profile'),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
                  child: Text(
                    s.currentUser?.initials ?? '',
                    style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dues card (+ spotlight, if the estate is currently celebrating/promoting someone)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: s.spotlight != null ? 3 : 1,
                child: GestureDetector(
                  onTap: () => context.go('/resident/dues'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ChRadii.card),
                      gradient: LinearGradient(
                        colors: [ChColors.accent2, ChColors.accent2N(900)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding dues', style: ChTextStyles.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 6),
                        Text(s.duesBalanceLabel, style: ChTextStyles.heading(fontSize: 28, color: Colors.white)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: ChColors.accent,
                            borderRadius: BorderRadius.circular(ChRadii.button),
                          ),
                          child: Text(
                            'Pay Now →',
                            style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.accentN(900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (s.spotlight != null) ...[
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _SpotlightCard(spotlight: s.spotlight!)),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Stat tiles: next meeting, visitor passes, active poll, complaints
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_rounded,
                  label: 'Next Meeting',
                  value: s.meetings.isNotEmpty ? s.meetings.first.title : 'None',
                  onTap: () => context.push('/resident/meetings'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.badge_rounded,
                  label: 'Visitor Passes',
                  value: '${s.activePassCount} active',
                  onTap: () => context.go('/resident/visitor'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Active Poll',
                  value: poll == null ? 'None' : poll.closesIn,
                  onTap: () => context.push('/resident/polls'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.shield_outlined,
                  label: 'Complaints',
                  value: '$pendingComplaints pending',
                  onTap: () {
                    notifier.loadComplaints();
                    context.push('/resident/complaint/log');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Latest announcement
          GestureDetector(
            onTap: () => context.go('/resident/announcements'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ChColors.accentN(100), borderRadius: BorderRadius.circular(ChRadii.card)),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: ChColors.accentN(200), shape: BoxShape.circle),
                    child: Icon(Icons.campaign_outlined, size: 16, color: ChColors.accentN(800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latest announcement', style: ChTextStyles.body(fontSize: 12, color: ChColors.accentN(800))),
                        const SizedBox(height: 4),
                        Text(
                          s.announcements.isNotEmpty ? s.announcements.first.title : 'No announcements yet',
                          style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text('Read →', style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w700, color: ChColors.accentN(800))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Ongoing projects — spotlight the lead project, link out to the rest
          if (featuredProject != null)
            GestureDetector(
              onTap: () => context.go('/resident/projects'),
              child: Container(
                decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
                            child: const Icon(Icons.home_work_outlined, size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ongoing projects',
                              overflow: TextOverflow.ellipsis,
                              style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
                            ),
                          ),
                          Text(
                            'See all ›',
                            style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (featuredProject.mediaBase64 != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(ChRadii.sm),
                              child: ChDataMedia(dataUrl: featuredProject.mediaBase64!, height: 56, fit: BoxFit.cover),
                            ),
                          if (featuredProject.mediaBase64 != null) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(featuredProject.title, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(ChRadii.pill),
                                  child: LinearProgressIndicator(
                                    value: featuredProject.progress / 100,
                                    minHeight: 6,
                                    backgroundColor: ChColors.neutralN(300),
                                    valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${featuredProject.progress}%', style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.accent2N(700))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),

          Text('Quick Actions', style: ChTextStyles.heading(fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Visitor Pass',
                  tint: ChColors.accent2N(100),
                  iconColor: ChColors.accent2N(700),
                  onTap: () => context.go('/resident/visitor'),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.credit_card_rounded,
                  label: 'Pay Dues',
                  tint: ChColors.accentN(100),
                  iconColor: ChColors.accentN(800),
                  onTap: () => context.go('/resident/dues'),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Submit\nComplaint',
                  tint: const Color(0xffece7f6),
                  iconColor: const Color(0xff6b5b95),
                  onTap: () {
                    notifier.resetComplaintForm();
                    context.push('/resident/complaint');
                  },
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.how_to_vote_outlined,
                  label: 'Vote in Poll',
                  tint: ChColors.accentN(100),
                  iconColor: ChColors.accentN(800),
                  onTap: () => context.push('/resident/polls'),
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.menu_book_outlined,
                  label: 'Rules',
                  tint: const Color(0xffe2ecf5),
                  iconColor: const Color(0xff3f6f92),
                  onTap: () => context.push('/resident/rules'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Your pledges
          if (s.myPledges.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
                        child: const Icon(Icons.volunteer_activism_outlined, size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your pledges',
                          overflow: TextOverflow.ellipsis,
                          style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
                        ),
                      ),
                      Text(
                        formatNaira(s.myPledges.fold<int>(0, (sum, p) => sum + p.amount)),
                        style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.accent2N(700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final p in s.myPledges) _PledgeRow(pledge: p),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Recent activity — the freshest visitor arrival and dues payment
          // already sitting in state, no extra fetch needed.
          if (s.visitorPasses.any((p) => p.hasEntered) || s.lastPayment != null) ...[
            Text('Recent Activity', style: ChTextStyles.heading(fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
              child: Column(
                children: [
                  for (final entry in _recentActivity(s)) entry,
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  List<Widget> _recentActivity(AppState s) {
    final items = <Widget>[];
    final lastArrival = s.visitorPasses.where((p) => p.hasEntered).toList();
    if (lastArrival.isNotEmpty) {
      final p = lastArrival.first;
      items.add(_ActivityRow(
        icon: Icons.person_outline_rounded,
        iconColor: ChColors.accent2N(700),
        iconBg: ChColors.accent2N(100),
        title: '${p.name} arrived',
        subtitle: 'via visitor pass',
        showBorder: s.lastPayment != null,
      ));
    }
    final payment = s.lastPayment;
    if (payment != null) {
      items.add(_ActivityRow(
        icon: Icons.receipt_long_outlined,
        iconColor: ChColors.accentN(800),
        iconBg: ChColors.accentN(100),
        title: payment.desc,
        subtitle: formatNaira(payment.amount),
        showBorder: false,
      ));
    }
    return items;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: ChColors.accent2N(700)),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 10.5, color: ChColors.neutralN(600)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.accent2N(700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ChTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.showBorder,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(border: showBorder ? const Border(bottom: BorderSide(color: ChColors.divider)) : null),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ChTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: ChColors.neutralN(500)),
        ],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.spotlight});

  final Spotlight spotlight;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(ChRadii.card))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SpotlightAvatar(spotlight: spotlight, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spotlight.name, style: ChTextStyles.heading(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(
                        spotlight.isBusiness ? 'Local business' : 'Community spotlight',
                        style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(spotlight.description, style: ChTextStyles.body(fontSize: 14)),
            if (spotlight.phone != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.call_outlined, size: 16, color: ChColors.accent2N(700)),
                  const SizedBox(width: 8),
                  Text(
                    spotlight.phone!,
                    style: ChTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: ChColors.accent2N(100), borderRadius: BorderRadius.circular(ChRadii.pill)),
              child: Text(
                spotlight.isBusiness ? 'BUSINESS' : 'SPOTLIGHT',
                style: ChTextStyles.body(fontSize: 9.5, fontWeight: FontWeight.w700, color: ChColors.accent2N(800)),
              ),
            ),
            const SizedBox(height: 10),
            _SpotlightAvatar(spotlight: spotlight, size: 38),
            const SizedBox(height: 8),
            Text(
              spotlight.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              spotlight.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 11, color: ChColors.neutralN(600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightAvatar extends StatelessWidget {
  const _SpotlightAvatar({required this.spotlight, required this.size});

  final Spotlight spotlight;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageBase64 = spotlight.imageBase64;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageBase64 != null
            ? ChDataMedia(dataUrl: imageBase64, height: size)
            : Container(
                color: ChColors.accent2N(200),
                child: Icon(
                  spotlight.isBusiness ? Icons.storefront_rounded : Icons.person_rounded,
                  size: size * 0.5,
                  color: ChColors.accent2N(800),
                ),
              ),
      ),
    );
  }
}

class _PledgeRow extends StatelessWidget {
  const _PledgeRow({required this.pledge});

  final MyPledge pledge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/resident/projects/${pledge.projectId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pledge.projectTitle,
                overflow: TextOverflow.ellipsis,
                style: ChTextStyles.body(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatNaira(pledge.amount),
              style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
            ),
          ],
        ),
      ),
    );
  }
}
