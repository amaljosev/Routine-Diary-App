import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
 final PageController _pageController = PageController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _pin = '';
  String _confirmPin = '';
  String _error = '';
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    _pageController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Handle digit input with haptic feedback
  void _onDigitPressed(String digit, bool isConfirmPage) {
    HapticFeedback.lightImpact(); 

    setState(() {
      // clear any visible error as soon as user starts typing anywhere
      if (_error.isNotEmpty) {
        _error = '';
        _errorTimer?.cancel();
      }

      if (isConfirmPage) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          _confirmController.text = _confirmPin;
        }
      } else {
        if (_pin.length < 4) {
          _pin += digit;
          _pinController.text = _pin;
        }
      }
    });

    // Auto-advance to confirm page when PIN is fully entered
    if (!isConfirmPage && _pin.length == 4) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    // Auto-validate when confirm page has 4 digits (small delay to let UI show last dot)
    if (isConfirmPage && _confirmPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _onConfirm();
      });
    }
  }

  // Handle backspace with haptic feedback
  void _onBackspacePressed(bool isConfirmPage) {
    HapticFeedback.lightImpact(); // haptic on backspace

    setState(() {
      if (_error.isNotEmpty) {
        _error = '';
        _errorTimer?.cancel();
      }

      if (isConfirmPage) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _confirmController.text = _confirmPin;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
          _pinController.text = _pin;
        }
      }
    });
  }

  // Validate and complete setup
  void _onConfirm() {
    // If confirm not filled yet, ignore (guard)
    if (_confirmPin.length < 4) return;

    if (_pin == _confirmPin && _pin.length == 4) {
      // PINs match – proceed (e.g., save PIN, pop with success)
      Navigator.pop(context, _pin);
    } else {
      // Mismatch: short haptic, show error text, clear pins and go back to create page
      HapticFeedback.vibrate(); // short vibration
      HapticFeedback.lightImpact();

      setState(() {
        _error = 'PINs do not match';
        // clear both fields so UX is obvious
        _confirmPin = '';
        _confirmController.text = '';
      });

      // bring user back to the create page and show error message briefly
      // if (_pageController.hasClients) {
      //   _pageController.animateToPage(
      //     0,
      //     duration: const Duration(milliseconds: 350),
      //     curve: Curves.easeInOut,
      //   );
      // }

      // Auto-hide error after 2 seconds
      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _error = '';
        });
      });
    }
  }

  bool _isConfirmPage() {
    if (!_pageController.hasClients) return false;
    final page = _pageController.page ?? _pageController.initialPage.toDouble();
    return page.round() == 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set your PIN'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView with two pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // disable swipe to force using keypad
                children: [
                  _PinPage(
                    title: 'Create PIN',
                    subtitle: 'Enter a 4-digit PIN',
                    controller: _pinController,
                    obscurePin: _pin,
                    primaryColor: primaryColor,
                    errorMessage: '', // no inline error for create page
                  ),
                  _PinPage(
                    title: 'Confirm PIN',
                    subtitle: 'Re-enter your PIN',
                    error: _error.isNotEmpty,
                    controller: _confirmController,
                    obscurePin: _confirmPin,
                    primaryColor: primaryColor,
                    errorMessage: _error,
                  ),
                ],
              ),
            ),
            // Custom numeric keypad
            _NumericKeypad(
              onDigitPressed: (digit) {
                final isConfirm = _isConfirmPage();
                _onDigitPressed(digit, isConfirm);
              },
              onBackspacePressed: () {
                final isConfirm = _isConfirmPage();
                _onBackspacePressed(isConfirm);
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 20),
            // Submit button – enabled once user has entered 4 digits in confirm page.
            // This allows pressing the button to get feedback for mismatch.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: (_confirmPin.length == 4) ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// A single page for PIN entry/confirmation
class _PinPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool error;
  final TextEditingController controller;
  final String obscurePin;
  final Color primaryColor;
  final String errorMessage;

  const _PinPage({
    required this.title,
    required this.subtitle,
    this.error = false,
    required this.controller,
    required this.obscurePin,
    required this.primaryColor,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: error ? Colors.red : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          // Display 4 masked digits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final bool hasDigit = index < obscurePin.length;
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasDigit ? primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: hasDigit
                      ? Icon(Icons.circle, size: 20, color: primaryColor)
                      : const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Inline short error message (fades in/out)
          AnimatedOpacity(
            opacity: errorMessage.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom numeric keypad
class _NumericKeypad extends StatelessWidget {
  final void Function(String) onDigitPressed;
  final VoidCallback onBackspacePressed;
  final Color primaryColor;

  const _NumericKeypad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int j = 1; j <= 3; j++)
                  _KeypadButton(
                    label: '${i * 3 + j}',
                    onPressed: () => onDigitPressed('${i * 3 + j}'),
                    primaryColor: primaryColor,
                  ),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _KeypadButton(
                label: '',
                onPressed: () {}, // empty placeholder
                disabled: true,
                primaryColor: primaryColor,
              ),
              _KeypadButton(
                label: '0',
                onPressed: () => onDigitPressed('0'),
                primaryColor: primaryColor,
              ),
              _KeypadButton(
                label: '⌫',
                onPressed: onBackspacePressed,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// A single keypad button
class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool disabled;
  final Color primaryColor;

  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.disabled = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: disabled ? Colors.transparent : primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  color: disabled ? Colors.grey : primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}