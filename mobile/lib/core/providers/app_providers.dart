import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/parcelles/presentation/bloc/parcelle_bloc.dart';
import '../../features/capteurs/presentation/bloc/sensor_bloc.dart';
import '../../features/notifications/presentation/bloc/alert_bloc.dart';
import '../../features/weather/presentation/bloc/weather_bloc.dart';
import '../../features/marketplace/presentation/bloc/marketplace_bloc.dart';
import '../../features/marketplace/presentation/bloc/equipment_bloc.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/recommandations/presentation/bloc/recommandation_bloc.dart';
import '../../features/community/presentation/bloc/chat_bloc.dart';
import '../../features/community/presentation/bloc/community_listing_bloc.dart';
import '../../features/assistant/presentation/bloc/chatbot_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../theme/theme_cubit.dart';
import '../../injection_container.dart' as di;

/// Fournit la liste de tous les BlocProviders de l'application
class AppProviders {
  static List<BlocProvider> get providers => [
    BlocProvider<AuthBloc>(
      create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus()),
    ),
    BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(storage: di.sl())),
    BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(di.sl())),
    BlocProvider<ParcelleBloc>(
      create: (_) => di.sl<ParcelleBloc>()..add(LoadParcelles()),
    ),
    BlocProvider<SensorBloc>(
      create: (_) => di.sl<SensorBloc>()..add(LoadSensors()),
    ),
    BlocProvider<AlertBloc>(
      create: (_) => di.sl<AlertBloc>()..add(LoadAlerts()),
    ),
    BlocProvider<MarketplaceBloc>(
      create: (_) => di.sl<MarketplaceBloc>()..add(LoadMarketplaceProducts()),
    ),
    BlocProvider<WeatherBloc>(
      create: (_) =>
          di.sl<WeatherBloc>()
            ..add(LoadWeatherForecast(latitude: 5.3600, longitude: -4.0083)),
    ),
    BlocProvider<AnalyticsBloc>(
      create: (_) => di.sl<AnalyticsBloc>()..add(LoadAnalytics()),
    ),
    BlocProvider<RecommandationBloc>(
      create: (_) => di.sl<RecommandationBloc>()..add(LoadRecommandations()),
    ),
    BlocProvider<EquipmentBloc>(
      create: (_) => di.sl<EquipmentBloc>()..add(LoadEquipments()),
    ),
    BlocProvider<ChatBloc>(
      create: (_) => di.sl<ChatBloc>()..add(LoadConversations()),
    ),
    BlocProvider<CommunityListingBloc>(
      create: (_) => di.sl<CommunityListingBloc>()..add(LoadListings()),
    ),
    BlocProvider<ChatbotBloc>(create: (_) => di.sl<ChatbotBloc>()),
    BlocProvider<CartBloc>(create: (_) => di.sl<CartBloc>()..add(LoadCart())),
    BlocProvider<FavoritesBloc>(
      create: (_) => di.sl<FavoritesBloc>()..add(LoadFavorites()),
    ),
  ];
}
