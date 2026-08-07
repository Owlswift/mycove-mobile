import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../data/models/my_pledge.dart';
import '../../../../data/models/poll.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/spotlight.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/poll_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final ongoingProjects = s.projects.where((p) => !p.isCompleted).toList();
    // Prefer a poll that's still open — otherwise a closed poll can sit here
    // indefinitely and hide newer ones a resident hasn't seen yet.
    final Poll? poll = s.polls.isEmpty
        ? null
        : s.polls.firstWhere((p) => p.closesIn != 'Closed', orElse: () => s.polls.first);

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
                  decoration: const BoxDecoration(color: ChColors.surface, shape: BoxShape.circle),
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
                            decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
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
                    style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w700, color: ChColors.bg),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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
                      gradient: const LinearGradient(
                        colors: [ChColors.accent2, Color(0xff3d472b)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding dues', style: ChTextStyles.body(fontSize: 13, color: ChColors.bg.withValues(alpha: 0.85))),
                        const SizedBox(height: 6),
                        Text(s.duesBalanceLabel, style: ChTextStyles.heading(fontSize: 28, color: ChColors.bg)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: ChColors.bg.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(ChRadii.pill),
                          ),
                          child: Text(
                            'Pay Now →',
                            style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.bg),
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
          const SizedBox(height: 12),

          // Meetings + Visitor tiles
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/resident/meetings'),
                  child: _DashboardTile(
                    icon: Icons.event_rounded,
                    label: 'Next meeting',
                    title: s.meetings.isNotEmpty ? s.meetings.first.title : 'None scheduled',
                    sub: s.meetings.isNotEmpty ? s.meetings.first.countdown : '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/resident/visitor'),
                  child: _DashboardTile(
                    icon: Icons.badge_rounded,
                    label: 'Visitor passes',
                    title: '${s.activePassCount}',
                    titleIsHeading: true,
                    sub: 'active now',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Latest announcement
          GestureDetector(
            onTap: () => context.go('/resident/announcements'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: ChColors.neutralN(200), shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_outlined, size: 16, color: ChColors.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latest announcement', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                        const SizedBox(height: 4),
                        Text(
                          s.announcements.isNotEmpty ? s.announcements.first.title : 'No announcements yet',
                          style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ongoing projects
          GestureDetector(
            onTap: () => context.go('/resident/projects'),
            child: Container(
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
                        child: const Icon(Icons.home_work_outlined, size: 13, color: ChColors.bg),
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
                  const SizedBox(height: 10),
                  for (final p in ongoingProjects) _ProjectProgressRow(project: p),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

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
                        child: const Icon(Icons.volunteer_activism_outlined, size: 13, color: ChColors.bg),
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
            const SizedBox(height: 12),
          ],

          // Active poll
          if (poll != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.pill)),
                  child: Text(
                    'ACTIVE POLL',
                    style: ChTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: ChColors.bg),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/resident/polls'),
                  child: Text(
                    'See all ›',
                    style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PollCard(
              poll: poll,
              onVote: (optionId) async {
                final error = await notifier.votePoll(poll.id, optionId);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
          ],
        ],
      ),
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
      backgroundColor: ChColors.bg,
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
              decoration: BoxDecoration(color: ChColors.accent2N(200), borderRadius: BorderRadius.circular(ChRadii.pill)),
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

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.title,
    required this.sub,
    this.titleIsHeading = false,
  });

  final IconData icon;
  final String label;
  final String title;
  final String sub;
  final bool titleIsHeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ChColors.accent2N(100), borderRadius: BorderRadius.circular(ChRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: ChColors.accent2N(200), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: ChColors.accent2N(800)),
          ),
          Text(label, style: ChTextStyles.body(fontSize: 12, color: ChColors.accent2N(800))),
          const SizedBox(height: 6),
          titleIsHeading
              ? Text(title, style: ChTextStyles.heading(fontSize: 24, color: ChColors.accent2N(900)))
              : Text(title, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.accent2N(900))),
          const SizedBox(height: 2),
          Text(sub, style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.accent2N(700))),
        ],
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

class _ProjectProgressRow extends StatelessWidget {
  const _ProjectProgressRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.title, style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(ChRadii.pill),
            child: LinearProgressIndicator(
              value: project.progress / 100,
              minHeight: 6,
              backgroundColor: ChColors.neutralN(300),
              valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
            ),
          ),
        ],
      ),
    );
  }
}
