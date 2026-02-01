import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:recipe_finder/features/auth/domain/entities/auth_entity.dart';
import 'package:recipe_finder/features/auth/domain/repositories/auth_repositories.dart';
import 'package:recipe_finder/features/auth/domain/usecase/register_usecase.dart';
import 'package:recipe_finder/core/error/failures.dart';

// Mock repository
class MockAuthRepository extends Mock implements IAuthRepository {}

// Fake AuthEntity
class FakeAuthEntity extends Fake implements AuthEntity {}

void main() {
  late RegisterUsecase registerUsecase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeAuthEntity());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerUsecase = RegisterUsecase(authRepository: mockAuthRepository);
  });

  group('RegisterUsecase Tests', () {
    /// Test 1: Successful registration with valid data
    test('Test 1: Should return true when registration is successful',
        () async {
      // Arrange
      const fullName = 'John Doe';
      const email = 'john@example.com';
      const username = 'johndoe';
      const password = 'password123';
      
      final authEntity = AuthEntity(
        fullName: fullName,
        email: email,
        username: username,
        password: password,
      );

      when(() => mockAuthRepository.register(any()))
          .thenAnswer((_) async => const Right(true));

      // Act
      final result = await registerUsecase(
        const RegisterUsecaseParams(
          fullName: fullName,
          email: email,
          username: username,
          password: password,
        ),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (success) {
          expect(success, true);
        },
      );
      verify(() => mockAuthRepository.register(any())).called(1);
    });

    /// Test 2: Registration failure with invalid data
    test('Test 2: Should return Failure when registration data is invalid',
        () async {
      // Arrange
      const params = RegisterUsecaseParams(
        fullName: '',
        email: 'invalid-email',
        username: 'user',
        password: 'pass',
      );

      when(() => mockAuthRepository.register(any())).thenAnswer(
        (_) async => Left(LocalDatabaseFailure(message: 'Invalid registration data')),
      );

      // Act
      final result = await registerUsecase(params);

      // Assert
      expect(result.isLeft(), true);
      verify(() => mockAuthRepository.register(any())).called(1);
    });
  });
}
