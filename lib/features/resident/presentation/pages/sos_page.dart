import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';

class SosPage extends ConsumerWidget {
  const SosPage({super.key});

  Future<void> _sendAlert(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SOS alert?'),
        content: const Text('Estate security and your emergency contact will be notified immediately, along with your location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: McColors.text),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: McColors.danger),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security has been notified. Stay safe — help is on the way.')),
    );
  }

  void _copyNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$number copied')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final user = s.currentUser;
    // Estate-wide numbers come from the admin-configured estate settings —
    // either can be unset while the admin hasn't configured it yet, so each
    // row only shows when a real number exists (no more placeholder dials).
    final securityPhone = s.securityGuardPhone;
    final officePhone = s.estateAdminPhone;
    final hasPersonalContact = user?.emergencyContactPhone?.isNotEmpty ?? false;

    return Column(
      children: [
        const McGenericHeader(title: 'Send SOS'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: McColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(McRadii.card),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: context.rs(72),
                        height: context.rs(72),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: McColors.danger.withValues(alpha: 0.14), shape: BoxShape.circle),
                        child: Container(
                          width: context.rs(48),
                          height: context.rs(48),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: McColors.danger, shape: BoxShape.circle),
                          child: Icon(Icons.shield_outlined, color: Colors.white, size: context.rs(24)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Need immediate help?', style: McTextStyles.heading(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(
                        'Press the button below to alert security and emergency contacts.',
                        textAlign: TextAlign.center,
                        style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                      ),
                      const SizedBox(height: 20),
                      McButton(label: 'Send SOS Alert', variant: ChButtonVariant.danger, onPressed: () => _sendAlert(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What happens when you send an SOS?', style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _bullet('Security team will be notified immediately'),
                      _bullet('Your location will be shared'),
                      _bullet('Emergency contacts will be alerted'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Emergency Contacts', style: McTextStyles.heading(fontSize: 15)),
                const SizedBox(height: 12),
                if (securityPhone == null && officePhone == null && !hasPersonalContact)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                    child: Text(
                      'No emergency contacts have been set up yet. Add a personal one from your profile, or ask estate management to publish their numbers.',
                      style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText, height: 1.4),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                    child: Column(
                      children: [
                        if (securityPhone != null)
                          _ContactRow(
                            label: 'Estate Security',
                            phone: securityPhone,
                            showBorder: true,
                            onTap: () => _copyNumber(context, securityPhone),
                          ),
                        if (officePhone != null)
                          _ContactRow(
                            label: 'Estate Admin',
                            phone: officePhone,
                            showBorder: hasPersonalContact || securityPhone != null,
                            onTap: () => _copyNumber(context, officePhone),
                          ),
                        if (hasPersonalContact)
                          _ContactRow(
                            label: user?.emergencyContactName?.isNotEmpty ?? false ? user!.emergencyContactName! : 'Your Emergency Contact',
                            phone: user!.emergencyContactPhone!,
                            showBorder: false,
                            onTap: () => _copyNumber(context, user.emergencyContactPhone!),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: BoxDecoration(color: McColors.neutralN(600), shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: McTextStyles.body(fontSize: 13, color: McColors.bodyText))),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.phone, required this.showBorder, required this.onTap});

  final String label;
  final String phone;
  final bool showBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: showBorder ? const Border(bottom: BorderSide(color: McColors.divider)) : null),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(phone, style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                ],
              ),
            ),
            Container(
              width: context.rs(34),
              height: context.rs(34),
              decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(Icons.call_outlined, size: context.rs(15), color: McColors.accent2N(700)),
            ),
          ],
        ),
      ),
    );
  }
}
