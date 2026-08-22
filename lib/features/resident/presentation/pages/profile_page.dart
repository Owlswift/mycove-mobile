import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final user = s.currentUser;

    return Column(
      children: [
        const ChGenericHeader(title: 'Profile'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Container(
                  width: context.rs(72),
                  height: context.rs(72),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    color: ChColors.accent2,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user?.initials ?? '',
                    style: ChTextStyles.body(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  user?.fullName ?? '',
                  style: ChTextStyles.heading(fontSize: 18),
                ),
                Text(
                  user?.house ?? '',
                  style: ChTextStyles.body(
                    fontSize: 13,
                    color: ChColors.bodyText,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Phone', user?.phone ?? '', showBorder: true),
                      if (user?.email?.isNotEmpty ?? false)
                        _infoRow('Email', user!.email!, showBorder: true),
                      if (user?.emergencyContactName?.isNotEmpty ?? false)
                        _infoRow(
                          'Emergency contact',
                          '${user!.emergencyContactName}${user.emergencyContactPhone != null ? ' · ${user.emergencyContactPhone}' : ''}',
                          showBorder: true,
                        ),
                      if (user?.vehiclePlates.isNotEmpty ?? false)
                        _infoRow(
                          'Vehicle(s)',
                          user!.vehiclePlates.join(', '),
                          showBorder: true,
                        ),
                      _infoRow('Estate', s.estateName ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                  ),
                  child: Column(
                    children: [
                      _linkRow(
                        context,
                        icon: Icons.poll_outlined,
                        label: 'Polls',
                        showBorder: true,
                        onTap: () => context.push('/resident/polls'),
                      ),
                      _linkRow(
                        context,
                        icon: Icons.menu_book_outlined,
                        label: 'Rules & Regulations',
                        showBorder: true,
                        onTap: () => context.push('/resident/rules'),
                      ),
                      _linkRow(
                        context,
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Submit a Complaint',
                        showBorder: true,
                        onTap: () {
                          notifier.resetComplaintForm();
                          context.push('/resident/complaint');
                        },
                      ),
                      _linkRow(
                        context,
                        icon: Icons.history_outlined,
                        label: 'My Complaints',
                        showBorder: true,
                        onTap: () {
                          notifier.loadComplaints();
                          context.push('/resident/complaint/log');
                        },
                      ),
                      _linkRow(
                        context,
                        icon: Icons.phonelink_lock_outlined,
                        label: 'Manage Devices',
                        showBorder: true,
                        onTap: () => context.push('/resident/profile/devices'),
                      ),
                      _linkRow(
                        context,
                        icon: Icons.pin_outlined,
                        label: (s.currentUser?.hasPin ?? false)
                            ? 'Change Transaction PIN'
                            : 'Set Transaction PIN',
                        showBorder: true,
                        onTap: () => context.push('/resident/profile/pin'),
                      ),
                      _linkRow(
                        context,
                        icon: Icons.record_voice_over_outlined,
                        label: 'Assistant Voice',
                        showBorder: true,
                        onTap: () => context.push('/resident/profile/voice'),
                      ),
                      _linkRow(
                        context,
                        icon: Icons.shield_outlined,
                        label: 'Emergency SOS',
                        iconColor: ChColors.danger,
                        iconBg: ChColors.danger.withValues(alpha: 0.12),
                        onTap: () => context.push('/resident/sos'),
                      ),
                    ],
                  ),
                ),
                if (s.biometricAvailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ChColors.surface,
                      borderRadius: BorderRadius.circular(ChRadii.card),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.rs(32),
                          height: context.rs(32),
                          decoration: BoxDecoration(
                            color: ChColors.accent2N(100),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            size: context.rs(17),
                            color: ChColors.accent2,
                          ),
                        ),
                        SizedBox(width: context.rs(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric Login',
                                style: ChTextStyles.body(fontSize: 14),
                              ),
                              if (!(s.currentUser?.hasPin ?? false))
                                Text(
                                  'Also requires a transaction PIN',
                                  style: ChTextStyles.body(fontSize: 11.5, color: ChColors.bodyText),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: s.biometricEnabled,
                          activeThumbColor: ChColors.accent2,
                          onChanged: (value) async {
                            if (value) {
                              final ok = await notifier.enableBiometrics();
                              if (ok && !(s.currentUser?.hasPin ?? false) && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Set a transaction PIN too so the lock screen can use both.'),
                                  ),
                                );
                              }
                            } else {
                              await notifier.disableBiometrics();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: notifier.logout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChColors.surface,
                      borderRadius: BorderRadius.circular(ChRadii.button),
                    ),
                    child: Text(
                      'Log Out',
                      style: ChTextStyles.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChColors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool showBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: ChColors.divider)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ChTextStyles.body(
              fontSize: 14,
              color: ChColors.bodyText,
            ),
          ),
          Text(
            value,
            style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBorder = false,
    Color? iconColor,
    Color? iconBg,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: showBorder
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: ChColors.divider)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: context.rs(32),
              height: context.rs(32),
              decoration: BoxDecoration(
                color: iconBg ?? ChColors.accent2N(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.rs(15),
                color: iconColor ?? ChColors.accent2N(700),
              ),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Text(label, style: ChTextStyles.body(fontSize: 14)),
            ),
            Text(
              '›',
              style: ChTextStyles.body(
                fontSize: 16,
                color: ChColors.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
