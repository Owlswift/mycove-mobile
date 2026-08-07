import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../../../../state/detail_providers.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(projectDetailProvider(id));

    return Column(
      children: [
        const ChGenericHeader(title: 'Project'),
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ChColors.accent)),
            error: (e, _) => Center(
              child: Text(
                'Could not load this project.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
            ),
            data: (json) {
              final isCompleted = json['status'] == 'COMPLETED';
              final statusLabel = isCompleted ? 'Completed' : 'In Progress';
              final progress = json['progress'] as int;
              final budget = (json['budget'] as List).cast<Map<String, dynamic>>();
              final allocated = json['allocated'] as int;
              final spent = json['spent'] as int;
              final remaining = json['remaining'] as int;
              final reports = (json['reports'] as List).cast<Map<String, dynamic>>();
              final goal = json['goal'] as int;
              final raised = json['raised'] as int;
              final raisedPct = json['raisedPct'] as int;
              final myDonated = json['myDonated'] as int;
              final pledged = json['pledged'] as int;
              final myPledged = json['myPledged'] as int;
              final mediaBase64 = json['mediaBase64'] as String?;

              return RefreshIndicator(
                onRefresh: () async => ref.read(appStateProvider.notifier).refreshResident(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mediaBase64 != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ChDataMedia(
                            dataUrl: mediaBase64,
                            height: 160,
                            borderRadius: BorderRadius.circular(ChRadii.card),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(child: Text(json['title'] as String, style: ChTextStyles.heading(fontSize: 20))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted ? ChColors.accent2N(100) : ChColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(ChRadii.pill),
                            ),
                            child: Text(
                              statusLabel,
                              style: ChTextStyles.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCompleted ? ChColors.accent2N(700) : ChColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ChRadii.pill),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: ChColors.neutralN(300),
                          valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(json['description'] as String, style: ChTextStyles.body(fontSize: 14)),
                      const SizedBox(height: 18),
                      Text(
                        'BUDGET',
                        style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                            .copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      for (final b in budget)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b['label'] as String, style: ChTextStyles.body(fontSize: 13)),
                              Text(formatNaira(b['amount'] as int), style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Budget', style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            formatNaira(json['totalBudget'] as int),
                            style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if (allocated > 0) ...[
                        const SizedBox(height: 20),
                        Text(
                          'ESTATE FUNDING',
                          style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Allocated from treasury', style: ChTextStyles.body(fontSize: 13)),
                                  Text(formatNaira(allocated), style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Spent (approved invoices)', style: ChTextStyles.body(fontSize: 13)),
                                  Text(formatNaira(spent), style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Remaining', style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text(
                                    formatNaira(remaining),
                                    style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: ChColors.accent2N(700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (goal > 0) ...[
                        const SizedBox(height: 20),
                        Text(
                          'COMMUNITY FUNDRAISING',
                          style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${formatNaira(raised)} raised', style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text('of ${formatNaira(goal)}', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(ChRadii.pill),
                                child: LinearProgressIndicator(
                                  value: raisedPct / 100,
                                  minHeight: 8,
                                  backgroundColor: ChColors.neutralN(300),
                                  valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
                                ),
                              ),
                              if (pledged > 0) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${formatNaira(pledged)} pledged by residents',
                                  style: ChTextStyles.body(fontSize: 12.5, color: ChColors.neutralN(600)),
                                ),
                              ],
                              if (myDonated > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'You donated ${formatNaira(myDonated)}',
                                  style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                                ),
                              ],
                              if (myPledged > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'You pledged ${formatNaira(myPledged)}',
                                  style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                                ),
                              ],
                              const SizedBox(height: 14),
                              ChButton(
                                label: 'Pledge',
                                onPressed: () => _showPledgeSheet(context, ref, id, json['title'] as String),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'UPDATES',
                        style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                            .copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      for (final r in reports)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['author'] as String, style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    Text(r['date'] as String, style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['text'] as String, style: ChTextStyles.body(fontSize: 13)),
                                if (r['mediaBase64'] != null) ...[
                                  const SizedBox(height: 10),
                                  ChDataMedia(
                                    dataUrl: r['mediaBase64'] as String,
                                    height: 140,
                                    borderRadius: BorderRadius.circular(ChRadii.sm),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPledgeSheet(BuildContext context, WidgetRef ref, String projectId, String projectTitle) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChRadii.card)),
      ),
      builder: (sheetContext) => _PledgeSheet(projectId: projectId, projectTitle: projectTitle),
    );
  }
}

class _PledgeSheet extends ConsumerStatefulWidget {
  const _PledgeSheet({required this.projectId, required this.projectTitle});

  final String projectId;
  final String projectTitle;

  @override
  ConsumerState<_PledgeSheet> createState() => _PledgeSheetState();
}

class _PledgeSheetState extends ConsumerState<_PledgeSheet> {
  String _amountText = '';
  bool _submitting = false;
  bool _thanks = false;
  String? _error;

  int? get _amount => int.tryParse(_amountText);

  @override
  Widget build(BuildContext context) {
    if (_thanks) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thanks for your pledge!', style: ChTextStyles.heading(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'We\'ll remind you about it when it\'s time.',
              style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pledge to ${widget.projectTitle}', style: ChTextStyles.heading(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'A pledge is a commitment to donate. Pay the estate whenever you\'re ready — once received, it\'ll be marked as your donation.',
            style: ChTextStyles.body(fontSize: 12.5, color: ChColors.neutralN(600)),
          ),
          const SizedBox(height: 16),
          ChTextField(
            label: 'Amount (₦)',
            value: _amountText,
            onChanged: (v) => setState(() => _amountText = v),
            placeholder: 'e.g. 15000',
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
          ],
          const SizedBox(height: 20),
          ChButton(
            label: _amount != null && _amount! > 0 ? 'Pledge ${formatNaira(_amount!)}' : 'Pledge',
            onPressed: _submitting || _amount == null || _amount! <= 0
                ? null
                : () async {
                    setState(() {
                      _submitting = true;
                      _error = null;
                    });
                    final error = await ref
                        .read(appStateProvider.notifier)
                        .pledge(projectId: widget.projectId, amount: _amount!);
                    if (!context.mounted) return;
                    if (error != null) {
                      setState(() {
                        _submitting = false;
                        _error = error;
                      });
                      return;
                    }
                    ref.invalidate(projectDetailProvider(widget.projectId));
                    setState(() => _thanks = true);
                    final navigator = Navigator.of(context);
                    Future.delayed(const Duration(milliseconds: 1400), () {
                      if (mounted) navigator.pop();
                    });
                  },
          ),
        ],
      ),
    );
  }
}