import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_data_media.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_underline_tabs.dart';
import '../../../../state/app_notifier.dart';

enum _ProjectFilter { all, inProgress, completed }

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  _ProjectFilter _filter = _ProjectFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final shown = switch (_filter) {
      _ProjectFilter.all => s.projects,
      _ProjectFilter.inProgress => s.projects.where((p) => !p.isCompleted).toList(),
      _ProjectFilter.completed => s.projects.where((p) => p.isCompleted).toList(),
    };

    return Column(
      children: [
        const McGenericHeader(title: 'Projects', showBack: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: McUnderlineTabs(
            options: [
              McUnderlineTabOption(label: 'All', selected: _filter == _ProjectFilter.all, onSelect: () => setState(() => _filter = _ProjectFilter.all)),
              McUnderlineTabOption(label: 'In Progress', selected: _filter == _ProjectFilter.inProgress, onSelect: () => setState(() => _filter = _ProjectFilter.inProgress)),
              McUnderlineTabOption(label: 'Completed', selected: _filter == _ProjectFilter.completed, onSelect: () => setState(() => _filter = _ProjectFilter.completed)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final p = shown[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => context.push('/resident/projects/${p.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.mediaBase64 != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: McDataMedia(
                                dataUrl: p.mediaBase64!,
                                height: context.rs(100),
                                borderRadius: BorderRadius.circular(McRadii.md),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title, style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: McColors.text)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.isCompleted ? McColors.accent2N(100) : McColors.warning.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(McRadii.pill),
                                      ),
                                      child: Text(
                                        p.status,
                                        style: McTextStyles.body(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.isCompleted ? McColors.accent2N(700) : McColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _ProgressRing(progress: p.progress, completed: p.isCompleted),
                            ],
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.completed});

  final int progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? McColors.accent2 : McColors.accent2N(600);
    return SizedBox(
      width: context.rs(46),
      height: context.rs(46),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: context.rs(46),
            height: context.rs(46),
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 4,
              backgroundColor: McColors.neutralN(200),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          completed
              ? Icon(Icons.check_rounded, size: context.rs(18), color: color)
              : Text('$progress%', style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
