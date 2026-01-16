import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:recipe_finder/app/app.dart';
import 'package:recipe_finder/core/constants/hive_table_constants.dart';
import 'package:recipe_finder/core/services/storage/user_session_service.dart';
import 'package:recipe_finder/features/auth/data/models/auth_hive_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(HiveTableConstants.authTypeId)) {
    Hive.registerAdapter(AuthHiveModelAdapter());
  }

  // Open boxes
  await Hive.openBox<AuthHiveModel>(HiveTableConstants.authTable);

  runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
        child: App(),
      ),
    );
}
