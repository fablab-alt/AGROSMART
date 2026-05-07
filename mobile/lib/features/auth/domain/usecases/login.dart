import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Login implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  Login(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(params.identifier, params.password);
  }
}

class LoginParams extends Equatable {
  final String identifier;
  final String password;

  const LoginParams({required this.identifier, required this.password});

  @override
  List<Object> get props => [identifier, password];
}

