import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final hasUnread = s.notifications.any((n) => !n.read);
    
    return Column(
      children: [
        ChGenericHeader(
          title: 'Notifications',
          trailing: hasUnread
              ? GestureDetector(
                  onTap: () async {
                    await notifier.markNotificationsRead();
                  },
                  child: Text(
                    'Mark all as read',
                    style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: ChColors.accentN(700)),
                  ),
                )
              : null,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(appStateProvider.notifier).refreshResident,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: s.notifications.length,
            itemBuilder: (context, i) {
              final n = s.notifications[i];
              final isMoney = n.type == 'payment' || n.type == 'project';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                    border: n.read ? null : Border.all(color: ChColors.accentN(300), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: context.rs(36),
                        height: context.rs(36),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isMoney ? ChColors.accent2N(200) : ChColors.accentN(200),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: isMoney ? ChColors.accent2 : ChColors.accent, shape: BoxShape.circle),
                        ),
                      ),
                      SizedBox(width: context.rs(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: ChTextStyles.body(
                                fontSize: 14,
                                fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                                color: n.read ? ChColors.bodyText : ChColors.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(n.time, style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText)),
                          ],
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(color: ChColors.accent, shape: BoxShape.circle),
                        ),
                    ],
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
