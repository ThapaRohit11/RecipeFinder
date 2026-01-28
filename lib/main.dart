import 'package:recipe_finder/core/services/storage/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_finder/app/app.dart';
import 'package:recipe_finder/core/services/hive/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();
  await hiveService.openBoxes(); 

  // shared pref
  final sharedPrefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: App(),
    ),
  );
}