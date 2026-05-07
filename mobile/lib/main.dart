import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/app_bloc_observer.dart';
import 'core/config/environment_config.dart';
import 'core/utils/error_handler.dart';

void main() async {
  // Capturer les erreurs Flutter synchrones
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log l'erreur de manière sécurisée
    ErrorHandler.logError(
      details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework Error',
    );
  };

  // Capturer les erreurs asynchrones non gérées
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Select API environment from --dart-define APP_ENV (development|staging|production).
      EnvironmentConfig.initFromDartDefine();

      // Configurer le BlocObserver pour le debugging
      Bloc.observer = AppBlocObserver();

      await initializeDateFormatting('fr', null);
      await di.init();

      runApp(
        MultiBlocProvider(
          providers: AppProviders.providers,
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      // Gestion globale des erreurs asynchrones
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'Global Async Error',
      );

      // En production, afficher un message générique plutôt que crasher
      if (EnvironmentConfig.isProduction) {
        debugPrint('[ERROR] Une erreur inattendue s\'est produite');
      } else {
        debugPrint('[ERROR] Uncaught async error: $error');
        debugPrint('[ERROR] Stack trace: $stackTrace');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'AgroSmart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
