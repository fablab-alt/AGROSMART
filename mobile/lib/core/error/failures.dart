import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de cache']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Erreur réseau']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erreur d\'authentification']);
}
