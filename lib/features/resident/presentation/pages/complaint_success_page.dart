import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../state/app_notifier.dart';

class ComplaintSuccessPage extends ConsumerWidget {
  const ComplaintSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
      child: Column(
        children: [
          Container(
            width: context.rs(64),
            height: context.rs(64),
            decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: context.rs(30)),
          ),
          const SizedBox(height: 18),
          Text('Complaint submitted', style: ChTextStyles.heading(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Reference ${s.complaintRef} · the estate office will follow up.',
            textAlign: TextAlign.center,
            style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
          ),
          const SizedBox(height: 22),
          ChButton(
            label: 'View My Complaints',
            onPressed: () {
              ref.read(appStateProvider.notifier).loadComplaints();
              context.go('/resident/complaint/log');
            },
          ),
          const SizedBox(height: 10),
          ChButton(
            label: 'Done',
            variant: ChButtonVariant.secondary,
            onPressed: () => context.go('/resident/profile'),
          ),
        ],
      ),
    );
  }
}
