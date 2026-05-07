import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/core/config/environment_config.dart';

/// BlocObserver personnalisé pour le logging et debugging des Blocs
///
/// Ce observer:
/// - Log les changements d'état en dev/staging
/// - Capture les erreurs dans les blocs
/// - Aide au debugging des transitions d'état
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (EnvironmentConfig.enableNetworkLogs) {
      debugPrint('[BLOC] 🆕 Created: ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (EnvironmentConfig.enableNetworkLogs) {
      debugPrint('[BLOC] 📩 Event: ${bloc.runtimeType} → ${event.runtimeType}');
    }
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (EnvironmentConfig.enableNetworkLogs) {
      debugPrint('[BLOC] 🔄 Change: ${bloc.runtimeType}');
      debugPrint('  Current: ${change.currentState.runtimeType}');
      debugPrint('  Next: ${change.nextState.runtimeType}');
    }
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (EnvironmentConfig.enableNetworkLogs) {
      debugPrint('[BLOC] ➡️ Transition: ${bloc.runtimeType}');
      debugPrint('  Event: ${transition.event.runtimeType}');
      debugPrint(
        '  ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // Toujours logger les erreurs, même en production
    debugPrint('[BLOC] ❌ Error in ${bloc.runtimeType}');
    debugPrint('  Error: $error');

    // En développement, afficher la stack trace complète
    if (!EnvironmentConfig.isProduction) {
      debugPrint('  StackTrace: $stackTrace');
    }

    // TODO: En production, envoyer à Crashlytics/Sentry
    // if (EnvironmentConfig.isProduction) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (EnvironmentConfig.enableNetworkLogs) {
      debugPrint('[BLOC] 🗑️ Closed: ${bloc.runtimeType}');
    }
  }
}
