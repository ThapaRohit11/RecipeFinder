import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences instance provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// UserSessionService provider
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserSessionService(prefs: prefs);
});

class UserSessionService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for storing user data
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyUsername = 'username';
  static const String _keyProfilePicture = 'profile_picture';
  static const String _keyToken = 'auth_token';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  // Save user session after login
  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
    required String profilePicture,
    required String username,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserFullName, fullName);
    await _prefs.setString(_keyUsername, username);
    await _prefs.setString(_keyProfilePicture, profilePicture);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _prefs.getString(_keyUserId);
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  // Get current user full name
  String? getCurrentUserFullName() {
    return _prefs.getString(_keyUserFullName);
  }

  String? getCurrentUsername() {
    return _prefs.getString(_keyUsername);
  }

  String? getCurrentUserProfilePicture() {
    return _prefs.getString(_keyProfilePicture);
  }


  // Save token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricEnabled, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _keyBiometricEmail, value: email);
    await _secureStorage.write(key: _keyBiometricPassword, value: password);
  }

  Future<BiometricCredentials?> getBiometricCredentials() async {
    final email = await _secureStorage.read(key: _keyBiometricEmail);
    final password = await _secureStorage.read(key: _keyBiometricPassword);

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }

    return BiometricCredentials(email: email, password: password);
  }

  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _keyBiometricEmail);
    await _secureStorage.delete(key: _keyBiometricPassword);
  }


  // Clear user session (logout)
  Future<void> clearSession() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserFullName);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyProfilePicture);
    await _secureStorage.delete(key: _keyToken);
  }

  void debugPrintUserData() {}
}

class BiometricCredentials {
  final String email;
  final String password;

  const BiometricCredentials({
    required this.email,
    required this.password,
  });
}