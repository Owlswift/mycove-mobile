import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_phone_field.dart';
import '../../../../core/widgets/ch_text_field.dart';
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
          ChGenericHeader(title: 'Invite Resident', centerTitle: true, onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(32)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: context.rs(48), color: ChColors.accent2),
                    SizedBox(height: context.rs(14)),
                    Text(
                      'Invitation sent',
                      style: ChTextStyles.heading(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rs(8)),
                    Text(
                      "Your estate admin needs to approve this before $_fullName can create their account.",
                      textAlign: TextAlign.center,
                      style: ChTextStyles.body(fontSize: 13.5, color: ChColors.bodyText, height: 1.4),
                    ),
                    SizedBox(height: context.rs(20)),
                    ChButton(label: 'Done', onPressed: () => context.pop()),
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
        ChGenericHeader(title: 'Invite Resident', centerTitle: true, onBack: () => context.pop()),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(10), context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "They'll get their own independent MyCove account — their own login, PIN, and history — without being separately charged estate dues.",
                  style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText, height: 1.4),
                ),
                SizedBox(height: context.rs(20)),
                ChTextField(
                  label: 'Full Name',
                  value: _fullName,
                  onChanged: (v) => setState(() => _fullName = v),
                  placeholder: "e.g. Resident's full name",
                ),
                SizedBox(height: context.rs(16)),
                Text('Phone Number', style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w500, color: ChColors.text)),
                SizedBox(height: context.rs(6)),
                ChPhoneField(value: _phone, onChanged: (v) => setState(() => _phone = v)),
                if (_error != null) ...[
                  SizedBox(height: context.rs(12)),
                  Text(_error!, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                ],
                SizedBox(height: context.rs(24)),
                ChButton(label: 'Send Invitation', onPressed: _submitting ? null : _submit, isLoading: _submitting),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
