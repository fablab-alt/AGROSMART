import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final FlutterSecureStorage storage;

  ThemeCubit({required this.storage}) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await storage.read(key: 'theme_mode');
    if (theme != null) {
      emit(ThemeMode.values.firstWhere(
        (e) => e.toString() == theme, 
        orElse: () => ThemeMode.system
      ));
    }
  }

  Future<void> setTheme(ThemeMode theme) async {
    await storage.write(key: 'theme_mode', value: theme.toString());
    emit(theme);
  }
}
