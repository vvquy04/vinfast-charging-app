import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Splash screen with animated EVCPoint logo and pulsing loading dots.
///
/// Automatically navigates to [/walkthrough] after 3 seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _dotsController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // Transparent status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Logo entrance animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Dots loop animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _logoController.forward();

    // Auto-navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/walkthrough');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const Spacer(flex: 4),

          // ─── Logo ────────────────────────────────
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.white,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App name
                  const Text(
                    'EVCPoint',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 4),

          // ─── Loading Dots ────────────────────────
          _buildLoadingDots(),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase =
                (_dotsController.value * 2 * math.pi) + (i * math.pi * 0.6);
            final opacity = (math.sin(phase) + 1) / 2; // range 0..1
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.15 + 0.85 * opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
