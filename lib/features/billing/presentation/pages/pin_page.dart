import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/service/pin_service.dart';
import '../../../../core/theme/app_theme.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isSetupMode = false;
  bool _isConfirmStep = false;
  String _statusMessage = '';
  bool _hasError = false;
  bool _isLocked = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _isSetupMode = !PinService.isPinSet();
    _statusMessage = _isSetupMode ? 'Create a 4-digit PIN' : 'Enter your PIN';
  }

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
          _statusMessage = 'Enter your PIN';
        });
      } else {
        setState(() => _statusMessage = 'Too many attempts. Wait ${remaining}s');
      }
    });
  }

  void _onKeyTap(String digit) {
    if (_isLocked || PinService.isLocked()) return;
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _processPin);
    }
  }

  void _onDelete() {
    if (_isLocked || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _processPin() async {
    if (_isSetupMode) {
      if (!_isConfirmStep) {
        // Step 1: store first entry and ask to confirm
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirmStep = true;
          _statusMessage = 'Confirm your PIN';
        });
      } else {
        // Step 2: confirm match
        if (_enteredPin == _confirmPin) {
          await PinService.setPin(_enteredPin);
          PinService.authenticate();
          if (mounted) context.go('/home');
        } else {
          setState(() {
            _enteredPin = '';
            _confirmPin = '';
            _isConfirmStep = false;
            _hasError = true;
            _statusMessage = 'PINs did not match. Try again.';
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              _hasError = false;
              _statusMessage = 'Create a 4-digit PIN';
            });
          }
        }
      }
    } else {
      // Login mode
      if (PinService.verifyPin(_enteredPin)) {
        PinService.authenticate();
        if (mounted) context.go('/home');
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = 'Wrong PIN. Try again.';
          _enteredPin = '';
        });
        if (PinService.isLocked()) {
          _startLockCountdown();
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && !_isLocked) {
          setState(() {
            _hasError = false;
            _statusMessage = 'Enter your PIN';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    size: 40, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                _isSetupMode
                    ? (_isConfirmStep ? 'Confirm PIN' : 'Setup PIN')
                    : 'Welcome Back',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasError ? Colors.red : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? Colors.red
                          : filled
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              // Keypad
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
          _keypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _keypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _keypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _keyButton('0'),
              _deleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_keyButton).toList(),
    );
  }

  Widget _keyButton(String digit) {
    return GestureDetector(
      onTap: () => _onKeyTap(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _deleteButton() {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined,
            color: Colors.grey, size: 24),
      ),
    );
  }
}
