import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_tag.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/detail_providers.dart';

class AnnouncementDetailPage extends ConsumerWidget {
  const AnnouncementDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(announcementDetailProvider(id));
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const ChGenericHeader(title: 'Notice'),
        Expanded(
          child: detail.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ChColors.accent),
            ),
            error: (e, _) => Center(
              child: Text(
                'Could not load this announcement.',
                style: ChTextStyles.body(
                  fontSize: 14,
                  color: ChColors.bodyText,
                ),
              ),
            ),
            data: (json) => RefreshIndicator(
              onRefresh: () async => notifier.refreshResident(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ChTag(
                          label: json['category'] as String,
                          background: ChColors.accent2N(100),
                          foreground: ChColors.accent2N(800),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM').format(
                            DateTime.parse(json['publishedAt'] as String),
                          ),
                          style: ChTextStyles.body(
                            fontSize: 12,
                            color: ChColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      json['title'] as String,
                      style: ChTextStyles.heading(fontSize: 20),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      json['body'] as String,
                      style: ChTextStyles.body(
                        fontSize: 14,
                        color: ChColors.text,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
