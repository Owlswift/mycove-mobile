import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_phone_field.dart';
import '../../../../core/widgets/mc_text_field.dart';
import '../../../../state/app_notifier.dart';

class InviteResidentPage extends ConsumerStatefulWidget {
  const InviteResidentPage({super.key});

  @override
  ConsumerState<InviteResidentPage> createState() => _InviteResidentPageState();
}

class _InviteResidentPageState extends ConsumerState<InviteResidentPage> {
  String _fullName = '';
  String _phone = '';
  bool _submitting = false;
  String? _error;
  bool _sent = false;

  Future<void> _submit() async {
    if (_fullName.trim().isEmpty || _phone.trim().isEmpty) {
      setState(() => _error = 'Enter a name and phone number.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ref
        .read(appStateProvider.notifier)
        .sendHouseholdInvite(fullName: _fullName.trim(), phone: _phone);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    setState(() {
      _submitting = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Column(
        children: [
          McGenericHeader(title: 'Invite Resident', centerTitle: true, onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(32)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: context.rs(48), color: McColors.accent2),
                    SizedBox(height: context.rs(14)),
                    Text(
                      'Invitation sent',
                      style: McTextStyles.heading(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rs(8)),
                    Text(
                      "Your estate admin needs to approve this before $_fullName can create their account.",
                      textAlign: TextAlign.center,
                      style: McTextStyles.body(fontSize: 13.5, color: McColors.bodyText, height: 1.4),
                    ),
                    SizedBox(height: context.rs(20)),
                    McButton(label: 'Done', onPressed: () => context.pop()),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        McGenericHeader(title: 'Invite Resident', centerTitle: true, onBack: () => context.pop()),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(10), context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "They'll get their own independent MyCove account — their own login, PIN, and history — without being separately charged estate dues.",
                  style: McTextStyles.body(fontSize: 13, color: McColors.bodyText, height: 1.4),
                ),
                SizedBox(height: context.rs(20)),
                McTextField(
                  label: 'Full Name',
                  value: _fullName,
                  onChanged: (v) => setState(() => _fullName = v),
                  placeholder: "e.g. Resident's full name",
                ),
                SizedBox(height: context.rs(16)),
                Text('Phone Number', style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w500, color: McColors.text)),
                SizedBox(height: context.rs(6)),
                McPhoneField(value: _phone, onChanged: (v) => setState(() => _phone = v)),
                if (_error != null) ...[
                  SizedBox(height: context.rs(12)),
                  Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                ],
                SizedBox(height: context.rs(24)),
                McButton(label: 'Send Invitation', onPressed: _submitting ? null : _submit, isLoading: _submitting),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
