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
import '../widgets/domestic_illustration.dart';
import '../widgets/whatsapp_icon.dart';

/// Domestic staff the resident has authorised to get their own entry code
/// over WhatsApp. With none added yet it introduces the feature; after that
/// it lists them, and any request waiting for the resident's approval sits
/// at the top.
class DomesticStaffPage extends ConsumerWidget {
  const DomesticStaffPage({super.key});

  Future<void> _decide(BuildContext context, WidgetRef ref, String id, bool approve) async {
    try {
      await ref.read(myCoveApiProvider).decideDomesticRequest(id, approve: approve);
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) {
        showMcToast(
          context,
          approve ? 'Approved. The code has been sent to them on WhatsApp.' : 'Request declined.',
          kind: McToastKind.success,
        );
      }
    } catch (e) {
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) showMcToast(context, extractMessage(e));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) async {
    await context.push('/resident/domestic-staff/add', extra: existing);
    ref.invalidate(domesticStaffProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(domesticStaffProvider);
    final requests = ref.watch(domesticRequestsProvider).asData?.value ?? const [];
    final hasStaff = (staff.asData?.value ?? const []).isNotEmpty || requests.isNotEmpty;

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            McGenericHeader(
              title: 'Domestic Staff',
              onBack: () => context.pop(),
              // Same round green "+" the Visitor Passes header uses.
              trailing: hasStaff
                  ? GestureDetector(
                      onTap: () => _add(context, ref),
                      child: Container(
                        width: context.rs(32),
                        height: context.rs(32),
                        decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
                        child: Icon(Icons.add, size: context.rs(18), color: Colors.white),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: staff.when(
                loading: () => const Center(child: CircularProgressIndicator(color: McColors.accent)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(extractMessage(e), style: McTextStyles.body(height: 1.6, fontSize: 13, color: McColors.danger)),
                  ),
                ),
                data: (list) => list.isEmpty && requests.isEmpty
                    ? _Intro(onAdd: () => _add(context, ref))
                    : _StaffList(
                        list: list,
                        requests: requests,
                        onOpen: (s) => _add(context, ref, existing: s),
                        onDecide: (id, approve) => _decide(context, ref, id, approve),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const DomesticIllustration(),
        const SizedBox(height: 22),
        Text('Give your domestic staff access', style: McTextStyles.heading(height: 1.35, fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          'Add your cleaner, cook or driver. They message ACCESS to MyCove on WhatsApp and get their own entry code, so you are not bothered each time.',
          style: McTextStyles.body(height: 1.6, fontSize: 13, color: McColors.bodyText),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: McColors.accent2N(100), borderRadius: BorderRadius.circular(McRadii.card)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF0BB66F), shape: BoxShape.circle),
                child: const WhatsappIcon(size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: McTextStyles.body(height: 1.6, fontSize: 13, fontWeight: FontWeight.w600, color: McColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      'Your staff sends ACCESS on WhatsApp. If they are allowed at that time, MyCove sends them a temporary gate code.',
                      style: McTextStyles.body(height: 1.6, fontSize: 12, color: McColors.bodyText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        McButton(verticalPadding: 15, label: 'Add domestic staff', onPressed: onAdd),
      ],
    );
  }
}

class _StaffList extends StatelessWidget {
  const _StaffList({
    required this.list,
    required this.requests,
    required this.onOpen,
    required this.onDecide,
  });

  final List<Map<String, dynamic>> list;
  final List<Map<String, dynamic>> requests;
  final void Function(Map<String, dynamic>) onOpen;
  final void Function(String id, bool approve) onDecide;

  Widget _card({required Widget child, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              boxShadow: McColors.cardShadow,
              color: McColors.surface,
              borderRadius: BorderRadius.circular(McRadii.card),
            ),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final r in requests)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['staffName']} is asking for an entry code',
                  style: McTextStyles.body(height: 1.6, fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
                ),
                const SizedBox(height: 4),
                Text('Approve to send them a code now.', style: McTextStyles.body(height: 1.6, fontSize: 11.5, color: McColors.bodyText)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: McButton(
                        verticalPadding: 15,
                        label: 'Decline',
                        variant: ChButtonVariant.secondary,
                        onPressed: () => onDecide(r['id'] as String, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: McButton(verticalPadding: 15, label: 'Approve', onPressed: () => onDecide(r['id'] as String, true))),
                  ],
                ),
              ],
            ),
          ),
        for (final s in list)
          _card(
            onTap: () => onOpen(s),
            child: Row(
              children: [
                Container(
                  width: context.rs(40),
                  height: context.rs(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
                  child: Text(
                    initialsOf(s['name'] as String),
                    style: McTextStyles.body(height: 1.6, fontSize: 13, fontWeight: FontWeight.w700, color: McColors.accent2N(700)),
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
                          Expanded(
                            child: Text(
                              s['name'] as String,
                              style: McTextStyles.body(height: 1.6, fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
                            ),
                          ),
                          if (s['requiresApproval'] == true) const _ApprovalPill(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(s['phone'] as String, style: McTextStyles.body(height: 1.6, fontSize: 11.5, color: McColors.bodyText)),
                      const SizedBox(height: 2),
                      Text(
                        '${daysLabel((s['days'] as List).cast<int>())} · ${hoursLabel(s['startTime'] as String?, s['endTime'] as String?)}',
                        style: McTextStyles.body(height: 1.6, fontSize: 11.5, color: McColors.bodyText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ApprovalPill extends StatelessWidget {
  const _ApprovalPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: McColors.accent2N(100), borderRadius: BorderRadius.circular(McRadii.pill)),
      child: Text('APPROVAL', style: McTextStyles.body(height: 1.6, fontSize: 10, fontWeight: FontWeight.w700, color: McColors.accent2N(700))),
    );
  }
}

/// Dashboard strip shown while an entry-code request is waiting for the
/// resident's approval.
class DomesticRequestBanner extends ConsumerWidget {
  const DomesticRequestBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(domesticRequestsProvider).asData?.value ?? const [];
    if (requests.isEmpty) return const SizedBox.shrink();
    final name = requests.first['staffName'] as String;
    final more = requests.length > 1 ? ' (+${requests.length - 1} more)' : '';
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(16)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(color: McColors.accent2N(100), borderRadius: BorderRadius.circular(McRadii.card)),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Text('$name is asking for an entry code$more.', style: McTextStyles.body(height: 1.6, fontSize: 13, color: McColors.text)),
          ),
          McTextButton(onPressed: () => context.push('/resident/domestic-staff'), label: 'Review'),
        ],
      ),
    );
  }
}
