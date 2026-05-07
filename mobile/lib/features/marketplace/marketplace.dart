/// Barrel export pour la feature Marketplace
///
/// Usage:
/// ```dart
/// import 'package:agriculture/features/marketplace/marketplace.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/product.dart';

// Domain - Repositories
export 'domain/repositories/marketplace_repository.dart';

// Presentation - Bloc
export 'presentation/bloc/marketplace_bloc.dart';
export 'presentation/bloc/equipment_bloc.dart';

// Presentation - Pages
export 'presentation/pages/marketplace_page.dart';
export 'presentation/pages/add_product_page.dart';
export 'presentation/pages/product_detail_page.dart';
