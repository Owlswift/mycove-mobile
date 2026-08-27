import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_brand_mark.dart';
import '../../../../state/app_notifier.dart';

const _pinLength = 4;

/// Shown whenever a session is being restored silently (cold start, or
/// resuming from the background) while both biometric unlock AND a
/// transaction PIN are set — see AppNotifier._enterApp/refreshOnResume,
/// which only route here when both are true, so the keypad below always
/// has a PIN to check against. Logging in with a password is never routed
/// through here, since typing the password already was the authentication
/// event.
class BiometricUnlockPage extends ConsumerStatefulWidget {
  const BiometricUnlockPage({super.key});

  @override
  ConsumerState<BiometricUnlockPage> createState() =>
      _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends ConsumerState<BiometricUnlockPage> {
  bool _authenticating = false;
  String _pin = '';
  bool _pinBusy = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    await ref.read(appStateProvider.notifier).unlockWithBiometrics();
    if (mounted) setState(() => _authenticating = false);
  }

  void _onDigit(String digit) {
    if (_pinBusy || _pin.length >= _pinLength) return;
    setState(() {
      _pinError = null;
      _pin += digit;
    });
    if (_pin.length == _pinLength) _submitPin();
  }

  void _onBackspace() {
    if (_pinBusy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submitPin() async {
    if (_pin.length != _pinLength || _pinBusy) return;
    setState(() {
      _pinBusy = true;
      _pinError = null;
    });
    final ok = await ref.read(appStateProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    if (ok) return;
    setState(() {
      _pinBusy = false;
      _pin = '';
      _pinError = 'Incorrect PIN. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: _PinKeypadBody(
          pin: _pin,
          pinLength: _pinLength,
          error: _pinError,
          busy: _pinBusy,
          biometricBusy: _authenticating,
          onDigit: _onDigit,
          onBackspace: _onBackspace,
          onBiometric: _unlock,
          onLogout: () => ref.read(appStateProvider.notifier).logout(),
        ),
      ),
    );
  }
}

class _PinKeypadBody extends StatelessWidget {
  const _PinKeypadBody({
    required this.pin,
    required this.pinLength,
    required this.error,
    required this.busy,
    required this.biometricBusy,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
    required this.onLogout,
  });

  final String pin;
  final int pinLength;
  final String? error;
  final bool busy;
  final bool biometricBusy;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;
  final VoidCallback onLogout;

  static const _rows = [
    [('1', ''), ('2', 'ABC'), ('3', 'DEF')],
    [('4', 'GHI'), ('5', 'JKL'), ('6', 'MNO')],
    [('7', 'PQRS'), ('8', 'TUV'), ('9', 'WXYZ')],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const McBrandMark(size: 52),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: McTextStyles.heading(fontSize: 26),
              children: [
                const TextSpan(text: 'My'),
                TextSpan(text: 'Cove', style: McTextStyles.heading(fontSize: 26, color: McColors.accent2)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Welcome back', style: McTextStyles.heading(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            'Enter your PIN or use biometrics to continue',
            textAlign: TextAlign.center,
            style: McTextStyles.body(fontSize: 14, color: McColors.bodyText),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pinLength; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                _PinDot(filled: i < pin.length),
              ],
            ],
          ),
          SizedBox(
            height: 28,
            child: error != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error!,
                      style: McTextStyles.body(fontSize: 13, color: McColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          for (final row in _rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (digit, letters) in row)
                  _KeypadKey(
                    onTap: busy ? null : () => onDigit(digit),
                    child: _DigitLabel(digit: digit, letters: letters),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _KeypadKey(
                onTap: busy ? null : onBiometric,
                background: McColors.accent2N(100),
                child: biometricBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: McColors.accent2),
                      )
                    : Icon(Icons.fingerprint, size: context.rs(28), color: McColors.accent2),
              ),
              _KeypadKey(
                onTap: busy ? null : () => onDigit('0'),
                child: const _DigitLabel(digit: '0', letters: ''),
              ),
              _KeypadKey(
                onTap: busy ? null : onBackspace,
                child: Icon(Icons.backspace_outlined, size: context.rs(22), color: McColors.text),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onLogout,
            child: Text(
              'Log Out',
              style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: McColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: context.rs(14),
      height: context.rs(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? McColors.accent2 : Colors.transparent,
        border: Border.all(color: filled ? McColors.accent2 : McColors.neutralN(300), width: 1.5),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.onTap, required this.child, this.background});

  final VoidCallback? onTap;
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final size = context.rs(72);
    return Material(
      color: background ?? Colors.transparent,
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
        Text(digit, style: McTextStyles.heading(fontSize: 26)),
        if (letters.isNotEmpty)
          Text(
            letters,
            style: McTextStyles.body(fontSize: 10, fontWeight: FontWeight.w600, color: McColors.bodyText),
          ),
      ],
    );
  }
}

