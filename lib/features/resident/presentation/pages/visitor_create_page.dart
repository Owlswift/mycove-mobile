import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class VisitorCreatePage extends ConsumerWidget {
  const VisitorCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const ChGenericHeader(title: 'New Visitor Pass'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChTextField(label: 'Visitor name', value: s.vfName, onChanged: notifier.onVfName, placeholder: 'Full name'),
                const SizedBox(height: 14),
                ChTextField(
                  label: 'Phone number',
                  value: s.vfPhone,
                  onChanged: notifier.onVfPhone,
                  placeholder: '0800 000 0000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                ChTextField(
                  label: 'Vehicle plate (optional)',
                  value: s.vfPlate,
                  onChanged: notifier.onVfPlate,
                  placeholder: 'e.g. LND 442 KJ',
                ),
                const SizedBox(height: 20),
                if (s.vfError.isNotEmpty) ...[
                  Text(s.vfError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                  const SizedBox(height: 12),
                ],
                ChButton(
                  label: 'Generate Pass',
                  onPressed: () async {
                    final id = await notifier.createVisitorPass();
                    if (id != null && context.mounted) {
                      context.pushReplacement('/resident/visitor/$id');
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
