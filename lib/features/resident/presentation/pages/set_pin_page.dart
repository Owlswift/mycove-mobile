import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_pin_boxes.dart';
import '../../../../state/app_notifier.dart';

const _pinLength = 4;

enum _Step { verifyCurrent, enterNew, confirmNew }

class SetPinPage extends ConsumerStatefulWidget {
  const SetPinPage({super.key});

  @override
  ConsumerState<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends ConsumerState<SetPinPage> {
  late _Step _step;
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hasPin = ref.read(appStateProvider).currentUser?.hasPin ?? false;
    _step = hasPin ? _Step.verifyCurrent : _Step.enterNew;
  }

  Future<void> _submitCurrentPin() async {
    if (_currentPin.length != _pinLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await ref.read(appStateProvider.notifier).verifyTransactionPin(_currentPin);
    if (!mounted) return;
    if (valid) {
      setState(() {
        _busy = false;
        _step = _Step.enterNew;
      });
    } else {
      setState(() {
        _busy = false;
        _currentPin = '';
        _error = 'Incorrect PIN. Please try again.';
      });
    }
  }

  void _submitNewPin() {
    if (_newPin.length != _pinLength) return;
    setState(() {
      _step = _Step.confirmNew;
      _error = null;
    });
  }

  Future<void> _submitConfirmPin() async {
    if (_confirmPin.length != _pinLength || _busy) return;
    if (_confirmPin != _newPin) {
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
    final ok = await ref.read(appStateProvider.notifier).setTransactionPin(_newPin);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      setState(() {
        _busy = false;
        _error = "Couldn't set your PIN. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChGenericHeader(title: 'Transaction PIN', centerTitle: true, onBack: () => context.pop()),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_outlined, size: context.rs(40), color: ChColors.accent2),
                SizedBox(height: context.rs(12)),
                Text(_title, style: ChTextStyles.heading(fontSize: 18), textAlign: TextAlign.center),
                SizedBox(height: context.rs(6)),
                Text(
                  _subtitle,
                  style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.rs(28)),
                if (_step == _Step.verifyCurrent)
                  ChPinBoxes(
                    length: _pinLength,
                    value: _currentPin,
                    obscureText: true,
                    onChanged: (v) {
                      setState(() => _currentPin = v);
                      if (v.length == _pinLength) _submitCurrentPin();
                    },
                  ),
                if (_step == _Step.enterNew)
                  ChPinBoxes(
                    length: _pinLength,
                    value: _newPin,
                    obscureText: true,
                    onChanged: (v) {
                      setState(() => _newPin = v);
                      if (v.length == _pinLength) _submitNewPin();
                    },
                  ),
                if (_step == _Step.confirmNew)
                  ChPinBoxes(
                    length: _pinLength,
                    value: _confirmPin,
                    obscureText: true,
                    onChanged: (v) {
                      setState(() => _confirmPin = v);
                      if (v.length == _pinLength) _submitConfirmPin();
                    },
                  ),
                if (_error != null) ...[
                  SizedBox(height: context.rs(14)),
                  Text(_error!, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger), textAlign: TextAlign.center),
                ],
                if (_busy) ...[
                  SizedBox(height: context.rs(20)),
                  const CircularProgressIndicator(strokeWidth: 2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _title => switch (_step) {
    _Step.verifyCurrent => 'Enter your current PIN',
    _Step.enterNew => 'Enter a new 4-digit PIN',
    _Step.confirmNew => 'Confirm your new PIN',
  };

  String get _subtitle => switch (_step) {
    _Step.verifyCurrent => 'Verify your current PIN before setting a new one.',
    _Step.enterNew => 'You\'ll use this to authorize purchases made by voice or in the app.',
    _Step.confirmNew => 'Enter it once more to confirm.',
  };
}
