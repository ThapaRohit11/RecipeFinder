import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:recipe_finder/app/app.dart';
import 'package:recipe_finder/core/constants/hive_table_constants.dart';
import 'package:recipe_finder/features/auth/data/models/auth_hive_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(HiveTableConstants.authTypeId)) {
    Hive.registerAdapter(AuthHiveModelAdapter());
  }

  // Open Hive boxes
  await Hive.openBox<AuthHiveModel>(HiveTableConstants.authTable);

  // Start app with Riverpod
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
