import 'package:flutter/material.dart';
// Screen imports removed because navigation is done directly inside screens (no named routes)
import 'package:recipe_finder/screens/splash_screen.dart';
// onboarding and home imports are intentionally omitted to avoid unused-import warnings

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}