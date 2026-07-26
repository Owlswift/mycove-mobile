import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/visitor_pass.dart';
import '../../../../state/app_notifier.dart';

class VisitorPage extends ConsumerWidget {
  const VisitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        ChGenericHeader(
          title: 'Visitor Passes',
          showBack: false,
          trailing: GestureDetector(
            onTap: () {
              notifier.resetVisitorForm();
              context.push('/resident/visitor/new');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 18, color: ChColors.bg),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              for (final p in s.visitorPasses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => context.push('/resident/visitor/${p.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: p.status == VisitorPassStatus.active ? ChColors.accent2N(200) : ChColors.neutralN(200),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 16,
                              color: p.status == VisitorPassStatus.active ? ChColors.accent2N(800) : ChColors.neutralN(600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(p.name, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.status == VisitorPassStatus.active
                                            ? ChColors.accent2N(100)
                                            : ChColors.neutralN(200),
                                        borderRadius: BorderRadius.circular(ChRadii.pill),
                                      ),
                                      child: Text(
                                        p.status == VisitorPassStatus.active ? 'ACTIVE' : 'EXPIRED',
                                        style: ChTextStyles.body(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: p.status == VisitorPassStatus.active
                                              ? ChColors.accent2N(700)
                                              : ChColors.neutralN(600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(p.window, style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  notifier.resetVisitorForm();
                  context.push('/resident/visitor/new');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: ChColors.neutralN(400), width: 1.5),
                    borderRadius: BorderRadius.circular(ChRadii.md),
                  ),
                  child: Text(
                    '+ New Visitor Pass',
                    style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.accentN(700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
