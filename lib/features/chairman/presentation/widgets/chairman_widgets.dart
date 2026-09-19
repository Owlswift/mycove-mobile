import 'package:flutter/material.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';

/// Small building blocks shared by the chairman's screens, so each page
/// stays about its own content rather than repeating card/pill styling.

class ChairmanCard extends StatelessWidget {
  const ChairmanCard({super.key, required this.child, this.margin = const EdgeInsets.only(bottom: 10)});

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        boxShadow: McColors.cardShadow,
        color: McColors.surface,
        borderRadius: BorderRadius.circular(McRadii.card),
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: McColors.bodyText)
            .copyWith(letterSpacing: 1),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(McRadii.pill),
      ),
      child: Text(label, style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// A list that always allows pull-to-refresh, with a friendly message when
/// there's nothing to show.
class ChairmanList extends StatelessWidget {
  const ChairmanList({
    super.key,
    required this.onRefresh,
    required this.children,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final IconData emptyIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: children.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                Icon(emptyIcon, size: 40, color: McColors.accent2N(400)),
                const SizedBox(height: 10),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: McTextStyles.body(fontSize: 14, color: McColors.bodyText),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: children,
            ),
    );
  }
}
