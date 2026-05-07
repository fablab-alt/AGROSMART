import 'package:get_it/get_it.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';

// Core
import 'core/network/network_info.dart';
import 'core/network/api_client.dart'; // Fixed import
import 'core/services/location_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/voice_assistant_service.dart';
import 'core/services/secure_storage_service.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/verify_otp.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Parcelles
import 'features/parcelles/data/datasources/parcelle_remote_data_source.dart';
import 'features/parcelles/data/repositories/parcelle_repository_impl.dart';
import 'features/parcelles/domain/repositories/parcelle_repository.dart';

// Diagnostics - Removed duplicate folder (using diagnostic/ instead)

// Dashboard
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Formations
import 'features/formations/data/datasources/formation_remote_data_source.dart';
import 'features/formations/data/repositories/formation_repository_impl.dart';
import 'features/formations/domain/repositories/formation_repository.dart';
import 'features/formations/presentation/bloc/formation_bloc.dart';

// Marketplace
import 'features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'features/marketplace/domain/repositories/marketplace_repository.dart';
import 'features/marketplace/domain/usecases/get_products.dart';
import 'features/marketplace/domain/usecases/create_product.dart';
import 'features/marketplace/presentation/bloc/marketplace_bloc.dart';

// Messages
import 'features/messages/data/datasources/message_remote_datasource.dart';
import 'features/messages/data/repositories/message_repository_impl.dart';
import 'features/messages/domain/repositories/message_repository.dart';
import 'features/messages/presentation/bloc/message_bloc.dart';

// Recommandations
import 'features/recommandations/presentation/bloc/recommandation_bloc.dart';

// Community Chat
import 'features/community/presentation/bloc/chat_bloc.dart';

// Marketplace additional blocs
import 'features/marketplace/presentation/bloc/payment_bloc.dart';
import 'features/marketplace/presentation/bloc/equipment_bloc.dart';

// Training - Removed duplicate folder (using formations/ instead)

// Orders
import 'features/orders/presentation/bloc/orders_bloc.dart';
import 'features/orders/domain/repositories/order_repository.dart';
import 'features/orders/data/repositories/order_repository_impl.dart';
import 'features/orders/data/datasources/order_remote_data_source.dart';

// Analytics
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/analytics/domain/repositories/analytics_repository.dart';
import 'features/analytics/data/repositories/analytics_repository_impl.dart';
import 'features/analytics/data/datasources/analytics_remote_data_source.dart';

// Diagnostic
import 'features/diagnostic/data/repositories/diagnostic_repository_impl.dart';
import 'features/diagnostic/data/datasources/diagnostics_remote_data_source.dart'
    as diagnostic_v2;
import 'features/diagnostic/presentation/bloc/diagnostic_bloc.dart';

// Capteurs
import 'features/capteurs/data/models/cached_sensor_data.dart';
import 'features/capteurs/data/datasources/sensor_local_data_source.dart';
import 'features/capteurs/data/datasources/sensor_remote_data_source.dart';
import 'features/capteurs/data/repositories/sensor_repository_impl.dart';
import 'features/capteurs/domain/repositories/sensor_repository.dart';
import 'features/capteurs/presentation/bloc/sensor_bloc.dart';

// Notifications
import 'features/notifications/data/datasources/alert_remote_data_source.dart';
import 'features/notifications/data/repositories/alert_repository_impl.dart';
import 'features/notifications/domain/repositories/alert_repository.dart';
import 'features/notifications/presentation/bloc/alert_bloc.dart';
import 'features/parcelles/presentation/bloc/parcelle_bloc.dart';

// Weather
import 'features/dashboard/data/repositories/weather_repository.dart';
import 'features/dashboard/data/datasources/weather_remote_data_source.dart';

import 'features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';

// Dashboard imports
import 'features/dashboard/data/models/cached_dashboard_data.dart';

// Weather imports
import 'features/weather/presentation/bloc/weather_bloc.dart';

// Forum imports
import 'features/forum/presentation/bloc/forum_bloc.dart';
import 'features/forum/domain/repositories/forum_repository.dart';
import 'features/forum/data/repositories/forum_repository_impl.dart';

// Recommandation imports
import 'features/recommandations/data/datasources/recommandation_remote_data_source.dart';

// Community Marketplace imports
import 'features/community/presentation/bloc/community_listing_bloc.dart';

// Stocks imports
import 'features/stocks/data/datasources/stock_remote_datasource.dart';
import 'features/stocks/data/repositories/stock_repository_impl.dart';
import 'features/stocks/domain/repositories/stock_repository.dart';
import 'features/stocks/domain/usecases/get_stocks.dart';
import 'features/stocks/domain/usecases/create_stock.dart';
import 'features/stocks/domain/usecases/add_mouvement.dart';
import 'features/stocks/presentation/bloc/stock_bloc.dart';

