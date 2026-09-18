import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_text_field.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/dues_outstanding_sheet.dart';

class VisitorCreatePage extends ConsumerWidget {
  const VisitorCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const McGenericHeader(title: 'New Visitor Pass'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                McTextField(label: 'Visitor name', value: s.vfName, onChanged: notifier.onVfName, placeholder: 'Full name'),
                const SizedBox(height: 14),
                McTextField(
                  label: 'Phone number',
                  value: s.vfPhone,
                  onChanged: notifier.onVfPhone,
                  placeholder: '0800 000 0000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                McTextField(
                  label: 'Vehicle plate (optional)',
                  value: s.vfPlate,
                  onChanged: notifier.onVfPlate,
                  placeholder: 'e.g. LND 442 KJ',
                ),
                const SizedBox(height: 20),
                if (s.vfError.isNotEmpty && !s.vfDuesBlocked) ...[
                  Text(s.vfError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  const SizedBox(height: 12),
                ],
                McButton(
                  label: 'Generate Pass',
                  onPressed: () async {
                    final id = await notifier.createVisitorPass();
                    if (!context.mounted) return;
                    if (id != null) {
                      context.pushReplacement('/resident/visitor/$id');
                    } else {
                      // The estate blocks passes for residents owing too
                      // many months of dues — offer to take them to pay.
                      final blocked = ref.read(appStateProvider);
                      if (blocked.vfDuesBlocked) {
                        final pay = await showDuesOutstandingSheet(
                          context,
                          monthsOwed: blocked.vfDuesMonthsOwed,
                          balance: blocked.vfDuesBalance,
                        );
                        if (pay && context.mounted) context.go('/resident/dues');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
