import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_finder/app/theme/theme_mode_provider.dart';
import 'package:recipe_finder/features/splash/presentation/pages/splash_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
// Screen imports removed because navigation is done directly inside screens (no named routes)

// onboarding and home imports are intentionally omitted to avoid unused-import warnings

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  static const double _shakeThreshold = 2.2;
  static const Duration _toggleCooldown = Duration(milliseconds: 1200);

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  DateTime _lastToggleAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    _accelerometerSub = userAccelerometerEventStream().listen((event) {
      final isSensorEnabled = ref.read(shakeThemeSensorProvider);
      if (!isSensorEnabled) {
        return;
      }

      final acceleration = sqrt((event.x * event.x) + (event.y * event.y) + (event.z * event.z));
      if (acceleration < _shakeThreshold) {
        return;
      }
      unawaited(_toggleThemeFromShake());
    });
  }

  Future<void> _toggleThemeFromShake() async {
    final now = DateTime.now();
    if (now.difference(_lastToggleAt) < _toggleCooldown) {
      return;
    }
    _lastToggleAt = now;

    await ref.read(themeModeProvider.notifier).toggle();
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Finder',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22A35A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FBF8),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22A35A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1712),
        cardTheme: CardThemeData(
          color: const Color(0xFF18221C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}