// Calendrier imports
import 'features/calendrier/data/datasources/calendrier_remote_datasource.dart';
import 'features/calendrier/data/repositories/calendrier_repository_impl.dart';
import 'features/calendrier/domain/repositories/calendrier_repository.dart';
import 'features/calendrier/domain/usecases/get_activites.dart';
import 'features/calendrier/domain/usecases/create_activite.dart';
import 'features/calendrier/domain/usecases/update_activite.dart';
import 'features/calendrier/domain/usecases/delete_activite.dart';
import 'features/calendrier/domain/usecases/get_activites_prochaines.dart';
import 'features/calendrier/domain/usecases/marquer_activite_terminee.dart';
import 'features/calendrier/presentation/bloc/calendrier_bloc.dart';

// Chatbot imports
import 'core/services/agri_chatbot_service.dart';
import 'features/assistant/presentation/bloc/chatbot_bloc.dart';

// Cart imports
import 'features/cart/presentation/bloc/cart_bloc.dart';

// Favorites imports
import 'features/favorites/presentation/bloc/favorites_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External Services
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerFactory(() => SettingsCubit(sl()));

  // Secure Storage Service
  final secureStorage = SecureStorageService();
  sl.registerLazySingleton(() => secureStorage);

  // Initialize Dio client with secure storage
  initDioClient(secureStorage);

  // Core API Client - Use the configured dioClient instead of new Dio()
  sl.registerLazySingleton(() => dioClient);
  sl.registerLazySingleton(() => ApiClient(dio: sl()));

  // Isar
  String? path;
  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    path = dir.path;
  }

  Isar? isar;
  try {
    isar = await Isar.open([
      CachedDashboardDataSchema,
      CachedSensorDataSchema,
    ], directory: path ?? '');
  } catch (e) {
    debugPrint('Isar error: $e. Deleting database...');
    if (path != null) {
      try {
        final dir = Directory(path);
        if (await dir.exists()) {
          final files = dir.listSync();
          for (var file in files) {
            if (file.path.endsWith('.isar') ||
                file.path.endsWith('.isar.lock')) {
              await file.delete();
            }
          }
        }
      } catch (e) {
        debugPrint('Error deleting database: $e');
      }
    }
    // Retry opening
    isar = await Isar.open([
      CachedDashboardDataSchema,
      CachedSensorDataSchema,
    ], directory: path ?? '');
  }
  sl.registerLazySingleton(() => isar!);

  // Data Sources registration continued
  sl.registerLazySingleton<SensorLocalDataSource>(
    () => SensorLocalDataSourceImpl(isar: sl()),
  );

  // Bloc Registration

  // Auth
  sl.registerFactory(
    () => AuthBloc(
      login: sl(),
      verifyOtp: sl(),
      register: sl(),
      updateProfile: sl(),
      logout: sl(),
      authRepository: sl(),
    ),
  );

  // Dashboard
  sl.registerFactory(() => DashboardBloc(getDashboardData: sl()));

  // Parcelles
  sl.registerFactory(() => ParcelleBloc(repository: sl()));

  // Sensors
  sl.registerFactory(() => SensorBloc(repository: sl()));

  // Notifications
  sl.registerFactory(() => AlertBloc(repository: sl()));

  // Messages (Replaces ChatBloc)
  sl.registerFactory(() => MessageBloc(repository: sl()));

  // Community Chat
  sl.registerFactory(() => ChatBloc(apiClient: sl()));

  // Payment
  sl.registerFactory(() => PaymentBloc(apiClient: sl()));

  // Equipment
  sl.registerFactory(() => EquipmentBloc(apiClient: sl()));

  // Training Formation - Using formations/FormationBloc instead

  // Diagnostic (using diagnostic/ folder)
  sl.registerFactory(() => DiagnosticBloc(repository: sl()));

  // Formations
  sl.registerFactory(() => FormationBloc(repository: sl()));

  // Marketplace
  sl.registerFactory(
    () => MarketplaceBloc(getProducts: sl(), createProduct: sl()),
  );

  // Recommandation
  sl.registerLazySingleton(() => RecommandationRemoteDataSource(sl()));
  sl.registerFactory(() => RecommandationBloc(dataSource: sl()));

  // Orders
  sl.registerFactory(() => OrdersBloc(repository: sl()));

  // Analytics
  sl.registerFactory(() => AnalyticsBloc(repository: sl()));

  // Weather
  sl.registerFactory(() => WeatherBloc(repository: sl()));

  // Forum
  sl.registerFactory(() => ForumBloc(repository: sl()));
  sl.registerLazySingleton<ForumRepository>(() => ForumRepositoryImpl());

  // Community Marketplace
  sl.registerFactory(() => CommunityListingBloc(apiClient: sl()));

  // Chatbot
  sl.registerLazySingleton(() => AgriChatbotService(apiClient: sl()));
  sl.registerFactory(() => ChatbotBloc(chatbotService: sl()));

  // Cart
  sl.registerFactory(() => CartBloc());

  // Favorites
  sl.registerFactory(() => FavoritesBloc());

  // Stocks
  sl.registerFactory(
    () => StockBloc(
      getStocksUseCase: sl(),
      createStockUseCase: sl(),
      addMouvementUseCase: sl(),
      repository: sl(),
    ),
  );

  // Calendrier
  sl.registerFactory(
    () => CalendrierBloc(
      getActivites: sl(),
      createActivite: sl(),
      updateActivite: sl(),
      deleteActivite: sl(),
      getActivitesProchaines: sl(),
      marquerActiviteTerminee: sl(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Use Cases
  // ---------------------------------------------------------------------------

  // Auth
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Dashboard
  sl.registerLazySingleton(() => GetDashboardData(sl()));

  // Diagnostics - using diagnostic/ folder

  // Marketplace
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => CreateProduct(sl()));

  // Stocks
  sl.registerLazySingleton(() => GetStocks(sl()));
  sl.registerLazySingleton(() => CreateStock(sl()));
  sl.registerLazySingleton(() => AddMouvement(sl()));

  // Calendrier
  sl.registerLazySingleton(() => GetActivites(sl()));
  sl.registerLazySingleton(() => CreateActivite(sl()));
  sl.registerLazySingleton(() => UpdateActivite(sl()));
  sl.registerLazySingleton(() => DeleteActivite(sl()));
  sl.registerLazySingleton(() => GetActivitesProchaines(sl()));
  sl.registerLazySingleton(() => MarquerActiviteTerminee(sl()));

  // ---------------------------------------------------------------------------
  // Repositories
  // ---------------------------------------------------------------------------

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), secureStorage: sl()),
  );

  // Dashboard
  sl.registerLazySingleton<DashboardRepository>(
    () =>
        DashboardRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Parcelles
  sl.registerLazySingleton<ParcelleRepository>(
    () => ParcelleRepositoryImpl(remoteDataSource: sl()),
  );

  // Sensors
  sl.registerLazySingleton<SensorRepository>(
    () => SensorRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Alerts
  sl.registerLazySingleton<AlertRepository>(
    () => AlertRepositoryImpl(remoteDataSource: sl()),
  );

  // Messages
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(remoteDataSource: sl()),
  );

  // Diagnostic
  sl.registerLazySingleton<DiagnosticRepository>(
    () => DiagnosticRepositoryImpl(remoteDataSource: sl()),
  );

  // Formations
  sl.registerLazySingleton<FormationRepository>(
    () => FormationRepositoryImpl(remoteDataSource: sl()),
  );

  // Marketplace
  sl.registerLazySingleton<MarketplaceRepository>(
    () => MarketplaceRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Orders
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl()),
  );

  // Analytics
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(remoteDataSource: sl()),
  );

  // Weather
  sl.registerLazySingleton(() => WeatherRepository(remoteDataSource: sl()));

  // Stocks
  sl.registerLazySingleton<StockRepository>(
    () => StockRepositoryImpl(remoteDataSource: sl()),
  );

  // Calendrier
  sl.registerLazySingleton<CalendrierRepository>(
    () => CalendrierRepositoryImpl(sl()),
  );

  // ---------------------------------------------------------------------------
  // Data Sources
  // ---------------------------------------------------------------------------

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      dio: sl<ApiClient>().dio,
      secureStorage: sl<SecureStorageService>(),
    ),
  );

  // Dashboard
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(isar: sl()),
  );

  // Parcelles
  sl.registerLazySingleton<ParcelleRemoteDataSource>(
    () => ParcelleRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Sensors
  sl.registerLazySingleton<SensorRemoteDataSource>(
    () => SensorRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Alerts
  sl.registerLazySingleton<AlertRemoteDataSource>(
    () => AlertRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Messages
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Diagnostic
  sl.registerLazySingleton<diagnostic_v2.DiagnosticRemoteDataSource>(
    () =>
        diagnostic_v2.DiagnosticRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Formations
  sl.registerLazySingleton<FormationRemoteDataSource>(
    () => FormationRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Marketplace
  sl.registerLazySingleton<MarketplaceRemoteDataSource>(
    () => MarketplaceRemoteDataSourceImpl(client: sl()),
  );

  // Orders
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(client: sl()),
  );

  // Analytics
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(client: sl()),
  );

  // Weather
  sl.registerLazySingleton<WeatherRemoteDataSource>(
    () => WeatherRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Stocks
  sl.registerLazySingleton<StockRemoteDataSource>(
    () => StockRemoteDataSource(apiClient: sl()),
  );

  // Calendrier
  sl.registerLazySingleton<CalendrierRemoteDataSource>(
    () => CalendrierRemoteDataSource(sl()),
  );

  // Services
  sl.registerLazySingleton(() => VoiceService());
  sl.registerLazySingleton(() => LocationService());
  sl.registerLazySingleton(() => VoiceAssistantService());
}
