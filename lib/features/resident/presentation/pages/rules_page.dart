import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    return Column(
      children: [
        const McGenericHeader(title: 'Rules & Regulations'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              for (final section in s.rulesSections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
                          ),
                          Text(section.title, style: McTextStyles.heading(fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final item in section.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 8, right: 8),
                                decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
                              ),
                              Expanded(child: Text(item, style: McTextStyles.body(fontSize: 13.5))),
                            ],
                          ),
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
}
