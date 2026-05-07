/// Barrel export pour la feature Auth
///
/// Ce fichier exporte tous les composants publics de la feature auth
/// pour faciliter les imports.
///
/// Usage:
/// ```dart
/// import 'package:agriculture/features/auth/auth.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/user.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';

// Domain - Usecases
export 'domain/usecases/login.dart';
export 'domain/usecases/register.dart';
export 'domain/usecases/verify_otp.dart';
export 'domain/usecases/logout.dart';

// Data - Repositories
export 'data/repositories/auth_repository_impl.dart';

// Data - Datasources
export 'data/datasources/auth_remote_datasource.dart';

// Presentation - Bloc
export 'presentation/bloc/auth_bloc.dart';

// Presentation - Pages
export 'presentation/pages/login_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/pages/otp_page.dart';
export 'presentation/pages/onboarding_page.dart';
