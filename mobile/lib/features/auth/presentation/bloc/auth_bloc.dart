import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/usecases/usecase.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Événement pour vérifier l'état d'authentification au démarrage
class CheckAuthStatus extends AuthEvent {}

/// Événement de déconnexion
class LogoutRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;
  LoginRequested(this.identifier, this.password);
  @override
  List<Object> get props => [identifier, password];
}

class VerifyOtpRequested extends AuthEvent {
  final String identifier;
  final String code;
  VerifyOtpRequested(this.identifier, this.code);
  @override
  List<Object> get props => [identifier, code];
}

class RegisterRequested extends AuthEvent {
  final String nom;
  final String prenoms;
  final String telephone;
  final String password;
  final String? email;
  final String? adresse;
  final String languePreferee;
  final String role; // 'ACHETEUR' ou 'PRODUCTEUR'
  final String? typeProducteur;
  final String? production3Mois;
  final String? superficie;
  final String? uniteSuperficie;
  final String? systemeIrrigation;
  final String? productionMois1;
  final String? productionMois2;
  final String? productionMois3;
  final List<Map<String, dynamic>>? productions;

  RegisterRequested({
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.password,
    this.email,
    this.adresse,
    this.languePreferee = 'fr',
    this.role = 'PRODUCTEUR', // Par défaut pour compatibilité
    this.typeProducteur,
    this.production3Mois,
    this.superficie,
    this.uniteSuperficie,
    this.systemeIrrigation,
    this.productionMois1,
    this.productionMois2,
    this.productionMois3,
    this.productions,
  });

  @override
  List<Object?> get props => [
    nom,
    prenoms,
    telephone,
    password,
    email,
    adresse,
    languePreferee,
    role,
    typeProducteur,
    production3Mois,
    superficie,
    uniteSuperficie,
    systemeIrrigation,
    productionMois1,
    productionMois2,
    productionMois3,
    productions,
  ];
}

class UpdateProfileRequested extends AuthEvent {
  final String nom;
  final String prenoms;
  final String telephone;
  final String? email;
  final String? typeProducteur;
  final String? region;
  final File? photo;
  final double? superficieExploitee;
  final String? uniteSuperficie;
  final String? systemeIrrigation;
  final double? productionMois1;
  final double? productionMois2;
  final double? productionMois3;

  UpdateProfileRequested({
    required this.nom,
    required this.prenoms,
    required this.telephone,
    this.email,
    this.typeProducteur,
    this.region,
    this.photo,
    this.superficieExploitee,
    this.uniteSuperficie,
    this.systemeIrrigation,
    this.productionMois1,
    this.productionMois2,
    this.productionMois3,
  });

  @override
  List<Object?> get props => [
    nom,
    prenoms,
    telephone,
    email,
    typeProducteur,
    region,
    photo,
    superficieExploitee,
    uniteSuperficie,
    systemeIrrigation,
    productionMois1,
    productionMois2,
    productionMois3,
  ];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// État après déconnexion - utilisateur non authentifié mais peut accéder au marketplace
class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  @override
  List<Object> get props => [user];
}

class AuthRegistered extends AuthState {
  final User user;
  final bool requiresOtp;
  AuthRegistered(this.user, {this.requiresOtp = false});
  @override
  List<Object> get props => [user, requiresOtp];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login login;
  final VerifyOtp verifyOtp;
  final Register register;
  final UpdateProfile updateProfile;
  final Logout logout;
  final AuthRepository authRepository;

  AuthBloc({
    required this.login,
    required this.verifyOtp,
    required this.register,
    required this.updateProfile,
    required this.logout,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  /// Handler pour vérifier l'état d'authentification au démarrage
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[AUTH] 🔍 Vérification de l\'état d\'authentification...');
    emit(AuthLoading());

    final result = await authRepository.getCurrentUser();
    result.fold(
      (failure) {
        debugPrint('[AUTH] ❌ Pas de session valide: ${failure.message}');
        emit(AuthUnauthenticated());
      },
      (user) {
        if (user != null) {
          debugPrint('[AUTH] ✅ Session restaurée: ${user.nom} ${user.prenoms}');
          emit(AuthAuthenticated(user));
        } else {
          debugPrint('[AUTH] ⚠️ Pas de token stocké');
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  /// Handler pour la déconnexion
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logout(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await login(
      LoginParams(identifier: event.identifier, password: event.password),
    );
    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      debugPrint(
        '[AUTH] 🎉 Login successful! User: ${user.email}, Role: ${user.role}',
      );
      emit(AuthAuthenticated(user));
    });
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await verifyOtp(
      VerifyOtpParams(telephone: event.identifier, code: event.code),
    );
    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      debugPrint(
        '[AUTH] 🎉 OTP verified! User: ${user.email}, Role: ${user.role}',
      );
      emit(AuthAuthenticated(user));
    });
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await register(
      RegisterParams(
        nom: event.nom,
        prenoms: event.prenoms,
        telephone: event.telephone,
        password: event.password,
        email: event.email,
        adresse: event.adresse,
        languePreferee: event.languePreferee,
        role: event.role,
        typeProducteur: event.typeProducteur,
        production3Mois: event.production3Mois,
        superficie: event.superficie,
        uniteSuperficie: event.uniteSuperficie,
        systemeIrrigation: event.systemeIrrigation,
        productionMois1: event.productionMois1,
        productionMois2: event.productionMois2,
        productionMois3: event.productionMois3,
        productions: event.productions,
      ),
    );
    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      // Émettre AuthAuthenticated pour que l'utilisateur soit connecté automatiquement
      debugPrint(
        '[AUTH] 🎉 Registration successful! User: ${user.email}, Role: ${user.role}',
      );
      emit(AuthAuthenticated(user));
    });
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await updateProfile(
      nom: event.nom,
      prenoms: event.prenoms,
      telephone: event.telephone,
      email: event.email,
      typeProducteur: event.typeProducteur,
      region: event.region,
      photo: event.photo,
      superficieExploitee: event.superficieExploitee,
      uniteSuperficie: event.uniteSuperficie,
      systemeIrrigation: event.systemeIrrigation,
      productionMois1: event.productionMois1,
      productionMois2: event.productionMois2,
      productionMois3: event.productionMois3,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
