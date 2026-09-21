import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_sheet.dart';
import '../../../../core/widgets/mc_text_button.dart';
import '../../../../core/widgets/mc_toast.dart';
import '../../../../state/detail_providers.dart';
import '../widgets/domestic_format.dart';
import '../widgets/domestic_parts.dart';

enum _Step { basics, hours, review, success }

const _dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// Adding (or editing) a domestic staff member as a short flow of full pages:
/// basic details → access hours → review → done. Editing starts at the
/// review page, where each section has its own Edit link.
class DomesticStaffFlowPage extends ConsumerStatefulWidget {
  const DomesticStaffFlowPage({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<DomesticStaffFlowPage> createState() =>
      _DomesticStaffFlowPageState();
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
  bool _fromReview =
      false; // an Edit link was used — go back to the review afterwards
  bool _busy = false;

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

  void _go(_Step step) => setState(() => _step = step);

  void _fail(String message) => showMcToast(context, message);

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
      _fail('Enter their name.');
      return;
    }
    if (_fullPhone == null) {
      _fail('Enter their WhatsApp number, for example 801 234 5678.');
      return;
    }
    _go(_fromReview ? _Step.review : _Step.hours);
  }

  void _hoursSave() {
    if (_setHours && _minutes(_end) <= _minutes(_start)) {
      _fail('The end time must be after the start time.');
      return;
    }
    _go(_Step.review);
  }

