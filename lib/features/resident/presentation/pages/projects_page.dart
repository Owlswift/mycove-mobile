import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    return Column(
      children: [
        const ChGenericHeader(title: 'Projects'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: s.projects.length,
            itemBuilder: (context, i) {
              final p = s.projects[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => context.push('/resident/projects/${p.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.mediaBase64 != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ChDataMedia(
                              dataUrl: p.mediaBase64!,
                              height: 90,
                              borderRadius: BorderRadius.circular(ChRadii.sm),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 90,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: ChColors.neutralN(200), borderRadius: BorderRadius.circular(ChRadii.sm)),
                            child: Text('project photo', style: ChTextStyles.body(fontSize: 11, color: ChColors.neutralN(600))),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(p.title, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600))),
                            Text(
                              p.status,
                              style: ChTextStyles.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.isCompleted ? ChColors.accent2N(700) : ChColors.accentN(700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(ChRadii.pill),
                          child: LinearProgressIndicator(
                            value: p.progress / 100,
                            minHeight: 6,
                            backgroundColor: ChColors.neutralN(300),
                            valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
          ),
        ),
      ],
    );
  }
}
