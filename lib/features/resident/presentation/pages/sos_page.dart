import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

// The estate doesn't have a security-desk/management-office number stored
// anywhere in the backend yet — these are placeholders until that lands.
const _estateSecurityPhone = '0800 123 4567';
const _managementOfficePhone = '0800 765 4321';

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
            style: TextButton.styleFrom(foregroundColor: ChColors.text),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ChColors.danger),
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
    final user = ref.watch(appStateProvider).currentUser;

    return Column(
      children: [
        const ChGenericHeader(title: 'Send SOS'),
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
                    color: ChColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(ChRadii.card),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: context.rs(72),
                        height: context.rs(72),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: ChColors.danger.withValues(alpha: 0.14), shape: BoxShape.circle),
                        child: Container(
                          width: context.rs(48),
                          height: context.rs(48),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: ChColors.danger, shape: BoxShape.circle),
                          child: Icon(Icons.shield_outlined, color: Colors.white, size: context.rs(24)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Need immediate help?', style: ChTextStyles.heading(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(
                        'Press the button below to alert security and emergency contacts.',
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
                      ),
                      const SizedBox(height: 20),
                      ChButton(label: 'Send SOS Alert', variant: ChButtonVariant.danger, onPressed: () => _sendAlert(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What happens when you send an SOS?', style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _bullet('Security team will be notified immediately'),
                      _bullet('Your location will be shared'),
                      _bullet('Emergency contacts will be alerted'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Emergency Contacts', style: ChTextStyles.heading(fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                  child: Column(
                    children: [
                      _ContactRow(
                        label: 'Estate Security',
                        phone: _estateSecurityPhone,
                        showBorder: true,
                        onTap: () => _copyNumber(context, _estateSecurityPhone),
                      ),
                      _ContactRow(
                        label: 'Management Office',
                        phone: _managementOfficePhone,
                        showBorder: user?.emergencyContactPhone?.isNotEmpty ?? false,
                        onTap: () => _copyNumber(context, _managementOfficePhone),
                      ),
                      if (user?.emergencyContactPhone?.isNotEmpty ?? false)
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
            decoration: BoxDecoration(color: ChColors.neutralN(600), shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText))),
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
        decoration: BoxDecoration(border: showBorder ? const Border(bottom: BorderSide(color: ChColors.divider)) : null),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(phone, style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText)),
                ],
              ),
            ),
            Container(
              width: context.rs(34),
              height: context.rs(34),
              decoration: BoxDecoration(color: ChColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(Icons.call_outlined, size: context.rs(15), color: ChColors.accent2N(700)),
            ),
          ],
        ),
      ),
    );
  }
}
