import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_tag.dart';
import '../../../../state/app_notifier.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);

    return Column(
      children: [
        const ChGenericHeader(title: 'Announcements', showBack: false),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: s.announcements.length,
            itemBuilder: (context, i) {
              final item = s.announcements[i];
              final unread = item.unread;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    ref.read(appStateProvider.notifier).openAnnouncement(item.id);
                    context.push('/resident/announcements/${item.id}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: ChColors.accent2N(200), shape: BoxShape.circle),
                          child: const Icon(Icons.campaign_outlined, size: 16, color: ChColors.text),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ChTag(label: item.category, background: ChColors.accent2N(100), foreground: ChColors.accent2N(800)),
                                  Text(item.date, style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.title, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
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
