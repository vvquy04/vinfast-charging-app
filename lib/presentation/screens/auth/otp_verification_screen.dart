import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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

  // SMS auto-detection simulation state
  bool _isWaitingForSms = true;
  String? _displayedOtp;
  Timer? _smsSimulationTimer;

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 4;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _simulateSmsReceiving();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _smsSimulationTimer?.cancel();
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

  void _simulateSmsReceiving() {
    _smsSimulationTimer?.cancel();
    setState(() {
      _isWaitingForSms = true;
      _displayedOtp = null;
      for (final c in _controllers) {
        c.clear();
      }
    });

    // Simulate 2 seconds SMS delay
    _smsSimulationTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final lastOtp = authProvider.lastSentOtp;

      setState(() {
        _isWaitingForSms = false;
        _displayedOtp = lastOtp;
      });

      if (lastOtp != null && lastOtp.length == 4) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = lastOtp[i];
        }
        // Focus the last input box and hide keyboard, or keep focus on first
        _focusNodes[3].requestFocus();
      }
    });
  }

  void _resendOtp() async {
    if (!_canResend) return;
    
    final args = ModalRoute.of(context)?.settings.arguments;
    String? phone;
    if (args is Map<String, dynamic>) {
      phone = args['phoneNumber'] as String?;
    } else if (args is String) {
      phone = args;
    }
    if (phone == null) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(phone);
    
    if (success && mounted) {
      _startTimer();
      _simulateSmsReceiving();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to resend OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  void _verify() async {
    if (!_isComplete) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? phone;
    bool isForgotPassword = false;
    if (args is Map<String, dynamic>) {
      phone = args['phoneNumber'] as String?;
      isForgotPassword = args['isForgotPassword'] == true;
    } else if (args is String) {
      phone = args;
    }
    if (phone == null) return;

    final authProvider = context.read<AuthProvider>();
    final isNewUser = await authProvider.verifyOtp(phone, _otp);

    if (isNewUser != null && mounted) {
      if (isForgotPassword) {
        if (isNewUser) {
          // New user, cannot reset password
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số điện thoại chưa được đăng ký trong hệ thống.'),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          // Existing user, proceed to reset password
          Navigator.pushNamed(context, '/reset-password', arguments: {'phoneNumber': phone});
        }
      } else {
        // Normal registration flow
        if (isNewUser) {
          Navigator.pushNamed(context, '/signup/profile', arguments: phone);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số điện thoại này đã được đăng ký. Vui lòng đăng nhập.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final args = ModalRoute.of(context)?.settings.arguments;
    String phone = '+84 ***';
    if (args is Map<String, dynamic>) {
      phone = args['phoneNumber'] as String? ?? '+84 ***';
    } else if (args is String) {
      phone = args;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.md),

                      // ─── Back button ────────────────────
                      _BackButton(onTap: () => Navigator.pop(context)),

                      const SizedBox(height: AppSizes.xl),

                      // ─── Header ─────────────────────────
                      const Text(
                        'Xác nhận mã OTP 📧',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text.rich(
                        TextSpan(
                          text: 'Chúng tôi đã gửi mã OTP tới số ',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.gray,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: phone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            const TextSpan(
                              text: '.\nNhập mã OTP vào bên dưới để tiếp tục.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.md),

                      // ─── SMS Simulation Status (Below phone number) ───
                      _buildSmsStatusIndicator(),

                      const SizedBox(height: AppSizes.xl),

                      // ─── OTP Inputs ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final bool hasValue = _controllers[i].text.isNotEmpty;
                          return Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
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
                                  fontSize: 22,
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
                                    vertical: AppSizes.sm,
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

                      const SizedBox(height: AppSizes.lg),

                      // ─── Resend ─────────────────────────
                      Center(
                        child: _canResend
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Chưa nhận được mã? ",
                                    style:
                                        TextStyle(fontSize: 14, color: AppColors.gray),
                                  ),
                                  GestureDetector(
                                    onTap: _resendOtp,
                                    child: const Text(
                                      'Gửi lại',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Bạn có thể gửi lại mã sau ${_countdown}s',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray,
                                ),
                              ),
                      ),

                      const Spacer(),

                      // ─── Continue button ────────────────
                      AppButton(
                        text: 'Tiếp tục',
                        isLoading: isLoading,
                        onPressed: _isComplete && !isLoading ? _verify : null,
                      ),

                      const SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildSmsStatusIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<bool>(_isWaitingForSms),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _isWaitingForSms
              ? AppColors.smoke
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isWaitingForSms
                ? AppColors.silver
                : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: _isWaitingForSms
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mã OTP: $_displayedOtp',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
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
