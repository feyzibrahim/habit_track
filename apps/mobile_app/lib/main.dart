import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/core/theme/app_theme.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/features/onboarding/onboarding_page.dart';
import 'package:ezecute/routes/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistence and load token
  await ApiService.init();

  if (ApiService.isAuthenticated) {
    await AppDataStore().refreshData();
  } else {
    try {
      await ApiService.loginGuest();
    } catch (e) {
      debugPrint("Failed to initialize guest mode: $e");
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E2229),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HabitBuilderApp());
}

class HabitBuilderApp extends StatelessWidget {
  const HabitBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        Widget initialScreen;
        if (ApiService.isAuthenticated) {
          final store = AppDataStore();
          if (store.activeGoal != null) {
            initialScreen = const AppShell();
          } else {
            initialScreen = const OnboardingPage();
          }
        } else {
          initialScreen = const OnboardingPage();
        }

        return MaterialApp(
          title: 'Mission Control',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: initialScreen,
        );
      },
    );
  }
}
