import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
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
  String? _error;

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
      setState(() => _error = 'Could not open your photos. Check that MyCove is allowed to use them.');
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
          ],
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
    setState(() {
      _busy = true;
      _error = null;
    });
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
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Widget _choice(String label, bool value) {
    final selected = _hasParty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _hasParty = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.rs(14)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? McColors.accent2N(100) : McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.button),
            border: Border.all(color: selected ? McColors.accent2 : McColors.divider),
          ),
          child: Text(
            label,
            style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600, color: McColors.text),
          ),
        ),
      ),
    );
  }

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
                padding: EdgeInsets.symmetric(horizontal: context.rs(24), vertical: context.rs(8)),
                children: [
                  Text(
                    'Your birthday is ${b.label} — ${b.whenLabel}! 🎂',
                    style: McTextStyles.heading(fontSize: 20),
                  ),
                  SizedBox(height: context.rs(6)),
                  Text(
                    'Add a photo and we\'ll put you on the estate spotlight with a birthday message.',
                    style: McTextStyles.body(fontSize: 14, color: McColors.text),
                  ),
                  SizedBox(height: context.rs(20)),
                  Center(
                    child: GestureDetector(
                      onTap: _choosePhotoSource,
                      child: Container(
                        width: context.rs(140),
                        height: context.rs(140),
                        decoration: BoxDecoration(
                          color: McColors.surfaceSunken,
                          shape: BoxShape.circle,
                          image: _photoBytes == null
                              ? null
                              : DecorationImage(image: MemoryImage(_photoBytes!), fit: BoxFit.cover),
                        ),
                        child: _photoBytes == null
                            ? Icon(Icons.add_a_photo_outlined, size: context.rs(36), color: McColors.text)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(8)),
                  Center(
                    child: TextButton(
                      onPressed: _choosePhotoSource,
                      child: Text(_photoBytes == null ? 'Add a photo' : 'Change photo'),
                    ),
                  ),
                  SizedBox(height: context.rs(16)),
                  Text('Will you be having a party?', style: McTextStyles.heading(fontSize: 16)),
                  SizedBox(height: context.rs(10)),
                  Row(
                    children: [
                      _choice('Yes', true),
                      SizedBox(width: context.rs(12)),
                      _choice('No', false),
                    ],
                  ),
                  if (_hasParty == true) ...[
                    SizedBox(height: context.rs(16)),
                    Text(
                      'Everyone in the estate will be told when and where.',
                      style: McTextStyles.body(fontSize: 13, color: McColors.text),
                    ),
                    SizedBox(height: context.rs(10)),
                    OutlinedButton.icon(
                      onPressed: _pickPartyTime,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(_partyAt == null ? 'Choose date and time' : _partyLabel(_partyAt!)),
                    ),
                    SizedBox(height: context.rs(12)),
                    TextField(
                      controller: _venue,
                      maxLength: 120,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Where?',
                        hintText: 'e.g. Block C clubhouse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_hasParty == false) ...[
                    SizedBox(height: context.rs(12)),
                    Text(
                      'No problem — on the day, everyone will get a message so they can wish you a happy birthday.',
                      style: McTextStyles.body(fontSize: 13, color: McColors.text),
                    ),
                  ],
                  if (_error != null) ...[
                    SizedBox(height: context.rs(12)),
                    Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  ],
                  SizedBox(height: context.rs(24)),
                  McButton(
                    label: 'Add me to the spotlight',
                    onPressed: _canSubmit ? _submit : null,
                    isLoading: _busy,
                  ),
                  SizedBox(height: context.rs(24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for day and month (no year) and saves it. Returns true when saved.
Future<bool> showBirthdayPickerDialog(
  BuildContext context,
  WidgetRef ref, {
  int? month,
  int? day,
}) async {
  var m = month ?? 1;
  var d = day ?? 1;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) {
        // Days in the chosen month; 29 Feb is allowed.
        final maxDay = const [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1];
        if (d > maxDay) d = maxDay;
        return AlertDialog(
          title: const Text('When is your birthday?'),
          content: Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: m,
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text(MyBirthday.monthNames[i - 1])),
                  ],
                  onChanged: (v) => setLocal(() => m = v ?? m),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: d,
                  items: [for (var i = 1; i <= maxDay; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) => setLocal(() => d = v ?? d),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        );
      },
    ),
  );
  if (saved != true) return false;
  try {
    await ref.read(myCoveApiProvider).setMyBirthday(month: m, day: d);
    ref.invalidate(myBirthdayProvider);
    return true;
  } catch (_) {
    return false;
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
          const Text('🎂', style: TextStyle(fontSize: 26)),
          SizedBox(width: context.rs(12)),
          Expanded(child: Text(text, style: McTextStyles.body(fontSize: 13.5, color: McColors.text))),
          TextButton(onPressed: onTap, child: Text(action)),
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
