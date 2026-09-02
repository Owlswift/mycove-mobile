import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_underline_tabs.dart';
import '../../../../data/models/visitor_pass.dart';
import '../../../../state/app_notifier.dart';

class VisitorPage extends ConsumerStatefulWidget {
  const VisitorPage({super.key});

  @override
  ConsumerState<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends ConsumerState<VisitorPage> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final passes = [...s.visitorPasses]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final active = passes.where((p) => p.status == VisitorPassStatus.active).toList();
    final history = passes.where((p) => p.status != VisitorPassStatus.active).toList();
    final shown = _showActive ? active : history;

    return Column(
      children: [
        McGenericHeader(
          title: 'Visitor Passes',
          showBack: false,
          trailing: GestureDetector(
            onTap: () {
              notifier.resetVisitorForm();
              context.push('/resident/visitor/new');
            },
            child: Container(
              width: context.rs(32),
              height: context.rs(32),
              decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
              child: Icon(Icons.add, size: context.rs(18), color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: McUnderlineTabs(
            options: [
              McUnderlineTabOption(label: 'Active (${active.length})', selected: _showActive, onSelect: () => setState(() => _showActive = true)),
              McUnderlineTabOption(label: 'History', selected: !_showActive, onSelect: () => setState(() => _showActive = false)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: shown.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    children: [
                      Icon(Icons.badge_outlined, size: 44, color: McColors.neutralN(400)),
                      const SizedBox(height: 12),
                      Text(
                        _showActive ? 'No active passes' : 'No pass history yet',
                        textAlign: TextAlign.center,
                        style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                      for (final p in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => context.push('/resident/visitor/${p.id}'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                              child: Row(
                                children: [
                                  Container(
                                    width: context.rs(40),
                                    height: context.rs(40),
                                    decoration: BoxDecoration(
                                      color: p.isInside ? McColors.accent2N(100) : McColors.surfaceSunken,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.qr_code_2_rounded,
                                      size: context.rs(18),
                                      color: p.isInside ? McColors.accent2N(700) : McColors.neutralN(600),
                                    ),
                                  ),
                                  SizedBox(width: context.rs(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(p.name, style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text))),
                                            _StatusPill(p: p),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.plate == '—' ? p.visitLabel : '${p.plate} · ${p.visitLabel}',
                                          style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('EEE, MMM d · h:mm a').format(p.createdAt),
                                          style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.p});

  final VisitorPass p;

  String get _label {
    if (p.status == VisitorPassStatus.revoked) return 'REVOKED';
    if (p.status != VisitorPassStatus.active) return 'EXPIRED';
    return p.isInside ? 'INSIDE' : (p.hasEntered ? 'LEFT' : 'ACTIVE');
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (p.status) {
      VisitorPassStatus.revoked => (McColors.danger.withValues(alpha: 0.1), McColors.danger),
      VisitorPassStatus.expired => (McColors.neutralN(200), McColors.bodyText),
      VisitorPassStatus.active => (McColors.accent2N(100), McColors.accent2N(700)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(McRadii.pill)),
      child: Text(_label, style: McTextStyles.body(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
