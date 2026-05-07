import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/weather.dart';
import 'package:agriculture/features/dashboard/data/repositories/weather_repository.dart';
import 'package:agriculture/core/utils/error_handler.dart';

// Events
abstract class WeatherEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWeatherForecast extends WeatherEvent {
  final double latitude;
  final double longitude;
  final String? location;

  LoadWeatherForecast({
    required this.latitude,
    required this.longitude,
    this.location,
  });

  @override
  List<Object?> get props => [latitude, longitude, location];
}

class LoadWeatherAlerts extends WeatherEvent {
  final double latitude;
  final double longitude;

  LoadWeatherAlerts({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class RefreshWeather extends WeatherEvent {}

// States
abstract class WeatherState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherForecastLoaded extends WeatherState {
  final List<WeatherForecast> forecasts;
  final List<WeatherAlert> alerts;

  WeatherForecastLoaded({required this.forecasts, this.alerts = const []});

  @override
  List<Object?> get props => [forecasts, alerts];
}

class WeatherError extends WeatherState {
  final String message;

  WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository repository;

  WeatherBloc({required this.repository}) : super(WeatherInitial()) {
    on<LoadWeatherForecast>(_onLoadWeatherForecast);
    on<LoadWeatherAlerts>(_onLoadWeatherAlerts);
    on<RefreshWeather>(_onRefreshWeather);
  }

  double? _lastLat;
  double? _lastLon;

  Future<void> _onLoadWeatherForecast(
    LoadWeatherForecast event,
    Emitter<WeatherState> emit,
  ) async {
    _lastLat = event.latitude;
    _lastLon = event.longitude;
    emit(WeatherLoading());
    try {
      final forecasts = await repository.getForecasts(
        event.latitude,
        event.longitude,
      );

      // Fetch alerts as well, fail silently if error
      List<WeatherAlert> alerts = [];
      try {
        alerts = await repository.getAlerts(event.latitude, event.longitude);
      } catch (alertError) {
        // Les alertes sont optionnelles, on continue sans
        ErrorHandler.logError(alertError, context: 'WeatherAlerts');
      }

      emit(WeatherForecastLoaded(forecasts: forecasts, alerts: alerts));
    } catch (e) {
      ErrorHandler.logError(e, context: 'LoadWeatherForecast');
      emit(WeatherError("Impossible de charger la météo"));
    }
  }

  Future<void> _onLoadWeatherAlerts(
    LoadWeatherAlerts event,
    Emitter<WeatherState> emit,
  ) async {
    try {
      final alerts = await repository.getAlerts(
        event.latitude,
        event.longitude,
      );

      if (state is WeatherForecastLoaded) {
        final currentState = state as WeatherForecastLoaded;
        emit(
          WeatherForecastLoaded(
            forecasts: currentState.forecasts,
            alerts: alerts,
          ),
        );
      }
    } catch (e) {
      // Erreur d'alertes non critique - logger seulement
      ErrorHandler.logError(e, context: 'LoadWeatherAlerts');
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (_lastLat == null || _lastLon == null) {
      // Fallback or ignore if no previous location
      // Try Abidjan defaults if completely missing
      _lastLat ??= 5.3600;
      _lastLon ??= -4.0083;
    }

    emit(WeatherLoading());
    try {
      final forecasts = await repository.getForecasts(_lastLat!, _lastLon!);
      final alerts = await repository.getAlerts(_lastLat!, _lastLon!);
      emit(WeatherForecastLoaded(forecasts: forecasts, alerts: alerts));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }

  // Mock data generators (to be removed when backend is integrated)
  // Mocks removed
}
