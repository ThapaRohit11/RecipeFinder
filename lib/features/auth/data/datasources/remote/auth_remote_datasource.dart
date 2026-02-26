import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/core/services/storage/user_session_service.dart';
import 'package:recipe_finder/features/auth/data/datasources/auth_datasource.dart';
import 'package:recipe_finder/features/auth/data/models/auth_api_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Provider
final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> getUserById(String authId) async {
    // Fetch user by ID from backend
    final response = await _apiClient.get("${ApiEndpoints.customers}/$authId");
    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      return AuthApiModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerLogin,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          extra: {'noRetry': true},
          connectTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected login response from server');
      }

      if (body['success'] == true) {
        final token = body['token'] as String?;
        if (token != null) {
          await _saveTokenSafely(token);

          final userData = body['data'] as Map<String, dynamic>?;
          AuthApiModel user;

          if (userData != null) {
            user = AuthApiModel.fromJson(userData);
          } else {
            final decodedToken = JwtDecoder.decode(token);
            final userId = decodedToken['id'] as String? ?? '';
            user = AuthApiModel(
              id: userId,
              fullName: email.split('@').first,
              email: email,
              username: email.split('@').first,
              profilePicture: '',
            );
          }

          await _saveSessionSafely(
            userId: user.id ?? '',
            email: user.email,
            fullName: user.fullName,
            username: user.username,
            profilePicture: user.profilePicture ?? '',
          );

          return user;
        }
      }

      throw Exception((body['message'] ?? 'Login failed').toString());
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(
        serverMessage ??
            e.message ??
            'Network error during login. API host: ${ApiEndpoints.baseUrl}',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.customerRegister,
        data: user.toJson(),
        options: Options(
          extra: {'noRetry': true},
          connectTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected register response from server');
      }

      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final registeredUser = AuthApiModel.fromJson(data);

        await _saveSessionSafely(
          userId: registeredUser.id ?? '',
          email: registeredUser.email,
          fullName: registeredUser.fullName,
          username: registeredUser.username,
          profilePicture: registeredUser.profilePicture ?? '',
        );

        return registeredUser;
      }

      throw Exception((body['message'] ?? 'Registration failed').toString());
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(
        serverMessage ??
            e.message ??
            'Network error during registration. API host: ${ApiEndpoints.baseUrl}',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _saveTokenSafely(String token) async {
    try {
      await _userSessionService
          .saveToken(token)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Token save failed: $e');
    }
  }

  Future<void> _saveSessionSafely({
    required String userId,
    required String email,
    required String fullName,
    required String username,
    required String profilePicture,
  }) async {
    try {
      await _userSessionService
          .saveUserSession(
            userId: userId,
            email: email,
            fullName: fullName,
            username: username,
            profilePicture: profilePicture,
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Session save failed: $e');
    }
  }
}
