import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_text_button.dart';
import '../../../../core/widgets/mc_toast.dart';
import '../../../../state/detail_providers.dart';
import '../widgets/domestic_format.dart';
import '../widgets/domestic_parts.dart';
import '../widgets/domestic_illustration.dart';
import '../widgets/whatsapp_icon.dart';

/// Domestic staff the resident has authorised to get their own entry code
/// over WhatsApp. With none added yet it introduces the feature; after that
/// it lists them, and any request waiting for the resident's approval sits
/// at the top.
class DomesticStaffPage extends ConsumerWidget {
  const DomesticStaffPage({super.key});

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool approve,
  ) async {
    try {
      await ref
          .read(myCoveApiProvider)
          .decideDomesticRequest(id, approve: approve);
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) {
        showMcToast(
          context,
          approve
              ? 'Approved. The code has been sent to them on WhatsApp.'
              : 'Request declined.',
          kind: McToastKind.success,
        );
      }
    } catch (e) {
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) showMcToast(context, extractMessage(e));
    }
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? existing,
  }) async {
    await context.push('/resident/domestic-staff/add', extra: existing);
    ref.invalidate(domesticStaffProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(domesticStaffProvider);
    final requests =
        ref.watch(domesticRequestsProvider).asData?.value ?? const [];
    final showList =
        (staff.asData?.value ?? const []).isNotEmpty || requests.isNotEmpty;

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // The introduction has a titled header; the list carries its own big title.
            McGenericHeader(
              title: showList ? '' : 'Domestic staff',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: staff.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: McColors.accent),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      extractMessage(e),
                      style: McTextStyles.body(
                        fontSize: 13,
                        color: McColors.bodyText,
                      ),
                    ),
                  ),
                ),
                data: (list) => list.isEmpty && requests.isEmpty
                    ? _Intro(onAdd: () => _add(context, ref))
                    : _StaffList(
                        list: list,
                        requests: requests,
                        onAdd: () => _add(context, ref),
                        onOpen: (s) => _add(context, ref, existing: s),
                        onDecide: (id, approve) =>
                            _decide(context, ref, id, approve),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const DomesticIllustration(),
              const SizedBox(height: 28),
              Text(
                'Give your domestic staff access',
                style: McTextStyles.heading(fontSize: 25, height: 1.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Add your cleaner, cook or driver. They message ACCESS to MyCove on WhatsApp and get their own entry code, so you are not bothered each time.',
                style: McTextStyles.body(
                  fontSize: 14,
                  color: McColors.bodyText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: McColors.accent2N(100),
                  borderRadius: BorderRadius.circular(McRadii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0BB66F),
                        shape: BoxShape.circle,
                      ),
                      child: const WhatsappIcon(size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works',
                            style: McTextStyles.heading(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your staff sends ACCESS on WhatsApp. If they are allowed at that time, MyCove sends them a temporary gate code.',
                            style: McTextStyles.body(
                              fontSize: 12,
                              color: McColors.bodyText,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: McButton(
            verticalPadding: 15,
            label: 'Add domestic staff',
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}

class _StaffList extends StatelessWidget {
  const _StaffList({
    required this.list,
    required this.requests,
    required this.onAdd,
    required this.onOpen,
    required this.onDecide,
  });

  final List<Map<String, dynamic>> list;
  final List<Map<String, dynamic>> requests;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>) onOpen;
  final void Function(String id, bool approve) onDecide;

  Widget _card({required Widget child, VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          boxShadow: McColors.cardShadow,
          color: McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.card),
        ),
        child: child,
      ),
    ),
  );

  Widget _line(DomesticIcon icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      children: [
        DomesticGlyph(icon, size: 19, color: McColors.bodyText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          'Domestic staff',
          style: McTextStyles.heading(fontSize: 25, height: 1.3),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage access for your staff members.',
          style: McTextStyles.body(
            fontSize: 13,
            color: McColors.bodyText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        McButton(
          verticalPadding: 15,
          label: 'Add staff',
          leading: const Icon(Icons.add, size: 22, color: Colors.white),
          onPressed: onAdd,
        ),
        const SizedBox(height: 22),
        for (final r in requests)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['staffName']} is asking for an entry code',
                  style: McTextStyles.heading(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Approve to send them a code now.',
                  style: McTextStyles.body(
                    fontSize: 13,
                    color: McColors.bodyText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: McButton(
                        verticalPadding: 15,
                        label: 'Decline',
                        variant: ChButtonVariant.outlined,
                        onPressed: () => onDecide(r['id'] as String, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: McButton(
                        verticalPadding: 15,
                        label: 'Approve',
                        onPressed: () => onDecide(r['id'] as String, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        for (final s in list)
          _card(
            onTap: () => onOpen(s),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: McColors.accent2N(100),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initialsOf(s['name'] as String),
                        style: McTextStyles.heading(
                          fontSize: 14,
                          color: McColors.accent2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'] as String,
                          style: McTextStyles.heading(fontSize: 14),
                        ),
                        _line(DomesticIcon.whatsapp, s['phone'] as String),
                        _line(
                          DomesticIcon.days,
                          daysLabel((s['days'] as List).cast<int>()),
                        ),
                        _line(
                          DomesticIcon.hours,
                          hoursLabel(
                            s['startTime'] as String?,
                            s['endTime'] as String?,
                          ),
                        ),
                        if (s['requiresApproval'] == true)
                          _line(DomesticIcon.approval, 'Requires approval'),
                      ],
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: McColors.bodyText,
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

/// Dashboard strip shown while an entry-code request is waiting for the
/// resident's approval.
class DomesticRequestBanner extends ConsumerWidget {
  const DomesticRequestBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests =
        ref.watch(domesticRequestsProvider).asData?.value ?? const [];
    if (requests.isEmpty) return const SizedBox.shrink();
    final name = requests.first['staffName'] as String;
    final more = requests.length > 1 ? ' (+${requests.length - 1} more)' : '';
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(16)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: McColors.accent2N(100),
        borderRadius: BorderRadius.circular(McRadii.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Text(
              '$name is asking for an entry code$more.',
              style: McTextStyles.body(
                height: 1.6,
                fontSize: 12,
                color: McColors.text,
              ),
            ),
          ),
          McTextButton(
            onPressed: () => context.push('/resident/domestic-staff'),
            label: 'Review',
          ),
        ],
      ),
    );
  }
}
