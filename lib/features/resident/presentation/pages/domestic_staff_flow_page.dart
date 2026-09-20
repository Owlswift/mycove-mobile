import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode, CupertinoTextThemeData, CupertinoTheme, CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_sheet.dart';
import '../../../../core/widgets/mc_text_button.dart';
import '../../../../state/detail_providers.dart';
import '../widgets/domestic_format.dart';

enum _Step { basics, hours, review, success }

const _dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

/// Adding (or editing) a domestic staff member as a short flow of full pages:
/// basic details → access hours → review → done. Editing starts at the
/// review page, where each section has its own Edit link.
class DomesticStaffFlowPage extends ConsumerStatefulWidget {
  const DomesticStaffFlowPage({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<DomesticStaffFlowPage> createState() => _DomesticStaffFlowPageState();
}

class _DomesticStaffFlowPageState extends ConsumerState<DomesticStaffFlowPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final Set<int> _days = {};
  bool _setHours = false;
  String _start = '08:00';
  String _end = '14:00';
  bool _approval = false;

  _Step _step = _Step.basics;
  bool _fromReview = false; // an Edit link was used — go back to the review afterwards
  bool _busy = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e['name'] as String;
      _phone.text = e['phone'] as String;
      _days.addAll((e['days'] as List).cast<int>());
      final start = e['startTime'] as String?;
      final end = e['endTime'] as String?;
      _setHours = start != null && end != null;
      if (_setHours) {
        _start = start!;
        _end = end!;
      }
      _approval = e['requiresApproval'] as bool? ?? false;
      _step = _Step.review;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// The number as +234…, from what was typed after the +234 prefix.
  String? get _fullPhone {
    if (_editing) return widget.existing!['phone'] as String;
    var digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('234')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length == 10 ? '+234$digits' : null;
  }

  String? get _startTime => _setHours ? _start : null;
  String? get _endTime => _setHours ? _end : null;

  void _go(_Step step) => setState(() {
        _step = step;
        _error = null;
      });

  void _back() {
    switch (_step) {
      case _Step.basics:
        if (_fromReview) {
          _go(_Step.review);
        } else {
          Navigator.of(context).pop();
        }
      case _Step.hours:
        _go(_fromReview ? _Step.review : _Step.basics);
      case _Step.review:
        if (_editing || _fromReview) {
          Navigator.of(context).pop();
        } else {
          _go(_Step.hours);
        }
      case _Step.success:
        Navigator.of(context).pop();
    }
  }

  void _editFromReview(_Step step) {
    _fromReview = true;
    _go(step);
  }

  void _basicsNext() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter their name.');
      return;
    }
    if (_fullPhone == null) {
      setState(() => _error = 'Enter their WhatsApp number, e.g. 801 234 5678.');
      return;
    }
    _go(_fromReview ? _Step.review : _Step.hours);
  }

  void _hoursSave() {
    if (_setHours && _minutes(_end) <= _minutes(_start)) {
      setState(() => _error = 'The end time must be after the start time.');
      return;
    }
    _go(_Step.review);
  }

  int _minutes(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));

  Future<void> _submit() async {
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
          startTime: _startTime,
          endTime: _endTime,
          requiresApproval: _approval,
        );
        ref.invalidate(domesticStaffProvider);
        if (mounted) Navigator.of(context).pop();
      } else {
        await api.addDomesticStaff(
          name: _name.text.trim(),
          phone: _fullPhone!,
          days: days,
          startTime: _startTime,
          endTime: _endTime,
          requiresApproval: _approval,
        );
        ref.invalidate(domesticStaffProvider);
        if (mounted) {
          setState(() {
            _busy = false;
            _step = _Step.success;
          });
        }
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = extractMessage(e);
      });
    }
  }

  Future<void> _remove() async {
    final sure = await showMcConfirmSheet(
      context,
      title: 'Remove ${_name.text.trim()}?',
      message: 'They will no longer be able to get an entry code.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (sure != true) return;
    try {
      await ref.read(myCoveApiProvider).removeDomesticStaff(widget.existing!['id'] as String);
      ref.invalidate(domesticStaffProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = extractMessage(e));
    }
  }

  // ── Shared pieces ──────────────────────────────────────────────────────

  Widget _field({required String label, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: McTextStyles.body(fontSize: 12, color: McColors.text.withValues(alpha: 0.7))),
          const SizedBox(height: 5),
          child,
        ],
      );

  /// The theme already gives every field the app's fill, radius, padding and
  /// Inter placeholder; the typed value uses [McTextStyles.inputValue].
  InputDecoration _decoration(String hint) => InputDecoration(hintText: hint, counterText: '');

  TextStyle get _value => McTextStyles.inputValue();

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.rs(16)),
        margin: EdgeInsets.only(bottom: context.rs(14)),
        decoration: BoxDecoration(
          color: McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.card),
          border: Border.all(color: McColors.divider),
        ),
        child: child,
      );

  Widget _page({
    required String title,
    required List<Widget> children,
    required List<Widget> actions,
  }) {
    return Column(
      children: [
        McGenericHeader(title: title, centerTitle: true, onBack: _back),
        Expanded(
          child: ListView(
            // The phone keypad on iPhone has no Done key: dragging the page closes it.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: context.rs(24), vertical: context.rs(8)),
            children: children,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(8), context.rs(24), context.rs(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: context.rs(10)),
                  child: Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                ),
              ...actions,
            ],
          ),
        ),
      ],
    );
  }

  // ── Pages ──────────────────────────────────────────────────────────────

  Widget _basics() {
    final anyDay = _days.isEmpty;
    return _page(
      title: _editing ? 'Edit domestic staff' : 'Add domestic staff',
      children: [
        SizedBox(height: context.rs(12)),
        Text('Basic details', style: McTextStyles.cardTitle()),
        SizedBox(height: context.rs(4)),
        Text(
          'Provide the staff member\'s name and WhatsApp number.',
          style: McTextStyles.body(fontSize: 14, color: McColors.text),
        ),
        SizedBox(height: context.rs(18)),
        _field(
          label: 'Name',
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: _value,
            decoration: _decoration('e.g. Mary Johnson'),
          ),
        ),
        SizedBox(height: context.rs(16)),
        _field(
          label: 'WhatsApp number',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(color: McColors.inputFill, borderRadius: BorderRadius.circular(McRadii.button)),
                child: Row(
                  children: [
                    // Nigerian flag
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: context.rs(24),
                        height: context.rs(16),
                        child: Row(
                          children: const [
                            Expanded(child: ColoredBox(color: Color(0xFF008751), child: SizedBox.expand())),
                            Expanded(child: ColoredBox(color: Colors.white, child: SizedBox.expand())),
                            Expanded(child: ColoredBox(color: Color(0xFF008751), child: SizedBox.expand())),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.rs(8)),
                    Text('+234', style: _value),
                  ],
                ),
              ),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: _editing
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(color: McColors.inputFill, borderRadius: BorderRadius.circular(McRadii.button)),
                        child: Text(
                          (widget.existing!['phone'] as String).replaceFirst('+234', ''),
                          style: _value,
                        ),
                      )
                    : TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: _value,
                        decoration: _decoration('e.g. 801 234 5678'),
                      ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(6)),
        Text('Use the number they will message MyCove with.', style: McTextStyles.body(fontSize: 12, color: McColors.text)),
        SizedBox(height: context.rs(24)),
        Text('When can they come?', style: McTextStyles.cardTitle()),
        SizedBox(height: context.rs(4)),
        Text('Select the days they normally visit.', style: McTextStyles.body(fontSize: 14, color: McColors.text)),
        SizedBox(height: context.rs(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 0; d < 7; d++)
              Semantics(
                label: _dayNames[d],
                child: GestureDetector(
                  onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                  child: Container(
                    width: context.rs(40),
                    height: context.rs(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _days.contains(d) ? McColors.accent2 : McColors.surface,
                      border: Border.all(color: _days.contains(d) ? McColors.accent2 : McColors.divider),
                    ),
                    child: Text(
                      _dayLetters[d],
                      style: McTextStyles.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _days.contains(d) ? Colors.white : McColors.text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.rs(12)),
        GestureDetector(
          onTap: () => setState(_days.clear),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(14)),
            decoration: BoxDecoration(
              color: anyDay ? McColors.accent2N(100) : McColors.surface,
              borderRadius: BorderRadius.circular(McRadii.button),
              border: Border.all(color: anyDay ? McColors.accent2 : McColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                SizedBox(width: context.rs(10)),
                Expanded(
                  child: Text(
                    anyDay ? 'Allow any day' : '${daysLabel(_days.toList())} · tap to allow any day',
                    style: McTextStyles.body(fontSize: 14, color: McColors.text),
                  ),
                ),
                Icon(anyDay ? Icons.check_circle : Icons.chevron_right, size: 20, color: anyDay ? McColors.accent2 : McColors.text),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(16)),
      ],
      actions: [McButton(label: _fromReview ? 'Done' : 'Next', onPressed: _basicsNext)],
    );
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    var picked = DateTime(2000, 1, 1, int.parse(current.substring(0, 2)), int.parse(current.substring(3, 5)));
    final confirmed = await showMcSheet<bool>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.rs(24), 0, context.rs(24), context.rs(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(start ? 'From what time?' : 'Until what time?', style: McTextStyles.heading(fontSize: 18)),
              SizedBox(
                height: context.rs(190),
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: McTextStyles.body(fontSize: 20, color: McColors.text),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: picked,
                    onDateTimeChanged: (v) => picked = v,
                  ),
                ),
              ),
              McButton(label: 'Done', onPressed: () => Navigator.of(sheetContext).pop(true)),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = value : _end = value);
  }

  Widget _timeTile(String label, String value, bool start) => GestureDetector(
        onTap: () => _pickTime(start),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: context.rs(12)),
          padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
          decoration: BoxDecoration(color: McColors.inputFill, borderRadius: BorderRadius.circular(McRadii.button)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: McTextStyles.body(fontSize: 12, color: McColors.text)),
                    SizedBox(height: context.rs(2)),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        SizedBox(width: context.rs(8)),
                        Text(timeLabel(value), style: _value),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      );

  Widget _hours() {
    return _page(
      title: _editing ? 'Edit domestic staff' : 'Add domestic staff',
      children: [
        SizedBox(height: context.rs(12)),
        Text('Access hours', style: McTextStyles.cardTitle()),
        SizedBox(height: context.rs(4)),
        Text('Limit access to specific hours (optional).', style: McTextStyles.body(fontSize: 14, color: McColors.text)),
        SizedBox(height: context.rs(18)),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time),
                  SizedBox(width: context.rs(10)),
                  Expanded(child: Text('Set access hours', style: McTextStyles.heading(fontSize: 15))),
                  Switch(value: _setHours, activeThumbColor: McColors.accent2, onChanged: (v) => setState(() => _setHours = v)),
                ],
              ),
              if (_setHours) ...[
                _timeTile('From', _start, true),
                _timeTile('Until', _end, false),
                SizedBox(height: context.rs(10)),
                Text(
                  'They can ask for a code from 15 minutes before the start time until the end time.',
                  style: McTextStyles.body(fontSize: 12, color: McColors.text),
                ),
              ] else ...[
                SizedBox(height: context.rs(4)),
                Text('Off: they can ask for a code at any time on their days.', style: McTextStyles.body(fontSize: 12, color: McColors.text)),
              ],
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined),
                  SizedBox(width: context.rs(10)),
                  Expanded(child: Text('Approve each request', style: McTextStyles.heading(fontSize: 15))),
                  Switch(value: _approval, activeThumbColor: McColors.accent2, onChanged: (v) => setState(() => _approval = v)),
                ],
              ),
              SizedBox(height: context.rs(4)),
              Text(
                'You will get a notification and must approve before they receive a code.',
                style: McTextStyles.body(fontSize: 12, color: McColors.text),
              ),
            ],
          ),
        ),
      ],
      actions: [McButton(label: 'Save', onPressed: _hoursSave)],
    );
  }

  Widget _reviewRow(IconData icon, String title, String value, {VoidCallback? onEdit, bool last = false}) => Container(
        padding: EdgeInsets.symmetric(vertical: context.rs(14)),
        decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: McColors.divider))),
        child: Row(
          children: [
            Container(
              width: context.rs(40),
              height: context.rs(40),
              decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: McColors.accent2),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: McTextStyles.heading(fontSize: 14)),
                  SizedBox(height: context.rs(2)),
                  Text(value, style: McTextStyles.body(fontSize: 13, color: McColors.text)),
                ],
              ),
            ),
            if (onEdit != null)
              McTextButton(label: 'Edit', onPressed: onEdit),
          ],
        ),
      );

  Widget _review() {
    final days = _days.toList()..sort();
    return _page(
      title: 'Review details',
      children: [
        SizedBox(height: context.rs(12)),
        _card(
          child: Column(
            children: [
              _reviewRow(Icons.person_outline, _name.text.trim(), _fullPhone ?? '', onEdit: () => _editFromReview(_Step.basics)),
              _reviewRow(Icons.calendar_today_outlined, 'Access days', daysLabel(days), onEdit: () => _editFromReview(_Step.basics)),
              _reviewRow(Icons.access_time, 'Access hours', hoursLabel(_startTime, _endTime), onEdit: () => _editFromReview(_Step.hours)),
              _reviewRow(
                Icons.shield_outlined,
                'Approval',
                _approval ? 'Require approval for each request' : 'No approval needed',
                onEdit: () => _editFromReview(_Step.hours),
                last: true,
              ),
            ],
          ),
        ),
      ],
      actions: [
        McButton(label: _editing ? 'Save changes' : 'Add domestic staff', onPressed: _busy ? null : _submit, isLoading: _busy),
        SizedBox(height: context.rs(10)),
        if (_editing) ...[
          McButton(label: 'Remove domestic staff', variant: ChButtonVariant.danger, onPressed: _remove),
          SizedBox(height: context.rs(10)),
        ],
        McButton(label: 'Cancel', variant: ChButtonVariant.secondary, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  Widget _success() {
    final days = _days.toList()..sort();
    Widget row(IconData icon, String label, String value) => Padding(
          padding: EdgeInsets.symmetric(vertical: context.rs(10)),
          child: Row(
            children: [
              Icon(icon, size: 22, color: McColors.accent2),
              SizedBox(width: context.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: McTextStyles.body(fontSize: 12, color: McColors.text)),
                    Text(value, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: McColors.text)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
            children: [
              SizedBox(height: context.rs(48)),
              Center(
                child: Container(
                  width: context.rs(96),
                  height: context.rs(96),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: McColors.accent2N(100)),
                  child: Center(
                    child: Container(
                      width: context.rs(64),
                      height: context.rs(64),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: McColors.accent2),
                      child: const Icon(Icons.check, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.rs(20)),
              Text('Domestic staff added', textAlign: TextAlign.center, style: McTextStyles.sectionTitle()),
              SizedBox(height: context.rs(8)),
              Text(
                '${_name.text.trim()} can now request gate access through WhatsApp.',
                textAlign: TextAlign.center,
                style: McTextStyles.body(fontSize: 14, color: McColors.text),
              ),
              SizedBox(height: context.rs(24)),
              Container(
                padding: EdgeInsets.all(context.rs(16)),
                decoration: BoxDecoration(
                  color: McColors.surface,
                  borderRadius: BorderRadius.circular(McRadii.card),
                  border: Border.all(color: McColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 20),
                        SizedBox(width: context.rs(8)),
                        Text('Access summary', style: McTextStyles.heading(fontSize: 15)),
                      ],
                    ),
                    const Divider(),
                    row(Icons.chat_outlined, 'WhatsApp number', _fullPhone ?? ''),
                    row(Icons.calendar_today_outlined, 'Days', daysLabel(days)),
                    row(Icons.access_time, 'Hours', hoursLabel(_startTime, _endTime)),
                    row(Icons.shield_outlined, 'Approval', _approval ? 'Required' : 'Not required'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(8), context.rs(24), context.rs(16)),
          child: McButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_step) {
      _Step.basics => _basics(),
      _Step.hours => _hours(),
      _Step.review => _review(),
      _Step.success => _success(),
    };
    return PopScope(
      canPop: _step == _Step.success ||
          (_step == _Step.basics && !_fromReview) ||
          (_step == _Step.review && (_editing || _fromReview)),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(backgroundColor: McColors.bg, body: SafeArea(child: body)),
    );
  }
}
