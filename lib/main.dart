import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/utils/dio_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/station_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/station_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/station_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'data/services/history_service.dart';
import 'data/repositories/history_repository.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/walkthrough_screen.dart';
import 'presentation/screens/auth/login_options_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/phone_input_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/screens/auth/complete_profile_screen.dart';
import 'presentation/screens/auth/add_vehicle_screen.dart';
import 'presentation/screens/home/dashboard_screen.dart';
import 'presentation/screens/station/station_detail_screen.dart';

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
        ChangeNotifierProvider(
          create: (_) {
            final dioClient = DioClient();
            final stationService = StationService(dioClient);
            final stationRepo = StationRepository(stationService);
            return StationProvider(stationRepo);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final dioClient = DioClient();
            final historyService = HistoryService(dioClient);
            final historyRepo = HistoryRepository(historyService);
            return HistoryProvider(historyRepo);
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
        '/home': (context) => const DashboardScreen(),
        '/station_detail': (context) => const StationDetailScreen(),
      },
    );
  }
}
