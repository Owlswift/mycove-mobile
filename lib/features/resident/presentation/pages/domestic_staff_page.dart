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

const _dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

/// Domestic staff the resident has authorised to get their own entry code
/// over WhatsApp — with the days and hours they're expected, and an option
/// to approve each code first. Requests waiting for approval sit at the top.
class DomesticStaffPage extends ConsumerWidget {
  const DomesticStaffPage({super.key});

  Future<void> _decide(BuildContext context, WidgetRef ref, String id, bool approve) async {
    try {
      await ref.read(myCoveApiProvider).decideDomesticRequest(id, approve: approve);
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Approved — the code has been sent to them on WhatsApp.' : 'Declined.')),
        );
      }
    } catch (e) {
      ref.invalidate(domesticRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractMessage(e))));
      }
    }
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
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20), vertical: context.rs(8)),
                children: [
                  Text(
                    'Add your cleaner, cook or driver. They message ACCESS to MyCove on WhatsApp and get their own entry code, so you are not bothered each time.',
                    style: McTextStyles.body(fontSize: 13.5, color: McColors.text),
                  ),
                  SizedBox(height: context.rs(16)),
                  for (final r in requests) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: context.rs(12)),
                      padding: EdgeInsets.all(context.rs(14)),
                      decoration: BoxDecoration(
                        color: McColors.accent2N(100),
                        borderRadius: BorderRadius.circular(McRadii.card),
                      ),
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
                                  onPressed: () => _decide(context, ref, r['id'] as String, false),
                                ),
                              ),
                              SizedBox(width: context.rs(10)),
                              Expanded(
                                child: McButton(
                                  label: 'Approve',
                                  onPressed: () => _decide(context, ref, r['id'] as String, true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  staff.when(
                    loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text(extractMessage(e), style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                    data: (list) => Column(
                      children: [
                        if (list.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: context.rs(24)),
                            child: Text('No domestic staff added yet.', style: McTextStyles.body(fontSize: 14, color: McColors.text)),
                          ),
                        for (final s in list)
                          Container(
                            margin: EdgeInsets.only(bottom: context.rs(10)),
                            decoration: BoxDecoration(
                              color: McColors.surface,
                              borderRadius: BorderRadius.circular(McRadii.card),
                              boxShadow: McColors.cardShadow,
                            ),
                            child: ListTile(
                              title: Text(s['name'] as String, style: McTextStyles.heading(fontSize: 15)),
                              subtitle: Text(
                                '${s['phone']}\n${s['scheduleLabel']}${s['requiresApproval'] == true ? '\nYou approve each code' : ''}',
                                style: McTextStyles.body(fontSize: 12.5, color: McColors.text),
                              ),
                              isThreeLine: true,
                              onTap: () => _openForm(context, ref, existing: s),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.rs(8)),
                  McButton(label: 'Add domestic staff', onPressed: () => _openForm(context, ref)),
                  SizedBox(height: context.rs(24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StaffForm(existing: existing),
    );
    if (saved == true) ref.invalidate(domesticStaffProvider);
  }
}

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late Set<int> _days;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late bool _setHours;
  late bool _approval;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.existing != null;

  static TimeOfDay? _parse(String? t) =>
      t == null ? null : TimeOfDay(hour: int.parse(t.substring(0, 2)), minute: int.parse(t.substring(3, 5)));

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?['name'] as String? ?? '');
    _phone = TextEditingController(text: e?['phone'] as String? ?? '');
    _days = {...((e?['days'] as List?)?.cast<int>() ?? const <int>[])};
    _start = _parse(e?['startTime'] as String?);
    _end = _parse(e?['endTime'] as String?);
    _setHours = _start != null && _end != null;
    _approval = e?['requiresApproval'] as bool? ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? TimeOfDay(hour: start ? 8 : 14, minute: 0),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || (!_editing && _phone.text.trim().isEmpty)) {
      setState(() => _error = 'Enter a name and a WhatsApp number.');
      return;
    }
    if (_setHours && (_start == null || _end == null)) {
      setState(() => _error = 'Choose both a start and an end time, or switch off the hours.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(myCoveApiProvider);
    final days = _days.toList()..sort();
    try {
      if (_editing) {
        await api.updateDomesticStaff(
          widget.existing!['id'] as String,
          name: _name.text.trim(),
          days: days,
          startTime: _setHours ? _fmt(_start!) : null,
          endTime: _setHours ? _fmt(_end!) : null,
          requiresApproval: _approval,
        );
      } else {
        await api.addDomesticStaff(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          days: days,
          startTime: _setHours ? _fmt(_start!) : null,
          endTime: _setHours ? _fmt(_end!) : null,
          requiresApproval: _approval,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = extractMessage(e);
      });
    }
  }

  Future<void> _remove() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${widget.existing!['name']}?'),
        content: const Text('They will no longer be able to get an entry code.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await ref.read(myCoveApiProvider).removeDomesticStaff(widget.existing!['id'] as String);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = extractMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_editing ? 'Edit domestic staff' : 'Add domestic staff', style: McTextStyles.heading(fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                enabled: !_editing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp number',
                  helperText: 'It must be a number they use on WhatsApp.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Days they come', style: McTextStyles.heading(fontSize: 14)),
              const SizedBox(height: 4),
              Text('Leave all off to allow any day.', style: McTextStyles.body(fontSize: 12.5, color: McColors.text)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (var d = 0; d < 7; d++)
                    Tooltip(
                      message: _dayNames[d],
                      child: FilterChip(
                        label: Text(_dayLetters[d]),
                        selected: _days.contains(d),
                        onSelected: (v) => setState(() => v ? _days.add(d) : _days.remove(d)),
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set the hours'),
                subtitle: const Text('They can ask for a code from 15 minutes before the start until the end time. Off = any time.'),
                value: _setHours,
                onChanged: (v) => setState(() => _setHours = v),
              ),
              if (_setHours)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(true),
                        child: Text(_start == null ? 'Start time' : 'From ${_start!.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(false),
                        child: Text(_end == null ? 'End time' : 'Until ${_end!.format(context)}'),
                      ),
                    ),
                  ],
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ask me to approve each code'),
                subtitle: const Text('You will get a notification and must approve before they receive a code.'),
                value: _approval,
                onChanged: (v) => setState(() => _approval = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
              ],
              const SizedBox(height: 12),
              McButton(label: _editing ? 'Save' : 'Add', onPressed: _busy ? null : _save, isLoading: _busy),
              if (_editing)
                TextButton(
                  onPressed: _remove,
                  child: const Text('Remove this person', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
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
