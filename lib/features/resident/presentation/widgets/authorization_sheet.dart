import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../state/app_notifier.dart';

const _pinLength = 4;

/// Gates a purchase behind biometrics and/or a transaction PIN — the single
/// place both voice-driven and tap-driven purchases authorize through (see
/// ResidentShell's `pendingAuthorizationFor` listener), so the security-
/// critical path only needs testing once. Never accepts a spoken PIN.
Future<bool> showAuthorizationSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AuthorizationSheet(),
  );
  return result ?? false;
}

class _AuthorizationSheet extends ConsumerStatefulWidget {
  const _AuthorizationSheet();

  @override
  ConsumerState<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends ConsumerState<_AuthorizationSheet> {
  String _pin = '';
  String _confirmPin = '';
  bool _busy = false;
  String? _error;
  bool _biometricAutoFired = false;

  Future<void> _authenticateBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(appStateProvider.notifier).authenticateForPurchase();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = "Authentication wasn't completed.";
    });
  }

  Future<void> _submitVerifyPin() async {
    if (_pin.length != _pinLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await ref.read(appStateProvider.notifier).verifyTransactionPin(_pin);
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _error = 'Incorrect PIN. Please try again.';
    });
  }

  Future<void> _submitSetPin() async {
    if (_pin.length != _pinLength || _confirmPin.length != _pinLength || _busy) return;
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _error = "PINs don't match. Please try again.";
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(appStateProvider.notifier).setTransactionPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = "Couldn't set your PIN. Please try again.";
    });
  }

  /// Which string the keypad below is currently typing into — the single
  /// PIN field while verifying an existing PIN, or whichever of the two
  /// fields isn't complete yet while setting a new one.
  String _activeDigits({required bool settingUpPin}) {
    if (!settingUpPin) return _pin;
    return _pin.length < _pinLength ? _pin : _confirmPin;
  }

  void _onDigit(String digit, {required bool settingUpPin}) {
    if (_busy) return;
    if (!settingUpPin) {
      if (_pin.length >= _pinLength) return;
      setState(() {
        _error = null;
        _pin += digit;
      });
      if (_pin.length == _pinLength) _submitVerifyPin();
      return;
    }
    if (_pin.length < _pinLength) {
      setState(() {
        _error = null;
        _pin += digit;
      });
      return;
    }
    if (_confirmPin.length >= _pinLength) return;
    setState(() {
      _error = null;
      _confirmPin += digit;
    });
    if (_confirmPin.length == _pinLength) _submitSetPin();
  }

  void _onBackspace({required bool settingUpPin}) {
    if (_busy) return;
    if (!settingUpPin || _confirmPin.isEmpty) {
      if (_pin.isEmpty) return;
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
  }

  void _forgotPin() {
    Navigator.pop(context, false);
    context.push('/resident/profile/pin', extra: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final hasBiometric = s.biometricAvailable && s.biometricEnabled;
    final hasPin = s.currentUser?.hasPin ?? false;
    final settingUpPin = !hasBiometric && !hasPin;

    // Auto-fire biometrics once on open, but PIN entry (below) is shown
    // alongside it from the start rather than hidden behind a "use PIN
    // instead" tap — either path is available immediately.
    if (hasBiometric && !_biometricAutoFired) {
      _biometricAutoFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticateBiometric());
    }

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: McColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
      ),
      // The cream background above fills all the way to the actual bottom
      // of the screen/sheet; only the content inside gets pushed up clear
      // of the home indicator. SafeArea around the Container itself (the
      // previous bug) left the dimmed backdrop visible in that gap instead.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(24), context.rs(24), context.rs(28)),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: McColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: context.rs(18)),
            Container(
              width: context.rs(56),
              height: context.rs(56),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(
                hasBiometric ? Icons.fingerprint : Icons.lock_outline_rounded,
                size: context.rs(28),
                color: McColors.accent2,
              ),
            ),
            SizedBox(height: context.rs(14)),
            Text(
              _title(hasPin: hasPin, settingUpPin: settingUpPin),
              style: McTextStyles.heading(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.rs(4)),
            Text(
              _subtitle(hasBiometric: hasBiometric, hasPin: hasPin, settingUpPin: settingUpPin),
              style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
              textAlign: TextAlign.center,
            ),
            if (hasBiometric) ...[
              SizedBox(height: context.rs(16)),
              McButton(label: 'Try Again', onPressed: _busy ? null : _authenticateBiometric, isLoading: _busy),
            ],
            if (hasPin) ...[
              if (hasBiometric) ...[
                SizedBox(height: context.rs(16)),
                Row(
                  children: [
                    Expanded(child: Divider(color: McColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
                      child: Text(
                        'or enter your PIN',
                        style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                      ),
                    ),
                    Expanded(child: Divider(color: McColors.divider)),
                  ],
                ),
              ],
              SizedBox(height: context.rs(20)),
              _PinDots(length: _pinLength, filled: _pin.length),
              SizedBox(height: context.rs(10)),
              TextButton(
                onPressed: _busy ? null : _forgotPin,
                style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('Forgot PIN?', style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.accent2)),
              ),
            ],
            if (settingUpPin) ...[
              SizedBox(height: context.rs(20)),
              Text(
                _pin.length < _pinLength ? 'Enter PIN' : 'Confirm PIN',
                style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
              ),
              SizedBox(height: context.rs(10)),
              _PinDots(length: _pinLength, filled: _activeDigits(settingUpPin: true).length),
            ],
            if (_error != null) ...[
              SizedBox(height: context.rs(14)),
              Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger), textAlign: TextAlign.center),
            ],
            if (hasPin || settingUpPin) ...[
              SizedBox(height: context.rs(18)),
              _Keypad(
                busy: _busy,
                onDigit: (d) => _onDigit(d, settingUpPin: settingUpPin),
                onBackspace: () => _onBackspace(settingUpPin: settingUpPin),
              ),
            ],
            SizedBox(height: context.rs(16)),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: Text('Cancel', style: McTextStyles.body(fontSize: 14, color: McColors.bodyText)),
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _title({required bool hasPin, required bool settingUpPin}) {
    if (settingUpPin) return 'Set up a transaction PIN';
    if (hasPin) return 'Enter your 4-digit PIN';
    return 'Confirm this purchase';
  }

  String _subtitle({required bool hasBiometric, required bool hasPin, required bool settingUpPin}) {
    if (settingUpPin) return 'Set a 4-digit PIN to authorize this and future purchases.';
    if (hasBiometric && hasPin) return 'Use Face ID or Touch ID, or enter your 4-digit PIN below.';
    if (hasBiometric) return 'Use Face ID or Touch ID to continue.';
    return 'This helps keep your account secure.';
  }
}

