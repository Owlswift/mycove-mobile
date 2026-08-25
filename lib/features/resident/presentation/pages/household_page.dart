import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/household_invite.dart';
import '../../../../data/models/household_member.dart';
import '../../../../state/app_notifier.dart';

/// Lists everyone linked to this resident's household — people this
/// resident invited in (each with their own independent account, not a
/// sub-user) plus any invitations still working their way through admin
/// approval and sign-up. See AppNotifier.sendHouseholdInvite/
/// cancelHouseholdInvite and the backend's HouseholdController.
class HouseholdPage extends ConsumerWidget {
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final members = s.householdMembers;
    // Accepted invites already show up as members above — listing them
    // again here would just be the same person twice.
    final pendingInvites = s.householdInvites
        .where((i) => i.status != HouseholdInviteStatus.accepted)
        .toList();

    final isEmpty = members.isEmpty && pendingInvites.isEmpty;
    // Only the household's own registered resident can invite people in —
    // someone who was themselves invited has no members/invites of their
    // own to show here (see HouseholdService.members/myInvites, both
    // scoped to invitedByUserId) and can't send invites either (see
    // HouseholdService.invite's ForbiddenException).
    final isInvitedMember = s.currentUser?.invitedByName != null;

    return Column(
      children: [
        ChGenericHeader(
          title: 'My Household',
          centerTitle: true,
          onBack: () => context.pop(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.rs(32),
                      context.rs(40),
                      context.rs(32),
                      context.rs(24),
                    ),
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: context.rs(40),
                        color: ChColors.neutralN(400),
                      ),
                      SizedBox(height: context.rs(12)),
                      Text(
                        'No household members yet.',
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ChColors.text,
                        ),
                      ),
                      SizedBox(height: context.rs(6)),
                      Text(
                        isInvitedMember
                            ? "Only ${s.currentUser?.invitedByName} can invite people into this household."
                            : "Invite someone you live with to get their own login — they won't be charged separate estate dues.",
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(
                          fontSize: 13,
                          color: ChColors.bodyText,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.rs(20),
                      context.rs(6),
                      context.rs(20),
                      context.rs(24),
                    ),
                    children: [
                      if (members.isNotEmpty) ...[
                        _SectionLabel('Household Members'),
                        SizedBox(height: context.rs(8)),
                        for (final m in members) ...[
                          _MemberTile(member: m),
                          SizedBox(height: context.rs(10)),
                        ],
                        SizedBox(height: context.rs(8)),
                      ],
                      if (pendingInvites.isNotEmpty) ...[
                        _SectionLabel('Invitations'),
                        SizedBox(height: context.rs(8)),
                        for (final i in pendingInvites) ...[
                          _InviteTile(
                            invite: i,
                            onCancel:
                                i.status ==
                                    HouseholdInviteStatus.pendingAdminApproval
                                ? () async {
                                    final error = await notifier
                                        .cancelHouseholdInvite(i.id);
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  }
                                : null,
                          ),
                          SizedBox(height: context.rs(10)),
                        ],
                      ],
                    ],
                  ),
          ),
        ),
        if (!isInvitedMember)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rs(20),
              0,
              context.rs(20),
              context.rs(24),
            ),
            child: ChButton(
              label: 'Invite Resident',
              variant: ChButtonVariant.primary,
              onPressed: () => context.push('/resident/profile/household/invite'),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: ChTextStyles.body(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ChColors.bodyText,
      ).copyWith(letterSpacing: 1),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.md),
        boxShadow: ChColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: context.rs(36),
            height: context.rs(36),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: ChColors.accent2,
              size: context.rs(18),
            ),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: ChTextStyles.body(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: ChColors.text,
                  ),
                ),
                SizedBox(height: context.rs(3)),
                Text(
                  'Joined ${DateFormat('MMM d, yyyy').format(member.joinedAt)}',
                  style: ChTextStyles.body(
                    fontSize: 12,
                    color: ChColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(9),
              vertical: context.rs(3),
            ),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              borderRadius: BorderRadius.circular(ChRadii.pill),
            ),
            child: Text(
              'Linked resident',
              style: ChTextStyles.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: ChColors.accent2N(700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({required this.invite, required this.onCancel});

  final HouseholdInvite invite;
  final VoidCallback? onCancel;

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (invite.status) {
      HouseholdInviteStatus.pendingAdminApproval => ChColors.warning,
      HouseholdInviteStatus.approved => ChColors.accent2,
      HouseholdInviteStatus.rejected => ChColors.danger,
      HouseholdInviteStatus.accepted => ChColors.accent2,
    };

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.md),
        boxShadow: ChColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.invitedFullName,
                      style: ChTextStyles.body(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: ChColors.text,
                      ),
                    ),
                    SizedBox(height: context.rs(3)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(9),
                        vertical: context.rs(3),
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(ChRadii.pill),
                      ),
                      child: Text(
                        invite.statusLabel,
                        style: ChTextStyles.body(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: ChColors.danger),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          if (invite.accessCode != null) ...[
            SizedBox(height: context.rs(12)),
            Text(
              "Share this code with ${invite.invitedFullName} — they'll log in with their "
              "phone number and this code, then set their own password.",
              style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText, height: 1.4),
            ),
            SizedBox(height: context.rs(8)),
            InkWell(
              borderRadius: BorderRadius.circular(ChRadii.sm),
              onTap: () => _copyCode(context, invite.accessCode!),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(10)),
                decoration: BoxDecoration(
                  color: ChColors.accent2N(100),
                  borderRadius: BorderRadius.circular(ChRadii.sm),
                  border: Border.all(color: ChColors.accent2N(300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invite.accessCode!,
                      style: ChTextStyles.heading(fontSize: 18).copyWith(letterSpacing: 3),
                    ),
                    Icon(Icons.copy_rounded, size: context.rs(18), color: ChColors.accent2N(700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
