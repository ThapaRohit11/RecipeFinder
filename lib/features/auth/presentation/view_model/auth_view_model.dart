import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:recipe_finder/features/auth/domain/usecase/login_usecase.dart';
import 'package:recipe_finder/features/auth/domain/usecase/register_usecase.dart';
import 'package:recipe_finder/features/auth/presentation/state/auth_state.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final loginUsecase = ref.read(loginUsecaseProvider);
  final registerUsecase = ref.read(registerUsecaseProvider);
  return AuthViewModel(
    loginUsecase: loginUsecase,
    registerUsecase: registerUsecase,
  );
});

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  static const Duration _authTimeout = Duration(seconds: 15);

  AuthViewModel({
    required LoginUsecase loginUsecase,
    required RegisterUsecase registerUsecase,
  })  : _loginUsecase = loginUsecase,
        _registerUsecase = registerUsecase,
        super(const AuthState());

  // Login method
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final params = LoginParams(email: email, password: password);
      final result = await _loginUsecase.call(params).timeout(_authTimeout);

      result.fold(
        (failure) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        },
        (authEntity) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            authEntity: authEntity,
          );
        },
      );
    } on TimeoutException {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Request timeout. Please check backend/server connection.',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Register method
  Future<void> register({
    required String fullName,
    required String email,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final params = RegisterUsecaseParams(
        fullName: fullName,
        email: email,
        username: username,
        password: password,
      );

      final result = await _registerUsecase.call(params).timeout(_authTimeout);

      result.fold(
        (failure) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        },
        (success) {
          if (success) {
            state = state.copyWith(status: AuthStatus.registered);
          } else {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'Registration failed',
            );
          }
        },
      );
    } on TimeoutException {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Request timeout. Please check backend/server connection.',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Reset error state
  void resetError() {
    state = state.copyWith(
      status: AuthStatus.initial,
      errorMessage: null,
    );
  }

  // Logout
  void logout() {
    state = const AuthState();
  }
}