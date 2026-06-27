import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/service/pin_service.dart';
import '../../../../core/theme/app_theme.dart';

enum _ChangePinStep { enterCurrent, enterNew, confirmNew }

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  _ChangePinStep _step = _ChangePinStep.enterCurrent;
  String _enteredPin = '';
  String _newPin = '';
  bool _hasError = false;
  String _statusMessage = 'Enter your current PIN';
  bool _isLocked = false;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockCountdown() {
    _isLocked = true;
    final rem = PinService.lockRemainingSeconds();
    setState(() {
      _hasError = true;
      _statusMessage = 'Too many attempts. Wait ${rem}s';
    });
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = PinService.lockRemainingSeconds();
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _isLocked = false;
          _hasError = false;
          _statusMessage = 'Enter your current PIN';
        });
      } else {
        setState(() => _statusMessage = 'Too many attempts. Wait ${remaining}s');
      }
    });
  }

  void _onKeyTap(String digit) {
    if (_isLocked) return;
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });
    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _process);
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _process() async {
    switch (_step) {
      case _ChangePinStep.enterCurrent:
        if (PinService.verifyPin(_enteredPin)) {
          setState(() {
            _step = _ChangePinStep.enterNew;
            _enteredPin = '';
            _statusMessage = 'Enter your new PIN';
          });
        } else {
          if (PinService.isLocked()) {
            _startLockCountdown();
            return;
          }
          await _showError('Wrong current PIN');
        }
        break;
      case _ChangePinStep.enterNew:
        setState(() {
          _newPin = _enteredPin;
          _enteredPin = '';
          _step = _ChangePinStep.confirmNew;
          _statusMessage = 'Confirm your new PIN';
        });
        break;
      case _ChangePinStep.confirmNew:
        if (_enteredPin == _newPin) {
          final pin = _enteredPin;
          _enteredPin = '';
          _newPin = '';
          await PinService.setPin(pin);
          if (mounted) {
            context.pop();
          }
        } else {
          await _showError('PINs do not match. Try again.');
          setState(() {
            _step = _ChangePinStep.enterNew;
            _statusMessage = 'Enter your new PIN';
            _newPin = '';
          });
        }
        break;
    }
  }

  Future<void> _showError(String msg) async {
    setState(() {
      _hasError = true;
      _statusMessage = msg;
      _enteredPin = '';
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _hasError = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Change PIN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset,
                    size: 36, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: TextStyle(
                    fontSize: 16,
                    color: _hasError ? Colors.red : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? Colors.red
                          : i < _enteredPin.length
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 16),
          _row(['4', '5', '6']),
          const SizedBox(height: 16),
          _row(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _key('0'),
              GestureDetector(
                onTap: _onDelete,
                child: _circle(
                    const Icon(Icons.backspace_outlined,
                        color: Colors.grey, size: 22)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_key).toList(),
      );

  Widget _key(String d) => GestureDetector(
        onTap: () => _onKeyTap(d),
        child: _circle(Text(d,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
      );

  Widget _circle(Widget child) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: child,
      );
}
