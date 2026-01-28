import 'package:recipe_finder/features/auth/data/models/auth_api_model.dart';
import 'package:recipe_finder/features/auth/data/models/auth_hive_model.dart';

abstract interface class IAuthDatasource{
  Future<bool> register(AuthHiveModel model);
  Future<AuthHiveModel?> login(String email, String password);
  Future<AuthHiveModel?> getCurrentUser();
  Future<bool> logout();

  //get email exists
  Future<bool> isEmailExists(String email);
}

abstract interface class IAuthRemoteDataSource {
  Future<AuthApiModel> register(AuthApiModel user);
  Future<AuthApiModel?> login(String email, String password);
  Future<AuthApiModel?> getUserById(String authId);
}