  int _minutes(String t) =>
      int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));

  Future<void> _submit() async {
    setState(() => _busy = true);
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
      setState(() => _busy = false);
      if (mounted) _fail(extractMessage(e));
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
      await ref
          .read(myCoveApiProvider)
          .removeDomesticStaff(widget.existing!['id'] as String);
      ref.invalidate(domesticStaffProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _fail(extractMessage(e));
    }
  }

  // ── Shared pieces ──────────────────────────────────────────────────────

  static const _pad = 20.0;

  TextStyle get _title => McTextStyles.heading(fontSize: 19);
  TextStyle get _subtitle =>
      McTextStyles.body(fontSize: 13, color: McColors.bodyText, height: 1.5);
  TextStyle get _value => McTextStyles.inputValue(fontSize: 14);

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: McTextStyles.body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: McColors.text,
      ),
    ),
  );

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(McRadii.button),
    borderSide: BorderSide(color: McColors.neutralN(300)),
  );

  /// Bordered, white fields (the theme's default is a borderless grey fill).
  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    counterText: '',
    fillColor: McColors.surface,
    enabledBorder: _border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  BoxDecoration get _boxField => BoxDecoration(
    color: McColors.surface,
    borderRadius: BorderRadius.circular(McRadii.button),
    border: Border.all(color: McColors.neutralN(300)),
  );

  /// White card with the app's soft shadow.
  Widget _card({
    required Widget child,
    EdgeInsets? padding,
    double bottom = 16,
  }) => Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: bottom),
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: McColors.surface,
      borderRadius: BorderRadius.circular(McRadii.card),
      boxShadow: McColors.cardShadow,
    ),
    child: child,
  );

  /// Header, scrolling content, and the action buttons pinned at the bottom.
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
            padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 24),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _title),
      const SizedBox(height: 6),
      Text(subtitle, style: _subtitle),
      const SizedBox(height: 24),
    ],
  );

  // ── Pages ──────────────────────────────────────────────────────────────

  Widget _basics() {
    final anyDay = _days.isEmpty;
    return _page(
      title: _editing ? 'Edit domestic staff' : 'Add domestic staff',
      children: [
        _sectionTitle(
          'Basic details',
          "Provide the staff member's name and WhatsApp number.",
        ),
        _label('Name'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: _value,
          decoration: _decoration('e.g. Mary Johnson'),
        ),
        const SizedBox(height: 24),
        _label('WhatsApp number'),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: _boxField,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      width: 26,
                      height: 18,
                      child: Row(
                        children: const [
                          Expanded(
                            child: ColoredBox(
                              color: Color(0xFF008751),
                              child: SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: ColoredBox(
                              color: Colors.white,
                              child: SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: ColoredBox(
                              color: Color(0xFF008751),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('+234', style: _value),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 22,
                    color: McColors.bodyText,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _editing
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: _boxField,
                      child: Text(
                        (widget.existing!['phone'] as String).replaceFirst(
                          '+234',
                          '',
                        ),
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
        const SizedBox(height: 10),
        Text(
          'Use the number they will message MyCove with.',
          style: McTextStyles.body(
            fontSize: 12,
            color: McColors.bodyText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _sectionTitle(
          'When can they come?',
          'Select the days they normally visit.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 0; d < 7; d++)
              Semantics(
                label: _dayNames[d],
                child: GestureDetector(
                  onTap: () => setState(
                    () => _days.contains(d) ? _days.remove(d) : _days.add(d),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(McRadii.button),
                      color: _days.contains(d)
                          ? McColors.accent2
                          : McColors.surface,
                      border: _days.contains(d)
                          ? null
                          : Border.all(color: McColors.neutralN(300)),
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
        const SizedBox(height: 20),
        McButton(
          label: 'Allow any day',
          variant: ChButtonVariant.outlined,
          selected: anyDay,
          verticalPadding: 15,
          leading: Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: anyDay ? McColors.accent2 : McColors.text,
          ),
          onPressed: () => setState(_days.clear),
        ),
        const SizedBox(height: 8),
      ],
      actions: [
        McButton(
          verticalPadding: 15,
          label: _fromReview ? 'Done' : 'Next',
          onPressed: _basicsNext,
        ),
      ],
    );
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    var picked = DateTime(
      2000,
      1,
      1,
      int.parse(current.substring(0, 2)),
      int.parse(current.substring(3, 5)),
    );
    final confirmed = await showMcSheet<bool>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                start ? 'From what time?' : 'Until what time?',
                style: McTextStyles.heading(fontSize: 17),
              ),
              SizedBox(
                height: 190,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: McTextStyles.body(
                        fontSize: 19,
                        color: McColors.text,
                      ),
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
              McButton(
                verticalPadding: 15,
                label: 'Done',
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = value : _end = value);
  }

  /// A time box: small label, then a clock icon and the time, with a chevron.
  Widget _timeTile(String label, String value, bool start) => GestureDetector(
    onTap: () => _pickTime(start),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: McColors.inputFill,
        borderRadius: BorderRadius.circular(McRadii.button),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: McTextStyles.body(
                    fontSize: 11,
                    color: McColors.bodyText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 22,
                      color: McColors.bodyText,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeLabelPadded(value),
                      style: McTextStyles.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: McColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 26,
            color: McColors.bodyText,
          ),
        ],
      ),
    ),
  );

  Widget _switchRow(
    DomesticIcon icon,
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DomesticGlyph(icon, size: 24, color: McColors.text),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: McTextStyles.heading(fontSize: 15)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: McColors.bodyText,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: McColors.accent2,
      ),
    ],
  );

  Widget _hours() {
    return _page(
      title: _editing ? 'Edit domestic staff' : 'Add domestic staff',
      children: [
        _sectionTitle(
          'Access hours',
          'Limit access to specific hours (optional).',
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _switchRow(
                DomesticIcon.hours,
                'Set access hours',
                null,
                _setHours,
                (v) => setState(() => _setHours = v),
              ),
              if (_setHours) ...[
                _timeTile('From', _start, true),
                _timeTile('Until', _end, false),
                const SizedBox(height: 14),
                Text(
                  'They can ask for a code from 15 minutes before the start time until the end time.',
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: McColors.bodyText,
                    height: 1.5,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'Off: they can ask for a code at any time on their days.',
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: McColors.bodyText,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        _card(
          child: _switchRow(
            DomesticIcon.approval,
            'Approve each request',
            'You will get a notification and must approve before they receive a code.',
            _approval,
            (v) => setState(() => _approval = v),
          ),
        ),
      ],
      actions: [
        McButton(verticalPadding: 15, label: 'Save', onPressed: _hoursSave),
      ],
    );
  }

  Widget _reviewRow(
    DomesticIcon icon,
    String title,
    String value, {
    VoidCallback? onEdit,
    bool last = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: last
        ? null
        : const BoxDecoration(
            border: Border(bottom: BorderSide(color: McColors.divider)),
          ),
    child: Row(
      children: [
        DomesticIconCircle(icon),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: McTextStyles.heading(fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                value,
                style: McTextStyles.body(
                  fontSize: 13,
                  color: McColors.bodyText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null) McTextButton(label: 'Edit', onPressed: onEdit),
      ],
    ),
  );

  Widget _review() {
    final days = _days.toList()..sort();
    return _page(
      title: 'Review details',
      children: [
        _card(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _reviewRow(
                DomesticIcon.person,
                _name.text.trim(),
                _fullPhone ?? '',
                onEdit: () => _editFromReview(_Step.basics),
              ),
              _reviewRow(
                DomesticIcon.days,
                'Access days',
                daysLabel(days),
                onEdit: () => _editFromReview(_Step.basics),
              ),
              _reviewRow(
                DomesticIcon.hours,
                'Access hours',
                hoursLabel(_startTime, _endTime),
                onEdit: () => _editFromReview(_Step.hours),
              ),
              _reviewRow(
                DomesticIcon.approval,
                'Approval',
                _approval
                    ? 'Require approval for each request'
                    : 'No approval needed',
                onEdit: () => _editFromReview(_Step.hours),
                last: true,
              ),
            ],
          ),
        ),
      ],
      actions: [
        McButton(
          verticalPadding: 15,
          label: _editing ? 'Save changes' : 'Add domestic staff',
          onPressed: _busy ? null : _submit,
          isLoading: _busy,
        ),
        const SizedBox(height: 12),
        if (_editing) ...[
          McButton(
            verticalPadding: 15,
            label: 'Entry & exit log',
            variant: ChButtonVariant.outlined,
            leading: const Icon(
              Icons.login_rounded,
              size: 20,
              color: McColors.text,
            ),
            onPressed: () => context.push(
              '/resident/domestic-staff/log',
              extra: {
                'id': widget.existing!['id'],
                'name': widget.existing!['name'],
              },
            ),
          ),
          const SizedBox(height: 12),
          McButton(
            verticalPadding: 15,
            label: 'Remove domestic staff',
            variant: ChButtonVariant.danger,
            onPressed: _remove,
          ),
          const SizedBox(height: 12),
        ],
        McButton(
          verticalPadding: 15,
          label: 'Cancel',
          variant: ChButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// The "Domestic staff added" page: tick in a soft ring, a summary card, Done at the bottom.
  Widget _success() {
    final days = _days.toList()..sort();
    Widget row(DomesticIcon icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          DomesticGlyph(icon, size: 26, color: McColors.accent2),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: McColors.bodyText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: McTextStyles.heading(fontSize: 14)),
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
            padding: const EdgeInsets.fromLTRB(_pad, 56, _pad, 24),
            children: [
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: McColors.accent2N(100).withValues(alpha: 0.6),
                    border: Border.all(color: McColors.accent2N(100), width: 2),
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: McColors.accent2,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Domestic staff added',
                textAlign: TextAlign.center,
                style: McTextStyles.heading(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                '${_name.text.trim()} can now request gate access through WhatsApp.',
                textAlign: TextAlign.center,
                style: McTextStyles.body(
                  fontSize: 14,
                  color: McColors.bodyText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: McColors.surface,
                  borderRadius: BorderRadius.circular(McRadii.card),
                  boxShadow: McColors.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      color: McColors.accent2N(100),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_note_outlined,
                            size: 22,
                            color: McColors.accent2,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Access summary',
                            style: McTextStyles.heading(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        children: [
                          row(
                            DomesticIcon.whatsapp,
                            'WhatsApp number',
                            _fullPhone ?? '',
                          ),
                          row(DomesticIcon.days, 'Days', daysLabel(days)),
                          row(
                            DomesticIcon.hours,
                            'Hours',
                            hoursLabel(_startTime, _endTime),
                          ),
                          row(
                            DomesticIcon.approval,
                            'Approval',
                            _approval ? 'Required' : 'Not required',
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
          padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 20),
          child: McButton(
            verticalPadding: 15,
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
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
      canPop:
          _step == _Step.success ||
          (_step == _Step.basics && !_fromReview) ||
          (_step == _Step.review && (_editing || _fromReview)),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: McColors.bg,
        body: SafeArea(child: body),
      ),
    );
  }
}
