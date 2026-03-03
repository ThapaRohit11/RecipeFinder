
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (override with --dart-define=API_BASE_URL=http://<host>:5000)
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) {
      return _baseUrlFromEnv;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.108:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // // ============ Batch Endpoints ============
  // static const String batches = '/batches';
  // static String batchById(String id) => '/batches/$id';

  // // ============ Category Endpoints ============
  // static const String categories = '/categories';
  // static String categoryById(String id) => '/categories/$id';

  // ============ Customer Endpoints ============
  static const String customers = '/api/auth';
  static const String customerLogin = '/api/auth/login';
  static const String customerRegister = '/api/auth/register';
  static const String uploadProfilePicture = '/api/auth';
  static String customerProfileById(String id) => '/api/auth/$id';

  // ============ Recipe Endpoints ============
  static const String recipes = '/api/recipes';
  static const String myRecipes = '/api/recipes/my';
  static String recipeById(String recipeId) => '/api/recipes/$recipeId';

  // ============ Favorite Endpoints ============
  static const String favorites = '/api/favorites';
  static String favoriteByRecipeId(String recipeId) => '/api/favorites/$recipeId';
  static String favoriteStatusByRecipeId(String recipeId) => '/api/favorites/$recipeId/status';
  // static String customerById(String id) => '/customers/$id';
  // // ============ Item Endpoints ============
  // static const String items = '/items';
  // static String itemById(String id) => '/items/$id';
  // static String itemClaim(String id) => '/items/$id/claim';

  // ============ Comment Endpoints ============
  // static const String comments = '/comments';
  // static String commentById(String id) => '/comments/$id';
  // static String commentsByItem(String itemId) => '/comments/item/$itemId';
  // static String commentLike(String id) => '/comments/$id/like';
}

