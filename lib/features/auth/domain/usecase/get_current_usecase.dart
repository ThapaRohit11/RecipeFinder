import 'package:recipe_finder/core/error/failures.dart';
import 'package:recipe_finder/core/usecase/app_usecase.dart';
import 'package:recipe_finder/features/auth/data/repositories/auth_repository.dart';
import 'package:recipe_finder/features/auth/domain/entities/auth_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repositories.dart';

// Create Provider
final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return GetCurrentUserUsecase(authRepository: authRepository);
});

class GetCurrentUserUsecase implements UsecaseWithoutParms<AuthEntity> {
  final IAuthRepository _authRepository;

  GetCurrentUserUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Either<Failure, AuthEntity>> call() {
    return _authRepository.getCurrentUser();
  }
}