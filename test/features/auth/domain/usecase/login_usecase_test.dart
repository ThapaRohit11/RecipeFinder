import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:recipe_finder/features/auth/domain/entities/auth_entity.dart';
import 'package:recipe_finder/features/auth/domain/repositories/auth_repositories.dart';
import 'package:recipe_finder/features/auth/domain/usecase/login_usecase.dart';
import 'package:recipe_finder/core/error/failures.dart';

// Mock repository
class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late LoginUsecase loginUsecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUsecase = LoginUsecase(authRepository: mockAuthRepository);
  });

  group('LoginUsecase Tests', () {
    /// Test 1: Successful login with valid credentials
    test('Test 1: Should return AuthEntity when login is successful', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final authEntity = const AuthEntity(
        authId: '1',
        email: email,
        fullName: 'Test User',
        username: 'testuser',
      );

      when(() => mockAuthRepository.login(email, password))
          .thenAnswer((_) async => Right(authEntity));

      // Act
      final result = await loginUsecase(
        LoginParams(email: email, password: password),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (auth) {
          expect(auth.email, email);
          expect(auth.fullName, 'Test User');
        },
      );
      verify(() => mockAuthRepository.login(email, password)).called(1);
    });

    /// Test 2: Login failure with invalid credentials
    test('Test 2: Should return Failure when login credentials are invalid',
        () async {
      // Arrange
      const email = 'invalid@example.com';
      const password = 'wrongpassword';

      when(() => mockAuthRepository.login(email, password)).thenAnswer(
        (_) async => Left(LocalDatabaseFailure(message: 'Invalid credentials')),
      );

      // Act
      final result = await loginUsecase(
        LoginParams(email: email, password: password),
      );

      // Assert
      expect(result.isLeft(), true);
      verify(() => mockAuthRepository.login(email, password)).called(1);
    });
  });
}
