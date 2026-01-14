import 'package:recipe_finder/core/error/failures.dart';
import 'package:recipe_finder/core/usecase/app_usecase.dart';
import 'package:recipe_finder/features/auth/data/repositories/auth_repository.dart';
import 'package:recipe_finder/features/auth/domain/repositories/auth_repositories.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef LogoutUsecase = UsecaseWithoutParms<bool>;

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return LogoutUsecaseImpl(authRepository: authRepository);
});

class LogoutUsecaseImpl implements UsecaseWithoutParms<bool> {
  final IAuthRepository _authRepository;
  LogoutUsecaseImpl({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call() {
    return _authRepository.logout();
  }
}