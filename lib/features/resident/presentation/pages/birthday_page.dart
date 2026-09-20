import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_sheet.dart';
import '../../../../core/widgets/mc_text_button.dart';
import '../../../../core/widgets/mc_toast.dart';
import '../../../../data/models/birthday.dart';
import '../../../../state/detail_providers.dart';

/// The week-before-your-birthday prompt: add a photo, say whether there'll
/// be a party. Submitting puts the resident on the estate spotlight with an
/// automatic message, and — if there's a party — tells everyone when and where.
class BirthdayCelebrationPage extends ConsumerStatefulWidget {
  const BirthdayCelebrationPage({super.key, required this.birthday});

  final MyBirthday birthday;

  @override
  ConsumerState<BirthdayCelebrationPage> createState() => _BirthdayCelebrationPageState();
}

class _BirthdayCelebrationPageState extends ConsumerState<BirthdayCelebrationPage> {
  final _venue = TextEditingController();
  String? _photoDataUrl;
  Uint8List? _photoBytes;
  bool? _hasParty;
  DateTime? _partyAt;
  bool _busy = false;

  @override
  void dispose() {
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1350,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (_) {
      if (mounted) showMcToast(context, 'Could not open your photos. Check that MyCove is allowed to use them.');
    }
  }

  void _choosePhotoSource() {
    showMcSheet<void>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: context.rs(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              McSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              McSheetOption(
                icon: Icons.photo_camera_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPartyTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _partyAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Party date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_partyAt ?? DateTime(now.year, now.month, now.day, 16)),
      helpText: 'Party start time',
    );
    if (time == null) return;
    setState(() => _partyAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  /// The estate is in Lagos (UTC+1, no daylight saving), whatever the phone's clock says.
  String _lagosIso(DateTime local) =>
      '${local.year}-${_two(local.month)}-${_two(local.day)}T${_two(local.hour)}:${_two(local.minute)}:00+01:00';

  String _partyLabel(DateTime at) {
    final h = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final suffix = at.hour < 12 ? 'AM' : 'PM';
    return '${at.day} ${MyBirthday.monthNames[at.month - 1]}, $h:${_two(at.minute)} $suffix';
  }

  bool get _canSubmit =>
      _hasParty != null &&
      (_hasParty == false || (_partyAt != null && _venue.text.trim().isNotEmpty)) &&
      !_busy;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(myCoveApiProvider).respondToBirthday(
            photoBase64: _photoDataUrl,
            hasParty: _hasParty!,
            partyAt: _hasParty! ? _lagosIso(_partyAt!) : null,
            partyVenue: _hasParty! ? _venue.text.trim() : null,
          );
      ref.invalidate(myBirthdayProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      setState(() => _busy = false);
      if (mounted) showMcToast(context, 'Something went wrong. Please try again.');
    }
  }

  /// Yes / No — the same pill chip the complaint categories use.
  Widget _choice(String label, bool value) {
    final selected = _hasParty == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _hasParty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? McColors.accent2 : McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.pill),
            border: selected ? null : Border.all(color: McColors.divider),
          ),
          child: Text(
            label,
            style: McTextStyles.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : McColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text, style: McTextStyles.body(fontSize: 12, color: McColors.text.withValues(alpha: 0.7))),
      );

  @override
  Widget build(BuildContext context) {
    final b = widget.birthday;
    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            McGenericHeader(title: 'Your birthday', centerTitle: true, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text('Your birthday is ${b.label}, ${b.whenLabel}! 🎂', style: McTextStyles.heading(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    "Add a photo and we'll put you on the estate spotlight with a birthday message.",
                    style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _choosePhotoSource,
                      child: Container(
                        width: context.rs(112),
                        height: context.rs(112),
                        decoration: BoxDecoration(
                          color: McColors.surfaceSunken,
                          shape: BoxShape.circle,
                          image: _photoBytes == null
                              ? null
                              : DecorationImage(image: MemoryImage(_photoBytes!), fit: BoxFit.cover),
                        ),
                        child: _photoBytes == null
                            ? Icon(Icons.add_a_photo_outlined, size: context.rs(30), color: McColors.bodyText)
                            : null,
                      ),
                    ),
                  ),
                  Center(
                    child: McTextButton(
                      onPressed: _choosePhotoSource,
                      label: _photoBytes == null ? 'Add a photo' : 'Change photo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Will you be having a party?'),
                  Row(children: [_choice('Yes', true), _choice('No', false)]),
                  if (_hasParty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Everyone in the estate will be told when and where.',
                      style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                    ),
                    const SizedBox(height: 14),
                    _label('When?'),
                    McButton(
                      variant: ChButtonVariant.secondary,
                      label: _partyAt == null ? 'Choose date and time' : _partyLabel(_partyAt!),
                      onPressed: _pickPartyTime,
                    ),
                    const SizedBox(height: 14),
                    _label('Where?'),
                    TextField(
                      controller: _venue,
                      maxLength: 120,
                      onChanged: (_) => setState(() {}),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      style: McTextStyles.inputValue(),
                      decoration: InputDecoration(
                        hintText: 'e.g. Block C clubhouse',
                        counterText: '',
                        fillColor: McColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(McRadii.button),
                          borderSide: BorderSide(color: McColors.neutralN(300)),
                        ),
                      ),
                    ),
                  ],
                  if (_hasParty == false) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No problem. On the day, everyone will get a message so they can wish you a happy birthday.',
                      style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                    ),
                  ],
                  const SizedBox(height: 20),
                  McButton(
                    label: 'Add me to the spotlight',
                    onPressed: _canSubmit ? _submit : null,
                    isLoading: _busy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for day and month (no year) in a sheet that slides up from the
/// bottom, and saves it. Returns true when saved.
Future<bool> showBirthdayPickerDialog(
  BuildContext context,
  WidgetRef ref, {
  int? month,
  int? day,
}) async {
  final picked = await showMcSheet<(int, int)>(
    context,
    builder: (_) => _BirthdaySheet(initialMonth: month ?? 1, initialDay: day ?? 1),
  );
  if (picked == null) return false;
  try {
    await ref.read(myCoveApiProvider).setMyBirthday(month: picked.$1, day: picked.$2);
    ref.invalidate(myBirthdayProvider);
    return true;
  } catch (_) {
    return false;
  }
}

class _BirthdaySheet extends StatefulWidget {
  const _BirthdaySheet({required this.initialMonth, required this.initialDay});

  final int initialMonth;
  final int initialDay;

  @override
  State<_BirthdaySheet> createState() => _BirthdaySheetState();
}

class _BirthdaySheetState extends State<_BirthdaySheet> {
  static const _daysIn = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  late int _month = widget.initialMonth;
  late int _day = widget.initialDay;
  late final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: widget.initialDay - 1);

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxDay = _daysIn[_month - 1];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.rs(24), 0, context.rs(24), context.rs(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When is your birthday?', style: McTextStyles.heading(fontSize: 18)),
            SizedBox(height: context.rs(4)),
            Text(
              'Day and month only. Your neighbours will celebrate with you.',
              style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
            ),
            SizedBox(
              height: context.rs(150),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: widget.initialMonth - 1),
                      onSelectedItemChanged: (i) => setState(() {
                        _month = i + 1;
                        final limit = _daysIn[_month - 1];
                        if (_day > limit) {
                          _day = limit;
                          _dayController.jumpToItem(limit - 1);
                        }
                      }),
                      children: [
                        for (final name in MyBirthday.monthNames)
                          Center(child: Text(name, style: McTextStyles.body(fontSize: 18, color: McColors.text))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      key: ValueKey(maxDay),
                      itemExtent: 40,
                      scrollController: _dayController,
                      onSelectedItemChanged: (i) => _day = i + 1,
                      children: [
                        for (var d = 1; d <= maxDay; d++)
                          Center(child: Text('$d', style: McTextStyles.body(fontSize: 18, color: McColors.text))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(8)),
            McButton(label: 'Save birthday', onPressed: () => Navigator.of(context).pop((_month, _day))),
          ],
        ),
      ),
    );
  }
}

