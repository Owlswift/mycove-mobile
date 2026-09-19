import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
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
        const McGenericHeader(title: 'Profile'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: context.rs(72),
                    height: context.rs(72),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: const BoxDecoration(
                      color: McColors.accent2,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user?.initials ?? '',
                      style: McTextStyles.body(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    user?.fullName ?? '',
                    style: McTextStyles.heading(fontSize: 18),
                  ),
                  Text(
                    user?.house ?? '',
                    style: McTextStyles.body(
                      fontSize: 13,
                      color: McColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: McColors.cardShadow,
                      color: McColors.surface,
                      borderRadius: BorderRadius.circular(McRadii.card),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Phone', user?.phone ?? '', showBorder: true),
                        if (user?.email?.isNotEmpty ?? false)
                          _infoRow('Email', user!.email!, showBorder: true),
                        // Tappable for everyone — this is how household-
                        // invited members (whose first-login flow skips the
                        // profile step) add or change their emergency contact.
                        _emergencyContactRow(context, ref, notifier),
                        if (user?.vehiclePlates.isNotEmpty ?? false)
                          _infoRow(
                            'Vehicle(s)',
                            user!.vehiclePlates.join(', '),
                            showBorder: true,
                          ),
                        if (_moveInLabel(user?.moveInMonth) != null)
                          _infoRow(
                            'Moved in',
                            _moveInLabel(user!.moveInMonth)!,
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
                      boxShadow: McColors.cardShadow,
                      color: McColors.surface,
                      borderRadius: BorderRadius.circular(McRadii.card),
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
                          onTap: () =>
                              context.push('/resident/profile/devices'),
                        ),
                        // An invited household member has no household of
                        // their own to manage — see HouseholdService.invite's
                        // ForbiddenException and household_page.dart, both of
                        // which already treat this as the account that can't
                        // invite/see others, so the entry point is hidden too.
                        if (s.currentUser?.invitedByName == null)
                          _linkRow(
                            context,
                            icon: Icons.group_outlined,
                            label: 'My Household',
                            showBorder: true,
                            onTap: () =>
                                context.push('/resident/profile/household'),
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
                          iconColor: McColors.danger,
                          iconBg: McColors.danger.withValues(alpha: 0.12),
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
                        boxShadow: McColors.cardShadow,
                        color: McColors.surface,
                        borderRadius: BorderRadius.circular(McRadii.card),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: context.rs(32),
                            height: context.rs(32),
                            decoration: BoxDecoration(
                              color: McColors.accent2N(100),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              size: context.rs(17),
                              color: McColors.accent2,
                            ),
                          ),
                          SizedBox(width: context.rs(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Biometric Login',
                                  style: McTextStyles.body(fontSize: 14, color: McColors.text),
                                ),
                                if (!(s.currentUser?.hasPin ?? false))
                                  Text(
                                    'Also requires a transaction PIN',
                                    style: McTextStyles.body(
                                      fontSize: 11.5,
                                      color: McColors.text,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: s.biometricEnabled,
                            activeThumbColor: McColors.accent2,
                            onChanged: (value) async {
                              if (value) {
                                final ok = await notifier.enableBiometrics();
                                if (ok &&
                                    !(s.currentUser?.hasPin ?? false) &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Set a transaction PIN too so the lock screen can use both.',
                                      ),
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
                        color: McColors.surface,
                        borderRadius: BorderRadius.circular(McRadii.button),
                      ),
                      child: Text(
                        'Log Out',
                        style: McTextStyles.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: McColors.danger,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tappable profile row for the emergency contact — shows the current
  /// value (or "Not set") and opens the edit dialog. Persists through
  /// [AppNotifier.saveEmergencyContact] (PATCH /users/me).
  Widget _emergencyContactRow(
    BuildContext context,
    WidgetRef ref,
    AppNotifier notifier,
  ) {
    final s = ref.watch(appStateProvider);
    final user = s.currentUser;
    final name = user?.emergencyContactName;
    final phone = user?.emergencyContactPhone;
    final hasAny = (name?.isNotEmpty ?? false) || (phone?.isNotEmpty ?? false);
    final value = hasAny
        ? [name, phone].whereType<String>().where((p) => p.isNotEmpty).join(' · ')
        : 'Not set';

    Future<void> openEditor() async {
      final result = await showDialog<(String, String)>(
        context: context,
        builder: (_) => _EditEmergencyContactDialog(
          initialName: name ?? '',
          initialPhone: phone ?? '',
        ),
      );
      if (result == null || !context.mounted) return;
      final removed = result.$1.trim().isEmpty && result.$2.trim().isEmpty;
      final error = await notifier.saveEmergencyContact(
        name: result.$1,
        phone: result.$2,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (removed
                    ? 'Emergency contact removed.'
                    : 'Emergency contact saved.'),
            style: McTextStyles.body(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    }

    return InkWell(
      onTap: openEditor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: McColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency contact',
                    style: McTextStyles.body(
                      fontSize: 14,
                      color: McColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: McTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: hasAny ? McColors.text : McColors.neutralN(500),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: context.rs(16), color: McColors.accent2),
          ],
        ),
      ),
    );
  }

  /// 'YYYY-MM' → 'March 2026'; null when the admin hasn't recorded one.
  static String? _moveInLabel(String? key) {
    if (key == null || !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(key)) return null;
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[int.parse(key.substring(5)) - 1]} ${key.substring(0, 4)}';
  }

  Widget _infoRow(String label, String value, {bool showBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: McColors.divider)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: McTextStyles.body(fontSize: 14, color: McColors.text),
          ),
          Text(
            value,
            style: McTextStyles.body(fontSize: 14, color: McColors.text, fontWeight: FontWeight.w500),
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
                border: Border(bottom: BorderSide(color: McColors.divider)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: context.rs(32),
              height: context.rs(32),
              decoration: BoxDecoration(
                color: iconBg ?? McColors.accent2N(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.rs(15),
                color: iconColor ?? McColors.accent2N(700),
              ),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Text(label, style: McTextStyles.body(fontSize: 14, color: McColors.text)),
            ),
            Text(
              '›',
              style: McTextStyles.body(fontSize: 16, color: McColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding/editing the personal emergency contact. Returns a
/// (name, phone) record on save, null when dismissed. Save requires a
/// phone; the Remove action pops with ('', '') which clears the contact
/// server-side (PATCH /users/me stores '' as null).
class _EditEmergencyContactDialog extends StatefulWidget {
  const _EditEmergencyContactDialog({
    required this.initialName,
    required this.initialPhone,
  });

  final String initialName;
  final String initialPhone;

  @override
  State<_EditEmergencyContactDialog> createState() =>
      _EditEmergencyContactDialogState();
}

class _EditEmergencyContactDialogState
    extends State<_EditEmergencyContactDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initialPhone,
  );
  String? _error;

  /// A contact exists server-side — show the Remove action so it can be
  /// cleared; a never-set contact has nothing to remove.
  bool get _hasExisting =>
      widget.initialName.isNotEmpty || widget.initialPhone.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    // Save always requires a phone so SOS always has someone to call.
    // Removing the contact entirely is the dedicated Remove action, which
    // pops with both fields empty and clears it server-side.
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your emergency contact\'s phone number.');
      return;
    }
    Navigator.of(context).pop((name, phone));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: McColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(McRadii.card),
      ),
      title: Text(
        'Emergency contact',
        style: McTextStyles.heading(fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            style: McTextStyles.inputValue(),
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              labelStyle: McTextStyles.inputPlaceholder(),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(McRadii.sm),
                borderSide: const BorderSide(color: McColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(McRadii.sm),
                borderSide: const BorderSide(color: McColors.accent2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            style: McTextStyles.inputValue(),
            decoration: InputDecoration(
              labelText: 'Phone number',
              labelStyle: McTextStyles.inputPlaceholder(),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(McRadii.sm),
                borderSide: const BorderSide(color: McColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(McRadii.sm),
                borderSide: const BorderSide(color: McColors.accent2),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: McTextStyles.body(fontSize: 12.5, color: McColors.danger),
            ),
          ],
          if (_hasExisting)
            TextButton(
              onPressed: () => Navigator.of(context).pop(('', '')),
              style: TextButton.styleFrom(foregroundColor: McColors.danger),
              child: const Text('Remove contact'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: McColors.text),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          style: TextButton.styleFrom(foregroundColor: McColors.accent2),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
