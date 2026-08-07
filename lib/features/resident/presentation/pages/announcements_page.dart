import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_filter_chips.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_tag.dart';
import '../../../../state/app_notifier.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final categories = ['All', ...{for (final a in s.announcements) a.category}];
    final shown = _category == 'All' ? s.announcements : s.announcements.where((a) => a.category == _category).toList();

    return Column(
      children: [
        const ChGenericHeader(title: 'Notices', showBack: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ChFilterChips(
            options: [
              for (final c in categories)
                ChFilterChipOption(
                  label: c == 'All' ? 'All Notices' : c,
                  selected: _category == c,
                  onSelect: () => setState(() => _category = c),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final item = shown[i];
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
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: ChColors.accent2N(100), shape: BoxShape.circle),
                          child: Icon(Icons.campaign_outlined, size: 16, color: ChColors.accent2N(700)),
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
