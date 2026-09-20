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
import '../../../../state/detail_providers.dart';
import '../widgets/domestic_format.dart';
import '../widgets/domestic_illustration.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Approved. The code has been sent to them on WhatsApp.' : 'Declined.')),
        );
      }
    } catch (e) {
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractMessage(e))));
      }
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

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            McGenericHeader(title: 'Domestic staff', centerTitle: true, onBack: () => context.pop()),
            Expanded(
              child: staff.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(extractMessage(e), style: McTextStyles.body(fontSize: 14, color: McColors.danger)),
                  ),
                ),
                data: (list) => list.isEmpty && requests.isEmpty
                    ? _Intro(onAdd: () => _add(context, ref))
                    : _StaffList(
                        list: list,
                        requests: requests,
                        onAdd: () => _add(context, ref),
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
            children: [
              SizedBox(height: context.rs(8)),
              const DomesticIllustration(),
              SizedBox(height: context.rs(24)),
              Text('Give your domestic staff access', style: McTextStyles.heading(fontSize: 26)),
              SizedBox(height: context.rs(12)),
              Text(
                'Add your cleaner, cook or driver. They message ACCESS to MyCove on WhatsApp and get their own entry code, so you are not bothered each time.',
                style: McTextStyles.body(fontSize: 14.5, color: McColors.text),
              ),
              SizedBox(height: context.rs(20)),
              Container(
                padding: EdgeInsets.all(context.rs(16)),
                decoration: BoxDecoration(
                  color: McColors.accent2N(100),
                  borderRadius: BorderRadius.circular(McRadii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.rs(34),
                      height: context.rs(34),
                      decoration: const BoxDecoration(color: Color(0xFF0BB66F), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                    ),
                    SizedBox(width: context.rs(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How it works', style: McTextStyles.heading(fontSize: 15)),
                          SizedBox(height: context.rs(4)),
                          Text(
                            'Your staff sends ACCESS on WhatsApp. If they are allowed at that time, MyCove sends them a temporary gate code.',
                            style: McTextStyles.body(fontSize: 13, color: McColors.text),
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
          padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(8), context.rs(24), context.rs(16)),
          child: McButton(label: 'Add domestic staff', onPressed: onAdd),
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

  Widget _meta(BuildContext context, IconData icon, String text) => Padding(
        padding: EdgeInsets.only(top: context.rs(4)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: McColors.text),
            SizedBox(width: context.rs(6)),
            Expanded(child: Text(text, style: McTextStyles.body(fontSize: 12.5, color: McColors.text))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.rs(20), vertical: context.rs(8)),
      children: [
        Text('Domestic staff', style: McTextStyles.heading(fontSize: 24)),
        SizedBox(height: context.rs(4)),
        Text('Manage access for your staff members.', style: McTextStyles.body(fontSize: 13.5, color: McColors.text)),
        SizedBox(height: context.rs(16)),
        McButton(label: '+ Add staff', onPressed: onAdd),
        SizedBox(height: context.rs(16)),
        for (final r in requests)
          Container(
            margin: EdgeInsets.only(bottom: context.rs(12)),
            padding: EdgeInsets.all(context.rs(14)),
            decoration: BoxDecoration(color: McColors.accent2N(100), borderRadius: BorderRadius.circular(McRadii.card)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['staffName']} is asking for an entry code', style: McTextStyles.heading(fontSize: 15)),
                SizedBox(height: context.rs(4)),
                Text('Approve to send them a code now.', style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                SizedBox(height: context.rs(10)),
                Row(
                  children: [
                    Expanded(
                      child: McButton(
                        label: 'Decline',
                        variant: ChButtonVariant.secondary,
                        onPressed: () => onDecide(r['id'] as String, false),
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(child: McButton(label: 'Approve', onPressed: () => onDecide(r['id'] as String, true))),
                  ],
                ),
              ],
            ),
          ),
        for (final s in list)
          GestureDetector(
            onTap: () => onOpen(s),
            child: Container(
              margin: EdgeInsets.only(bottom: context.rs(12)),
              padding: EdgeInsets.all(context.rs(14)),
              decoration: BoxDecoration(
                color: McColors.surface,
                borderRadius: BorderRadius.circular(McRadii.card),
                boxShadow: McColors.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.rs(44),
                    height: context.rs(44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
                    child: Text(
                      initialsOf(s['name'] as String),
                      style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.accent2),
                    ),
                  ),
                  SizedBox(width: context.rs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] as String, style: McTextStyles.heading(fontSize: 15)),
                        _meta(context, Icons.chat_outlined, s['phone'] as String),
                        _meta(context, Icons.calendar_today_outlined, daysLabel((s['days'] as List).cast<int>())),
                        _meta(context, Icons.access_time, hoursLabel(s['startTime'] as String?, s['endTime'] as String?)),
                        if (s['requiresApproval'] == true) _meta(context, Icons.shield_outlined, 'Requires approval'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: McColors.divider),
                ],
              ),
            ),
          ),
        SizedBox(height: context.rs(24)),
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
            child: Text('$name is asking for an entry code$more.', style: McTextStyles.body(fontSize: 13.5, color: McColors.text)),
          ),
          TextButton(onPressed: () => context.push('/resident/domestic-staff'), child: const Text('Review')),
        ],
      ),
    );
  }
}
