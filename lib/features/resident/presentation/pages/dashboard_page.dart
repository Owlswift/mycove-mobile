import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/spotlight_modal_storage.dart';
import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../data/models/meeting.dart';
import '../../../../data/models/my_pledge.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../data/models/poll.dart';
import '../../../../data/models/spotlight.dart';
import '../../../../data/models/utility_meter.dart';
import '../../../../data/models/utility_purchase.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// The provider already returns this pre-formatted (e.g. "79.9 kWh") — see
/// VtpassProvider/BuypowerProvider on the backend — so it's shown as-is.
/// `utilityPurchases` is newest-first, so the first electricity purchase
/// with units is the most recent one that actually vended.
String? _lastElectricityUnits(List<UtilityPurchase> purchases) {
  for (final p in purchases) {
    if (p.type == 'ELECTRICITY' && p.units != null) return p.units;
  }
  return null;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _spotlightModalChecked = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    if (!_spotlightModalChecked) {
      final spotlightImage = s.spotlight?.imageBase64;
      // Bootstrap fills in `s.spotlight` asynchronously after the first
      // build, so this stays unlatched across rebuilds until it actually
      // has an image to show — otherwise the very first (still-empty)
      // build would permanently skip the popup.
      if (spotlightImage != null && spotlightImage.isNotEmpty) {
        _spotlightModalChecked = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeShowSpotlightModal(spotlightImage),
        );
      }
    }
    final ongoingProjects = s.projects.where((p) => !p.isCompleted).toList();
    final featuredProject = ongoingProjects.isEmpty
        ? null
        : ongoingProjects.first;
    // Prefer a poll that's still open — otherwise a closed poll can sit here
    // indefinitely and hide newer ones a resident hasn't seen yet.
    final Poll? poll = s.polls.isEmpty
        ? null
        : s.polls.firstWhere(
            (p) => p.closesIn != 'Closed',
            orElse: () => s.polls.first,
          );
    // s.meetings is sorted oldest-first with no upcoming-only filter, so
    // plain `.first` would surface a stale, already-past meeting once the
    // soonest-scheduled one in the list has come and gone — unlike the poll
    // pick above, there's no reasonable fallback for a meeting that's
    // already happened, so this is null (not "the last one that occurred")
    // whenever nothing's left upcoming.
    final now = DateTime.now();
    final upcomingMeetings = s.meetings
        .where((m) => m.scheduledAt.isAfter(now))
        .toList();
    final Meeting? nextMeeting = upcomingMeetings.isEmpty
        ? null
        : upcomingMeetings.first;
    final pendingComplaints = s.complaints
        .where((c) => c.status != 'RESOLVED')
        .length;
    final unreadCount = s.notifications.where((n) => !n.read).length;
    final recentActivity = _recentActivity(s);

    return RefreshIndicator(
      onRefresh: notifier.refreshResident,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.rs(16),
          context.rs(6),
          context.rs(16),
          context.rs(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting on the left, bell + avatar on the right — no
            // separate app/estate branding row above it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()},',
                        style: ChTextStyles.body(
                          fontSize: 13,
                          color: ChColors.text,
                        ),
                      ),
                      Text(
                        '${s.currentUser?.first ?? ''} 👋',
                        style: ChTextStyles.heading(fontSize: 24),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: notifier.startVoiceListening,
                  child: Container(
                    width: context.rs(42),
                    height: context.rs(42),
                    margin: EdgeInsets.only(right: context.rs(10)),
                    decoration: const BoxDecoration(
                      color: ChColors.accent2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: context.rs(21),
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/resident/notifications'),
                  child: Container(
                    width: context.rs(42),
                    height: context.rs(42),
                    margin: EdgeInsets.only(right: context.rs(10)),
                    decoration: const BoxDecoration(
                      color: ChColors.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            size: context.rs(21),
                            color: ChColors.text,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: context.rs(-2),
                            right: context.rs(-2),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.rs(4),
                              ),
                              constraints: BoxConstraints(
                                minWidth: context.rs(16),
                                minHeight: context.rs(16),
                              ),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: ChColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/resident/profile'),
                  child: Container(
                    width: context.rs(42),
                    height: context.rs(42),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChColors.accent2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChColors.accent2N(200),
                        width: context.rs(2),
                      ),
                    ),
                    child: Text(
                      s.currentUser?.initials ?? '',
                      style: ChTextStyles.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(10)),
            Text(
              'A safer, cleaner and better community together.',
              style: ChTextStyles.body(fontSize: 12.5, color: ChColors.text),
            ),
            SizedBox(height: context.rs(16)),

            // Dues card (+ spotlight, if the estate is currently celebrating/promoting someone)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: s.spotlight != null ? 3 : 1,
                  child: GestureDetector(
                    onTap: () => context.go('/resident/dues'),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ChRadii.card),
                        boxShadow: ChColors.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(ChRadii.card),
                        child: Stack(
                          children: [
                            // Estate photo peeking through on the right, behind
                            // a scrim so the text on the left stays readable.
                            Positioned.fill(
                              child: s.estateImage != null
                                  ? ChDataMedia(dataUrl: s.estateImage!)
                                  : Image.asset(
                                      'assets/images/welcome_banner.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ChColors.accent2N(900),
                                      ChColors.accent2N(
                                        900,
                                      ).withValues(alpha: 0.55),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(context.rs(20)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (s.currentUser?.duesLiable ?? true)
                                        ? 'Outstanding Dues'
                                        : 'Household Outstanding Dues',
                                    style: ChTextStyles.body(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.rs(6)),
                                  Text(
                                    s.duesBalanceLabel,
                                    style: ChTextStyles.heading(
                                      fontSize: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (s.currentUser?.duesLiable ?? true) ...[
                                    SizedBox(height: context.rs(14)),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: context.rs(12),
                                      runSpacing: context.rs(8),
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.rs(18),
                                            vertical: context.rs(10),
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xfff5dfb8),
                                            borderRadius: BorderRadius.circular(
                                              ChRadii.pill,
                                            ),
                                          ),
                                          child: Text(
                                            'Pay Now →',
                                            style: ChTextStyles.body(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: ChColors.accentN(900),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (s.spotlight != null) ...[
                  SizedBox(width: context.rs(12)),
                  Expanded(
                    flex: 2,
                    child: _SpotlightCard(spotlight: s.spotlight!),
                  ),
                ],
              ],
            ),
            SizedBox(height: context.rs(18)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Utilities', style: ChTextStyles.heading(fontSize: 13)),
                GestureDetector(
                  onTap: () => context.push('/resident/utility-history'),
                  child: Row(
                    children: [
                      Text(
                        'History',
                        style: ChTextStyles.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ChColors.accent2,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: context.rs(16), color: ChColors.accent2),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(10)),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _UtilityCard(
                      icon: Icons.bolt_rounded,
                      cardBg: ChColors.accentN(200).withValues(alpha: 0.45),
                      iconBg: ChColors.accentN(300).withValues(alpha: 0.75),
                      iconColor: ChColors.accentN(800),
                      title: 'Electricity',
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastElectricityUnits(s.utilityPurchases) ?? '0.0 kWh',
                            style: ChTextStyles.heading(fontSize: 21),
                          ),
                          SizedBox(height: context.rs(4)),
                          Row(
                            children: [
                              Container(
                                width: context.rs(10),
                                height: context.rs(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xfffa6617),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: context.rs(5)),
                              Text(
                                'Running low?',
                                style: ChTextStyles.body(
                                  fontSize: 12,
                                  color: Color(0xfffa6617),
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                          if (s.utilityMeters.isNotEmpty) ...[
                            SizedBox(height: context.rs(3)),
                            Text(
                              s.utilityMeters.length > 1
                                  ? '${s.utilityMeters.length} meters saved'
                                  : 'Meter: ${formatMeterNumber(s.utilityMeters.first.meterNumber)}',
                              style: ChTextStyles.body(
                                fontSize: 10.5,
                                color: ChColors.bodyText,
                              ),
                            ),
                          ],
                        ],
                      ),
                      buttonLabel: 'Buy Electricity',
                      onTap: () {
                        if (s.utilityMeters.length > 1) {
                          context.push('/resident/electricity/select-meter');
                        } else if (s.utilityMeters.isNotEmpty) {
                          notifier.useExistingMeter(s.utilityMeters.first);
                          context.push('/resident/electricity/confirm');
                        } else {
                          notifier.resetElectricityForm();
                          context.push('/resident/electricity');
                        }
                      },
                    ),
                  ),
                  SizedBox(width: context.rs(6)),
                  Expanded(
                    child: _UtilityCard(
                      icon: Icons.phone_android_rounded,
                      cardBg: const Color(0xfff3f0fa),
                      iconBg: const Color(0xffece7f6),
                      iconColor: const Color(0xff6b5b95),
                      title: 'Airtime',
                      body: Text(
                        'Top up your phone anytime anywhere',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChTextStyles.body(
                          fontSize: 11,
                          color: ChColors.text,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      buttonLabel: 'Buy Airtime',
                      onTap: () {
                        notifier.resetAirtimeForm();
                        context.push('/resident/airtime');
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(10)),

            // Stat tiles: next meeting, visitor passes, active poll, complaints
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.event_rounded,
                    label: 'Next Meeting',
                    value: nextMeeting != null
                        ? meetingWhenLabel(nextMeeting.scheduledAt)
                        : 'No date yet',
                    onTap: () => context.push('/resident/meetings'),
                  ),
                ),
                SizedBox(width: context.rs(4)),
                Expanded(
                  child: _StatTile(
                    icon: Icons.badge_rounded,
                    label: 'Visitor Passes',
                    value: '${s.activePassCount} active',
                    onTap: () => context.go('/resident/visitor'),
                  ),
                ),
                SizedBox(width: context.rs(4)),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Active Poll',
                    value: poll == null ? 'None' : poll.closesIn,
                    onTap: () => context.push('/resident/polls'),
                  ),
                ),
                SizedBox(width: context.rs(4)),
                Expanded(
                  child: _StatTile(
                    icon: Icons.verified_user_rounded,
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
            SizedBox(height: context.rs(10)),

            // Latest announcement
            GestureDetector(
              onTap: () => context.go('/resident/announcements'),
              child: Container(
                padding: EdgeInsets.all(context.rs(16)),
                decoration: BoxDecoration(
                  color: ChColors.accentN(200).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  boxShadow: ChColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: context.rs(55),
                      height: context.rs(55),
                      decoration: BoxDecoration(
                        color: ChColors.accentN(300).withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        size: context.rs(30),
                        color: ChColors.accentN(800),
                      ),
                    ),
                    SizedBox(width: context.rs(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest Announcement',
                            style: ChTextStyles.body(
                              fontSize: 11,
                              color: ChColors.text,
                            ),
                          ),
                          SizedBox(height: context.rs(4)),
                          Text(
                            s.announcements.isNotEmpty
                                ? s.announcements.first.title
                                : 'No announcements yet',
                            style: ChTextStyles.body(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: ChColors.text,
                            ),
                          ),
                          if (s.announcements.isNotEmpty) ...[
                            SizedBox(height: context.rs(2)),
                            Text(
                              s.announcements.first.date,
                              style: ChTextStyles.body(
                                fontSize: 10.5,
                                color: ChColors.text,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: context.rs(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(10),
                        vertical: context.rs(6),
                      ),
                      decoration: BoxDecoration(
                        color: ChColors.accentN(300).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(ChRadii.pill),
                      ),
                      child: Text(
                        'Read →',
                        style: ChTextStyles.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ChColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.rs(10)),

            // Ongoing projects — spotlight the lead project, link out to the rest
            if (featuredProject != null)
              GestureDetector(
                onTap: () => context.go('/resident/projects'),
                child: Container(
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                    boxShadow: ChColors.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.rs(16),
                          context.rs(10),
                          context.rs(16),
                          0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: context.rs(30),
                              height: context.rs(30),
                              decoration: const BoxDecoration(
                                color: ChColors.accent2,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.home_work_outlined,
                                size: context.rs(15),
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: context.rs(8)),
                            Expanded(
                              child: Text(
                                'Ongoing Projects',
                                overflow: TextOverflow.ellipsis,
                                style: ChTextStyles.body(
                                  fontSize: 12,
                                  color: ChColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'See all ›',
                              style: ChTextStyles.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ChColors.accent2N(700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.rs(8)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(ChRadii.sm),
                              child: SizedBox(
                                width: context.rs(86),
                                height: context.rs(64),
                                // Not every project has its own photo yet —
                                // falls back to the estate's own photo (or,
                                // failing that, a generic asset) rather than
                                // leaving the thumbnail slot empty.
                                child: featuredProject.mediaBase64 != null
                                    ? ChDataMedia(
                                        dataUrl: featuredProject.mediaBase64!,
                                        height: context.rs(56),
                                        fit: BoxFit.cover,
                                      )
                                    : s.estateImage != null
                                    ? ChDataMedia(
                                        dataUrl: s.estateImage!,
                                        height: context.rs(56),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/welcome_banner.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(width: context.rs(12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    featuredProject.title,
                                    style: ChTextStyles.body(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ChColors.text,
                                    ),
                                  ),
                                  SizedBox(height: context.rs(6)),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      ChRadii.pill,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: featuredProject.progress / 100,
                                      minHeight: context.rs(6),
                                      backgroundColor: ChColors.neutralN(300),
                                      valueColor: const AlwaysStoppedAnimation(
                                        ChColors.accent2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.rs(10)),
                            Text(
                              '${featuredProject.progress}%',
                              style: ChTextStyles.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ChColors.accent2N(700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.rs(10)),
                    ],
                  ),
                ),
              ),
            SizedBox(height: context.rs(18)),

            Text('Quick Actions', style: ChTextStyles.heading(fontSize: 13)),
            SizedBox(height: context.rs(6)),
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
                    label: (s.currentUser?.duesLiable ?? true)
                        ? 'Pay Dues'
                        : 'View Dues',
                    tint: ChColors.accentN(500),
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
            // Pending — Traffic Update quick action is built and working
            // (see AppNotifier.openTrafficUpdate) but held back from the UI
            // until this feature is ready to ship. Re-enable by restoring
            // this Row.
            // SizedBox(height: context.rs(10)),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _QuickAction(
            //         icon: Icons.traffic_rounded,
            //         label: 'Traffic\nUpdate',
            //         tint: const Color(0xfffde7d7),
            //         iconColor: const Color(0xffb5651d),
            //         onTap: notifier.openTrafficUpdate,
            //       ),
            //     ),
            //     const Expanded(flex: 4, child: SizedBox()),
            //   ],
            // ),
            SizedBox(height: context.rs(18)),

            // Your pledges
            if (s.myPledges.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(16),
                  vertical: context.rs(10),
                ),
                decoration: BoxDecoration(
                  color: ChColors.surface,
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  boxShadow: ChColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: context.rs(30),
                          height: context.rs(30),
                          decoration: const BoxDecoration(
                            color: ChColors.accent2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volunteer_activism_outlined,
                            size: context.rs(15),
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: context.rs(8)),
                        Expanded(
                          child: Text(
                            'Your pledges',
                            overflow: TextOverflow.ellipsis,
                            style: ChTextStyles.body(
                              fontSize: 12,
                              color: ChColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatNaira(
                            s.myPledges.fold<int>(
                              0,
                              (sum, p) => sum + p.amount,
                            ),
                          ),
                          style: ChTextStyles.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ChColors.accent2N(700),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs(8)),
                    for (final p in s.myPledges) _PledgeRow(pledge: p),
                  ],
                ),
              ),
              SizedBox(height: context.rs(18)),
            ],

            // Recent activity — only what genuinely happened in the last 7
            // days (real timestamps: an arrival's actual entry time, a
            // payment's real record time), not just "the most recent one
            // ever recorded" regardless of how stale it's gotten.
            if (recentActivity.isNotEmpty) ...[
              Text(
                'Recent Activity',
                style: ChTextStyles.heading(fontSize: 13),
              ),
              SizedBox(height: context.rs(10)),
              Container(
                decoration: BoxDecoration(
                  color: ChColors.surface,
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  boxShadow: ChColors.cardShadow,
                ),
                child: Column(children: recentActivity),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _recentActivity(AppState s) {
    final items = <Widget>[];
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final recentArrivals =
        s.visitorPasses
            .where(
              (p) =>
                  p.hasEntered &&
                  p.enteredAt != null &&
                  p.enteredAt!.isAfter(sevenDaysAgo),
            )
            .toList()
          ..sort((a, b) => b.enteredAt!.compareTo(a.enteredAt!));
    final lastPayment = s.lastPayment;
    final recentPayment =
        lastPayment != null && lastPayment.createdAt.isAfter(sevenDaysAgo)
        ? lastPayment
        : null;

    if (recentArrivals.isNotEmpty) {
      final p = recentArrivals.first;
      items.add(
        _ActivityRow(
          icon: Icons.person_outline_rounded,
          iconColor: ChColors.accent2N(700),
          iconBg: ChColors.accent2N(100),
          title: '${p.name} arrived',
          subtitle: 'via visitor pass',
          time: relativeTime(p.enteredAt!),
          showBorder: recentPayment != null,
        ),
      );
    }
    if (recentPayment != null) {
      items.add(
        _ActivityRow(
          icon: Icons.receipt_long_outlined,
          iconColor: ChColors.accentN(800),
          iconBg: ChColors.accentN(100),
          title: recentPayment.desc,
          subtitle: formatNaira(recentPayment.amount),
          time: relativeTime(recentPayment.createdAt),
          showBorder: false,
        ),
      );
    }
    return items;
  }

  /// Pops the Spotlight's image full-screen, image only — no name/
  /// description, that's what the card next to Dues is for. Capped at
  /// [SpotlightModalStorage.maxPerDay] shows per calendar day so it doesn't
  /// nag on every launch.
  Future<void> _maybeShowSpotlightModal(String imageDataUrl) async {
    const storage = SpotlightModalStorage();
    if (!await storage.shouldShow()) return;
    await storage.recordShown();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: context.rs(24)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ChRadii.card),
              child: ChDataMedia(
                dataUrl: imageDataUrl,
                height: MediaQuery.sizeOf(context).height * 0.55,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: -14,
              right: -14,
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(context.rs(6)),
                  child: Icon(
                    Icons.close_rounded,
                    color: ChColors.text,
                    size: context.rs(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityCard extends StatelessWidget {
  const _UtilityCard({
    required this.icon,
    required this.cardBg,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color cardBg;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget body;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(ChRadii.card),
        boxShadow: ChColors.cardShadow,
      ),
      child: Stack(
        children: [
          // Same icon as the top-left badge, oversized and faint, watermarked
          // into the card's background — matches the reference design.
          Positioned(
            right: context.rs(-30),
            top: context.rs(14),
            child: Opacity(
              opacity: 0.05,
              child: Icon(icon, size: context.rs(96), color: iconColor),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.rs(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.rs(44),
                      height: context.rs(44),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: context.rs(22), color: iconColor),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: ChTextStyles.body(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: ChColors.text
                            ),
                          ),
                          SizedBox(height: context.rs(8)),
                          body,
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(12)),
                // Absorbs the height difference between the two cards (they're
                // stretched to match via the IntrinsicHeight wrapper above) so
                // the button always pins to the bottom instead of floating
                // right under whichever card's content happens to be shorter.
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: context.rs(7)),
                    decoration: BoxDecoration(
                      color: ChColors.accent2,
                      borderRadius: BorderRadius.circular(ChRadii.button),
                    ),
                    child: Text(
                      buttonLabel,
                      style: ChTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(10),
          vertical: context.rs(8),
        ),
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.md),
          boxShadow: ChColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: context.rs(40),
              height: context.rs(40),
              decoration: BoxDecoration(
                color: ChColors.accent2N(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.rs(20),
                color: ChColors.accent2N(700),
              ),
            ),
            SizedBox(height: context.rs(4)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 10, color: ChColors.text),
            ),
            SizedBox(height: context.rs(2)),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: ChColors.accent2N(700),
              ),
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
            width: context.rs(54),
            height: context.rs(54),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(ChRadii.md),
            ),
            child: Icon(icon, size: context.rs(26), color: iconColor),
          ),
          SizedBox(height: context.rs(4)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ChTextStyles.body(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: ChColors.text,
            ),
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
    required this.time,
    required this.showBorder,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(16),
        vertical: context.rs(8),
      ),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: ChColors.divider))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: context.rs(38),
            height: context.rs(38),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: context.rs(19), color: iconColor),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ChTextStyles.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ChColors.text,
                  ),
                ),
                SizedBox(height: context.rs(2)),
                Text(
                  subtitle,
                  style: ChTextStyles.body(fontSize: 10, color: ChColors.text),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(8)),
          Text(
            time,
            style: ChTextStyles.body(fontSize: 10, color: ChColors.text),
          ),
          SizedBox(width: context.rs(4)),
          Icon(Icons.chevron_right, size: context.rs(18), color: ChColors.text),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChRadii.card)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          sheetContext.rs(20),
          sheetContext.rs(24),
          sheetContext.rs(20),
          sheetContext.rs(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SpotlightAvatar(
                  spotlight: spotlight,
                  size: sheetContext.rs(56),
                ),
                SizedBox(width: sheetContext.rs(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spotlight.name,
                        style: ChTextStyles.heading(fontSize: 17),
                      ),
                      SizedBox(height: sheetContext.rs(2)),
                      Text(
                        spotlight.isBusiness
                            ? 'Local business'
                            : 'Community spotlight',
                        style: ChTextStyles.body(
                          fontSize: 12,
                          color: ChColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sheetContext.rs(16)),
            Text(spotlight.description, style: ChTextStyles.body(fontSize: 14)),
            if (spotlight.phone != null) ...[
              SizedBox(height: sheetContext.rs(14)),
              Row(
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: sheetContext.rs(16),
                    color: ChColors.accent2N(700),
                  ),
                  SizedBox(width: sheetContext.rs(8)),
                  Text(
                    spotlight.phone!,
                    style: ChTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ChColors.accent2N(700),
                    ),
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
        padding: EdgeInsets.all(context.rs(14)),
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.card),
          boxShadow: ChColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(8),
                vertical: context.rs(3),
              ),
              decoration: BoxDecoration(
                color: ChColors.accent2N(100),
                borderRadius: BorderRadius.circular(ChRadii.pill),
              ),
              child: Text(
                spotlight.isBusiness ? 'BUSINESS' : 'SPOTLIGHT',
                style: ChTextStyles.body(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: ChColors.accent2N(800),
                ),
              ),
            ),
            SizedBox(height: context.rs(10)),
            _SpotlightAvatar(spotlight: spotlight, size: context.rs(38)),
            SizedBox(height: context.rs(8)),
            Text(
              spotlight.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.rs(2)),
            Text(
              spotlight.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ChTextStyles.body(fontSize: 11, color: ChColors.text),
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
                  spotlight.isBusiness
                      ? Icons.storefront_rounded
                      : Icons.person_rounded,
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
        padding: EdgeInsets.symmetric(vertical: context.rs(3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pledge.projectTitle,
                overflow: TextOverflow.ellipsis,
                style: ChTextStyles.body(
                  fontSize: 12,
                  color: ChColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: context.rs(8)),
            Text(
              formatNaira(pledge.amount),
              style: ChTextStyles.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ChColors.accent2N(700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
