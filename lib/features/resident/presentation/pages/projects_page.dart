import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_underline_tabs.dart';
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
        const ChGenericHeader(title: 'Projects'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ChUnderlineTabs(
            options: [
              ChUnderlineTabOption(label: 'All', selected: _filter == _ProjectFilter.all, onSelect: () => setState(() => _filter = _ProjectFilter.all)),
              ChUnderlineTabOption(label: 'In Progress', selected: _filter == _ProjectFilter.inProgress, onSelect: () => setState(() => _filter = _ProjectFilter.inProgress)),
              ChUnderlineTabOption(label: 'Completed', selected: _filter == _ProjectFilter.completed, onSelect: () => setState(() => _filter = _ProjectFilter.completed)),
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
                      decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.mediaBase64 != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ChDataMedia(
                                dataUrl: p.mediaBase64!,
                                height: 100,
                                borderRadius: BorderRadius.circular(ChRadii.md),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.isCompleted ? ChColors.accent2N(100) : ChColors.warning.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(ChRadii.pill),
                                      ),
                                      child: Text(
                                        p.status,
                                        style: ChTextStyles.body(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.isCompleted ? ChColors.accent2N(700) : ChColors.warning,
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
    final color = completed ? ChColors.accent2 : ChColors.accent2N(600);
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 4,
              backgroundColor: ChColors.neutralN(200),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          completed
              ? Icon(Icons.check_rounded, size: 18, color: color)
              : Text('$progress%', style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
