/// Barrel export pour la feature Parcelles
///
/// Usage:
/// ```dart
/// import 'package:agriculture/features/parcelles/parcelles.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/parcelle.dart';

// Domain - Repositories
export 'domain/repositories/parcelle_repository.dart';

// Data - Repositories
export 'data/repositories/parcelle_repository_impl.dart';

// Data - Datasources
export 'data/datasources/parcelle_remote_data_source.dart';

// Presentation - Bloc
export 'presentation/bloc/parcelle_bloc.dart';

// Presentation - Pages
export 'presentation/pages/parcelles_page.dart';
export 'presentation/pages/parcelle_detail_page.dart';