/// Dashboard strip: asks for a birthday if there isn't one, and in the week
/// before it nudges (and once per launch opens) the photo + party prompt.
class BirthdayDashboardCards extends ConsumerStatefulWidget {
  const BirthdayDashboardCards({super.key});

  @override
  ConsumerState<BirthdayDashboardCards> createState() => _BirthdayDashboardCardsState();
}

class _BirthdayDashboardCardsState extends ConsumerState<BirthdayDashboardCards> {
  static bool _autoOpened = false;
  static bool _askDismissed = false;

  Future<void> _openPrompt(MyBirthday b) async {
    await Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => BirthdayCelebrationPage(birthday: b)));
  }

  Widget _card({required String text, required String action, required VoidCallback onTap, VoidCallback? onDismiss}) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(16)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: McColors.accent2N(100),
        borderRadius: BorderRadius.circular(McRadii.card),
      ),
      child: Row(
        children: [
          const Text('🎂', style: TextStyle(fontSize: 24)),
          SizedBox(width: context.rs(12)),
          Expanded(child: Text(text, style: McTextStyles.body(fontSize: 12.5, color: McColors.text))),
          McTextButton(onPressed: onTap, label: action),
          if (onDismiss != null)
            IconButton(visualDensity: VisualDensity.compact, onPressed: onDismiss, icon: const Icon(Icons.close, size: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(myBirthdayProvider).asData?.value;
    if (b == null) return const SizedBox.shrink();

    if (b.needsResponse) {
      if (!_autoOpened) {
        _autoOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openPrompt(b);
        });
      }
      return _card(
        text: 'Your birthday is ${b.whenLabel}. Add a photo and tell the estate about your party.',
        action: 'Open',
        onTap: () => _openPrompt(b),
      );
    }
    if (!b.hasBirthday && !_askDismissed) {
      return _card(
        text: 'Add your birthday so the estate can celebrate with you.',
        action: 'Add',
        onTap: () => showBirthdayPickerDialog(context, ref),
        onDismiss: () => setState(() => _askDismissed = true),
      );
    }
    return const SizedBox.shrink();
  }
}
