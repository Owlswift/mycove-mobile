import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
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
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: ChColors.bg, size: 30),
          ),
          const SizedBox(height: 18),
          Text('Complaint submitted', style: ChTextStyles.heading(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Reference ${s.complaintRef} · the estate office will follow up.',
            textAlign: TextAlign.center,
            style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () {
              ref.read(appStateProvider.notifier).loadComplaints();
              context.go('/resident/complaint/log');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ChColors.accent2, Color(0xff56633f)]),
                borderRadius: BorderRadius.circular(ChRadii.pill),
              ),
              child: Text('View My Complaints', style: ChTextStyles.heading(fontSize: 14, color: ChColors.bg)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.go('/resident/profile'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.pill)),
              child: Text('Done', style: ChTextStyles.heading(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
