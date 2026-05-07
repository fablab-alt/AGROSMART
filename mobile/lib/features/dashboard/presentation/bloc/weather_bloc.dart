import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/dashboard/data/repositories/weather_repository.dart';
import 'package:agriculture/features/dashboard/presentation/widgets/weather_widget.dart';

// Events
abstract class WeatherEvent {}
class LoadWeather extends WeatherEvent {
  final double lat;
  final double lon;
  LoadWeather({this.lat = 5.36, this.lon = -4.00}); // Default Abidjan
}

// States
abstract class WeatherState {}
class WeatherInitial extends WeatherState {}
class WeatherLoading extends WeatherState {}
class WeatherLoaded extends WeatherState {
  final WeatherData weather;
  WeatherLoaded(this.weather);
}
class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);
}

// Bloc
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository repository;

  WeatherBloc({required this.repository}) : super(WeatherInitial()) {
    on<LoadWeather>((event, emit) async {
      emit(WeatherLoading());
      try {
        final weather = await repository.getWeather(event.lat, event.lon);
        emit(WeatherLoaded(weather));
      } catch (e) {
        emit(WeatherError(e.toString()));
      }
    });
  }
}
