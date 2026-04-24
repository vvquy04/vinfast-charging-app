import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/utils/dio_client.dart';
import 'data/services/auth_service.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/walkthrough_screen.dart';
import 'presentation/screens/auth/login_options_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/phone_input_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/screens/auth/complete_profile_screen.dart';
import 'presentation/screens/auth/add_vehicle_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final dioClient = DioClient();
            final authService = AuthService(dioClient);
            final authRepository = AuthRepository(authService);
            return AuthProvider(authRepository);
          },
        ),
      ],
      child: const EVCPointApp(),
    ),
  );
}

class EVCPointApp extends StatelessWidget {
  const EVCPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVCPoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: const ColorScheme.light(
          primary: AppColors.black,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.black,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        splashColor: AppColors.silver.withOpacity(0.3),
        highlightColor: AppColors.silver.withOpacity(0.1),
      ),

      // ─── Routes ──────────────────────────────────
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/walkthrough': (context) => const WalkthroughScreen(),
        '/login-options': (context) => const LoginOptionsScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup/phone': (context) => const PhoneInputScreen(),
        '/signup/otp': (context) => const OtpVerificationScreen(),
        '/signup/profile': (context) => const CompleteProfileScreen(),
        '/signup/vehicle': (context) => const AddVehicleScreen(),
        // TODO: Add home screen route
        '/home': (context) => const _PlaceholderHome(),
      },
    );
  }
}

/// Temporary placeholder home screen.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'EVCPoint',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome! Home screen coming soon.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
