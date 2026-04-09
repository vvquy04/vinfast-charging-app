import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Sign-up step 2 — OTP code verification.
///
/// Receives phone number via route arguments and displays 4-digit OTP input
/// with auto-focus, countdown timer, and resend functionality.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;
  bool _isLoading = false;

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 4;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _resendOtp() {
    if (!_canResend) return;
    // TODO: Call resend OTP API
    _startTimer();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _verify() {
    if (!_isComplete) return;

    setState(() => _isLoading = true);

    // TODO: Call verify OTP API
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Pass phone number to profile screen
        final phone = ModalRoute.of(context)?.settings.arguments as String?;
        Navigator.pushNamed(context, '/signup/profile', arguments: phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        ModalRoute.of(context)?.settings.arguments as String? ?? '+84 ***';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),

              // ─── Back button ────────────────────
              _BackButton(onTap: () => Navigator.pop(context)),

              const SizedBox(height: AppSizes.xl),

              // ─── Header ─────────────────────────
              const Text(
                'OTP code verification 📧',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'We have sent an OTP code to phone number $phone. Enter the OTP code below to continue.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── OTP Inputs ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final bool hasFocus = _focusNodes[i].hasFocus;
                  final bool hasValue = _controllers[i].text.isNotEmpty;
                  return Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPressed(i, event),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        cursorColor: AppColors.black,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: hasValue
                              ? AppColors.smoke
                              : AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            borderSide:
                                const BorderSide(color: AppColors.silver),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            borderSide: BorderSide(
                              color: hasValue
                                  ? AppColors.black
                                  : AppColors.silver,
                              width: hasValue ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            borderSide: const BorderSide(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSizes.xl),

              // ─── Resend ─────────────────────────
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: _resendOtp,
                        child: const Text(
                          "Didn't receive code? Resend",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      )
                    : Text(
                        'You can resend code in ${_countdown}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray,
                        ),
                      ),
              ),

              const Spacer(),

              // ─── Continue button ────────────────
              AppButton(
                text: 'Continue',
                isLoading: _isLoading,
                onPressed: _isComplete ? _verify : null,
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.smoke,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.black,
        ),
      ),
    );
  }
}
