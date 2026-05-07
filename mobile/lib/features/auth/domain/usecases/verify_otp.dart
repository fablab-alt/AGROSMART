import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp implements UseCase<User, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  @override
  Future<Either<Failure, User>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(params.telephone, params.code);
  }
}

class VerifyOtpParams extends Equatable {
  final String telephone;
  final String code;

  const VerifyOtpParams({required this.telephone, required this.code});

  @override
  List<Object> get props => [telephone, code];
}
