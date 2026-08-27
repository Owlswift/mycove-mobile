import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_data_media.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_text_field.dart';
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
        const McGenericHeader(title: 'Project'),
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator(color: McColors.accent)),
            error: (e, _) => Center(
              child: Text(
                'Could not load this project.',
                style: McTextStyles.body(fontSize: 14, color: McColors.text),
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
                          child: McDataMedia(
                            dataUrl: mediaBase64,
                            height: context.rs(160),
                            borderRadius: BorderRadius.circular(McRadii.card),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(child: Text(json['title'] as String, style: McTextStyles.heading(fontSize: 13, color: McColors.text))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted ? McColors.accent2N(100) : McColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(McRadii.pill),
                            ),
                            child: Text(
                              statusLabel,
                              style: McTextStyles.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCompleted ? McColors.accent2N(700) : McColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(McRadii.pill),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: McColors.neutralN(300),
                          valueColor: const AlwaysStoppedAnimation(McColors.accent2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(json['description'] as String, style: McTextStyles.body(fontSize: 14, color: McColors.text)),
                      const SizedBox(height: 18),
                      Text(
                        'BUDGET',
                        style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.text)
                            .copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      for (final b in budget)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b['label'] as String, style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                              Text(formatNaira(b['amount'] as int), style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.text)),
                            ],
                          ),
                        ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Budget', style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
                          Text(
                            formatNaira(json['totalBudget'] as int),
                            style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text),
                          ),
                        ],
                      ),
                      if (allocated > 0) ...[
                        const SizedBox(height: 20),
                        Text(
                          'ESTATE FUNDING',
                          style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.text)
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Allocated from treasury', style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                                  Text(formatNaira(allocated), style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.text)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Spent (approved invoices)', style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                                  Text(formatNaira(spent), style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.text)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Remaining', style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
                                  Text(
                                    formatNaira(remaining),
                                    style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.accent2N(700)),
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
                          style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.text)
                              .copyWith(letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${formatNaira(raised)} raised', style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
                                  Text('of ${formatNaira(goal)}', style: McTextStyles.body(fontSize: 12, color: McColors.text)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(McRadii.pill),
                                child: LinearProgressIndicator(
                                  value: raisedPct / 100,
                                  minHeight: 8,
                                  backgroundColor: McColors.neutralN(300),
                                  valueColor: const AlwaysStoppedAnimation(McColors.accent2),
                                ),
                              ),
                              if (pledged > 0) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${formatNaira(pledged)} pledged by residents',
                                  style: McTextStyles.body(fontSize: 12.5, color: McColors.text),
                                ),
                              ],
                              if (myDonated > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'You donated ${formatNaira(myDonated)}',
                                  style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: McColors.accent2N(700)),
                                ),
                              ],
                              // On a completed project an unfulfilled pledge
                              // is surfaced by the outstanding banner below
                              // instead of this neutral line.
                              if (myPledged > 0 && !isCompleted) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'You pledged ${formatNaira(myPledged)}',
                                  style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: McColors.accent2N(700)),
                                ),
                              ],
                              const SizedBox(height: 14),
                              if (isCompleted && myPledged > 0) ...[
                                // Completed projects take no new pledges, but
                                // a resident's unfulfilled pledge stays
                                // visible as outstanding — the estate still
                                // expects that money.
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: McColors.warning.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(McRadii.md),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, size: 18, color: McColors.warning),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your ${formatNaira(myPledged)} pledge is still outstanding on this completed project — please settle it with the estate office.',
                                          style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w600, color: McColors.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (!isCompleted)
                                McButton(
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
                        style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.text)
                            .copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      for (final r in reports)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.md)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['author'] as String, style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: McColors.text)),
                                    Text(r['date'] as String, style: McTextStyles.body(fontSize: 12, color: McColors.text)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['text'] as String, style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                                if (r['mediaBase64'] != null) ...[
                                  const SizedBox(height: 10),
                                  McDataMedia(
                                    dataUrl: r['mediaBase64'] as String,
                                    height: context.rs(140),
                                    borderRadius: BorderRadius.circular(McRadii.sm),
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
      backgroundColor: McColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
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
            Text('Thanks for your pledge!', style: McTextStyles.heading(fontSize: 18, color: McColors.text), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'We\'ll remind you about it when it\'s time.',
              style: McTextStyles.body(fontSize: 13, color: McColors.text),
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
          Text('Pledge to ${widget.projectTitle}', style: McTextStyles.heading(fontSize: 18, color: McColors.text)),
          const SizedBox(height: 6),
          Text(
            'A pledge is a commitment to donate. Pay the estate whenever you\'re ready — once received, it\'ll be marked as your donation.',
            style: McTextStyles.body(fontSize: 12.5, color: McColors.text),
          ),
          const SizedBox(height: 16),
          McTextField(
            label: 'Amount (₦)',
            value: _amountText,
            onChanged: (v) => setState(() => _amountText = v),
            placeholder: 'e.g. 15000',
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
          ],
          const SizedBox(height: 20),
          McButton(
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