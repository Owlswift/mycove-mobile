import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/ui_options.dart';
import '../../../../state/app_notifier.dart';

class ComplaintPage extends ConsumerWidget {
  const ComplaintPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const ChGenericHeader(title: 'Submit a Complaint'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in complaintCategoryOptions)
                      _CategoryChip(
                        label: cat,
                        selected: s.complaintCategory == cat,
                        onTap: () => notifier.selectComplaintCategory(cat),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Details', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                const SizedBox(height: 5),
                TextField(
                  minLines: 5,
                  maxLines: 8,
                  onChanged: notifier.onComplaintDesc,
                  decoration: const InputDecoration(hintText: 'Describe the issue…'),
                ),
                const SizedBox(height: 14),
                if (s.complaintError.isNotEmpty) ...[
                  Text(s.complaintError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                  const SizedBox(height: 12),
                ],
                ChButton(
                  label: 'Submit Complaint',
                  onPressed: () async {
                    final generatedRef = await notifier.submitComplaint();
                    if (generatedRef != null && context.mounted) {
                      context.push('/resident/complaint/success');
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ChColors.accent2 : null,
          border: selected ? null : Border.all(color: ChColors.divider),
          borderRadius: BorderRadius.circular(ChRadii.pill),
        ),
        child: Text(label, style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : ChColors.text)),
      ),
    );
  }
}