/// Static (no TextField/focus) row of 4 boxes — a filled dot once that
/// index is typed, empty otherwise. Driven entirely by [_Keypad] below
/// rather than the system keyboard.
class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: context.rs(10)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: context.rs(50),
            height: context.rs(56),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: McColors.inputFill,
              borderRadius: BorderRadius.circular(McRadii.button),
              border: Border.all(
                color: i == filled ? McColors.accent2 : Colors.transparent,
                width: 2,
              ),
            ),
            child: i < filled
                ? Container(
                    width: context.rs(10),
                    height: context.rs(10),
                    decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
                  )
                : null,
          ),
        ],
      ],
    );
  }
}

/// In-app numeric keypad (no system keyboard) — same key layout as the
/// biometric app-unlock screen's, reused here so a resident never needs to
/// dismiss the sheet's own keyboard affordance to see the "Cancel"/error
/// text below it.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.busy, required this.onDigit, required this.onBackspace});

  final bool busy;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    [('1', ''), ('2', 'ABC'), ('3', 'DEF')],
    [('4', 'GHI'), ('5', 'JKL'), ('6', 'MNO')],
    [('7', 'PQRS'), ('8', 'TUV'), ('9', 'WXYZ')],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (digit, letters) in row)
                _KeypadKey(onTap: busy ? null : () => onDigit(digit), child: _DigitLabel(digit: digit, letters: letters)),
            ],
          ),
          SizedBox(height: context.rs(4)),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: context.rs(64), height: context.rs(64)),
            _KeypadKey(onTap: busy ? null : () => onDigit('0'), child: const _DigitLabel(digit: '0', letters: '')),
            _KeypadKey(
              onTap: busy ? null : onBackspace,
              child: Icon(Icons.backspace_outlined, size: context.rs(20), color: McColors.text),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = context.rs(64);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

class _DigitLabel extends StatelessWidget {
  const _DigitLabel({required this.digit, required this.letters});

  final String digit;
  final String letters;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(digit, style: McTextStyles.heading(fontSize: 24)),
        if (letters.isNotEmpty)
          Text(letters, style: McTextStyles.body(fontSize: 9, fontWeight: FontWeight.w600, color: McColors.bodyText)),
      ],
    );
  }
}
