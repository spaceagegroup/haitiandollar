import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:haitiandollar/services/pin_auth_service.dart';
import 'package:haitiandollar/theme/htd_theme.dart';
import 'package:haitiandollar/utils/app_strings.dart';

/// Modal bottom sheet presenting a 4-digit numeric keypad with oversized touch targets.
///
/// Designed for physical market conditions:
/// - 72×72pt button hit targets for one-handed outdoor usage.
/// - Tactile haptics on every tap.
/// - Biometric fingerprint shortcut that clears typed digits and works even during PIN lockout.
/// - High-contrast Sun Mode / Night Mode palettes.
class PinKeypadSheet extends StatefulWidget {
  const PinKeypadSheet({
    super.key,
    required this.authService,
    required this.locale,
    required this.onAuthenticated,
    this.isSettingNewPin = false,
    this.titleOverride,
  });

  final PinAuthService authService;
  final String locale;
  final ValueChanged<bool> onAuthenticated; // passes isDuress
  final bool isSettingNewPin;
  final String? titleOverride;

  static Future<bool?> show(
    BuildContext context, {
    required PinAuthService authService,
    required String locale,
    bool isSettingNewPin = false,
    String? titleOverride,
    ValueChanged<bool>? onDuressDetected,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinKeypadSheet(
        authService: authService,
        locale: locale,
        isSettingNewPin: isSettingNewPin,
        titleOverride: titleOverride,
        onAuthenticated: (isDuress) {
          if (isDuress) {
            onDuressDetected?.call(true);
          }
          Navigator.of(ctx).pop(true);
        },
      ),
    );
  }

  @override
  State<PinKeypadSheet> createState() => _PinKeypadSheetState();
}

class _PinKeypadSheetState extends State<PinKeypadSheet> {
  String _enteredPin = '';
  String? _firstPin; // for two-step confirmation during setup
  String? _errorMessage;
  bool _isVerifying = false;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    if (widget.authService.isLockedOut) {
      _startLockoutCountdown();
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.authService.isLockedOut) {
        timer.cancel();
        if (mounted) setState(() => _errorMessage = null);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                '${AppStrings.get('pin_locked', widget.locale)} ${widget.authService.lockoutSecondsRemaining}s';
          });
        }
      }
    });
  }

  void _onDigit(String digit) {
    if (_isVerifying) return;
    if (widget.authService.isLockedOut && !widget.isSettingNewPin) return;
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _processCompletePin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isVerifying) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _onBiometric() async {
    // Clear partial entered PIN so user is not confused
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });

    final ok = await widget.authService.authenticateWithBiometrics();
    if (ok && mounted) {
      widget.onAuthenticated(false);
    }
  }

  Future<void> _processCompletePin() async {
    setState(() => _isVerifying = true);

    if (widget.isSettingNewPin) {
      if (_firstPin == null) {
        // Step 1 of setup: check weak PIN
        if (PinAuthService.isWeakPin(_enteredPin)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorMessage = AppStrings.get('pin_weak', widget.locale);
            _enteredPin = '';
            _isVerifying = false;
          });
          return;
        }
        // Advance to step 2: confirmation
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isVerifying = false;
        });
      } else {
        // Step 2 of setup: verify confirmation matches
        if (_enteredPin != _firstPin) {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorMessage = AppStrings.get('pin_mismatch', widget.locale);
            _enteredPin = '';
            _firstPin = null;
            _isVerifying = false;
          });
          return;
        }

        final res = await widget.authService.setPin(_enteredPin);
        if (res == AuthResult.success && mounted) {
          widget.onAuthenticated(false);
        } else if (mounted) {
          setState(() {
            _errorMessage = AppStrings.get('pin_weak', widget.locale);
            _enteredPin = '';
            _firstPin = null;
            _isVerifying = false;
          });
        }
      }
      return;
    }

    // Normal Outflow Verification
    final result = await widget.authService.verifyPin(_enteredPin);
    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        widget.onAuthenticated(false);
        break;
      case AuthResult.successDuress:
        widget.onAuthenticated(true);
        break;
      case AuthResult.lockedOut:
        HapticFeedback.heavyImpact();
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
        });
        _startLockoutCountdown();
        break;
      case AuthResult.incorrectPin:
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = AppStrings.get('pin_incorrect', widget.locale);
          _enteredPin = '';
          _isVerifying = false;
        });
        break;
      default:
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;
    final bg = isSun ? kSunCardSurface : const Color(0xFF141414);
    final border = isSun ? kSunBorder : const Color(0xFF2A2A2A);
    final textPrimary = isSun ? kSunHeaderText : Colors.white;
    final textSecondary = isSun ? kSunSecondaryText : Colors.white60;

    String title;
    if (widget.titleOverride != null) {
      title = widget.titleOverride!;
    } else if (widget.isSettingNewPin) {
      title = _firstPin == null
          ? AppStrings.get('pin_create_title', widget.locale)
          : AppStrings.get('pin_confirm_title', widget.locale);
    } else {
      title = AppStrings.get('pin_title', widget.locale);
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border, width: isSun ? 1.5 : 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isSun ? kSunSecondaryText.withValues(alpha: 0.3) : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 18),

            // 4-Dot Masked Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (isSun ? kSunHeaderText : const Color(0xFFFCC419))
                        : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? (isSun ? kSunHeaderText : const Color(0xFFFCC419))
                          : (isSun ? kSunBorder : Colors.white38),
                      width: 2.0,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Error or lockout message banner
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE03131),
                  ),
                ),
              )
            else
              const SizedBox(height: 16),

            const SizedBox(height: 12),

            // Numeric Keypad Grid (3x4)
            _buildKeypadRow(['1', '2', '3'], isSun),
            const SizedBox(height: 12),
            _buildKeypadRow(['4', '5', '6'], isSun),
            const SizedBox(height: 12),
            _buildKeypadRow(['7', '8', '9'], isSun),
            const SizedBox(height: 12),
            _buildBottomKeypadRow(isSun),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isSun) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberKey(d, isSun)).toList(),
    );
  }

  Widget _buildBottomKeypadRow(bool isSun) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric Button (Available even if PIN is locked out)
        if (widget.authService.biometricsAvailable && !widget.isSettingNewPin)
          _buildSpecialKey(
            icon: Icons.fingerprint,
            onTap: _onBiometric,
            isSun: isSun,
            tooltip: 'Biometric',
          )
        else
          const SizedBox(width: 72, height: 72),

        // Zero
        _buildNumberKey('0', isSun),

        // Backspace
        _buildSpecialKey(
          icon: Icons.backspace_outlined,
          onTap: _onBackspace,
          isSun: isSun,
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildNumberKey(String digit, bool isSun) {
    return Material(
      color: isSun ? kSunCardSurface : const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.12),
          width: isSun ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onDigit(digit),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isSun ? kSunHeaderText : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required IconData icon,
    required VoidCallback onTap,
    required bool isSun,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: isSun ? kSunHeaderText : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
