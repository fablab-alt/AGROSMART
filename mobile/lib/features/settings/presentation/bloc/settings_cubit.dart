import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriculture/core/network/api_client.dart';

// États des paramètres utilisateur
class SettingsState {
  final bool isLowDataMode;
  final String language;
  final bool isVocalModeEnabled;
  final bool isNotificationEnabled;
  final bool isSaving;
  final String? errorMessage;

  const SettingsState({
    this.isLowDataMode = false,
    this.language = 'Français',
    this.isVocalModeEnabled = false,
    this.isNotificationEnabled = true,
    this.isSaving = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isLowDataMode,
    String? language,
    bool? isVocalModeEnabled,
    bool? isNotificationEnabled,
    bool? isSaving,
    String? errorMessage,
  }) {
    return SettingsState(
      isLowDataMode: isLowDataMode ?? this.isLowDataMode,
      language: language ?? this.language,
      isVocalModeEnabled: isVocalModeEnabled ?? this.isVocalModeEnabled,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  // Liste des langues supportées
  static const List<String> supportedLanguages = [
    'Français',
    'English',
    'Baoulé',
    'Malinké',
    'Sénoufo',
  ];
}

// Cubit pour gérer les paramètres
class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;
  ApiClient? _apiClient;

  SettingsCubit(this._prefs, {ApiClient? apiClient})
    : super(const SettingsState()) {
    _apiClient = apiClient;
    _loadSettings();
  }

  void setApiClient(ApiClient client) {
    _apiClient = client;
  }

  void _loadSettings() {
    final lowData = _prefs.getBool('isLowDataMode') ?? false;
    final lang = _prefs.getString('language') ?? 'Français';
    final vocalMode = _prefs.getBool('isVocalModeEnabled') ?? false;
    final notifications = _prefs.getBool('isNotificationEnabled') ?? true;
    emit(
      state.copyWith(
        isLowDataMode: lowData,
        language: lang,
        isVocalModeEnabled: vocalMode,
        isNotificationEnabled: notifications,
      ),
    );
  }

  void toggleLowDataMode(bool value) {
    _prefs.setBool('isLowDataMode', value);
    emit(state.copyWith(isLowDataMode: value));
  }

  Future<void> toggleVocalMode(bool value) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      // Sauvegarder localement
      await _prefs.setBool('isVocalModeEnabled', value);

      // Synchroniser avec le backend si disponible
      if (_apiClient != null) {
        try {
          await _apiClient!.patch(
            '/users/settings',
            data: {'vocal_mode_enabled': value},
          );
        } catch (e) {
          // Si erreur backend, on garde quand même la valeur locale
          debugPrint('Erreur sync backend mode vocal: $e');
        }
      }

      emit(state.copyWith(isVocalModeEnabled: value, isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erreur lors de la modification du mode vocal',
        ),
      );
    }
  }

  Future<void> toggleNotifications(bool value) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _prefs.setBool('isNotificationEnabled', value);

      if (_apiClient != null) {
        try {
          await _apiClient!.patch(
            '/users/settings',
            data: {'notifications_enabled': value},
          );
        } catch (e) {
          debugPrint('Erreur sync backend notifications: $e');
        }
      }

      emit(state.copyWith(isNotificationEnabled: value, isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erreur lors de la modification des notifications',
        ),
      );
    }
  }

  Future<void> setLanguage(String value) async {
    if (!SettingsState.supportedLanguages.contains(value)) {
      emit(state.copyWith(errorMessage: 'Langue non supportée'));
      return;
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _prefs.setString('language', value);

      if (_apiClient != null) {
        try {
          await _apiClient!.patch(
            '/users/settings',
            data: {'preferred_language': value},
          );
        } catch (e) {
          debugPrint('Erreur sync backend langue: $e');
        }
      }

      emit(state.copyWith(language: value, isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erreur lors du changement de langue',
        ),
      );
    }
  }

  // Charger les paramètres depuis le backend (après connexion)
  Future<void> loadFromBackend() async {
    if (_apiClient == null) return;

    try {
      final response = await _apiClient!.get('/users/profile');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = response.data['data'];

        final backendLang = userData['preferred_language'] as String?;
        final backendVocal = userData['vocal_mode_enabled'] as bool?;
        final backendNotif = userData['notifications_enabled'] as bool?;

        if (backendLang != null &&
            SettingsState.supportedLanguages.contains(backendLang)) {
          await _prefs.setString('language', backendLang);
        }
        if (backendVocal != null) {
          await _prefs.setBool('isVocalModeEnabled', backendVocal);
        }
        if (backendNotif != null) {
          await _prefs.setBool('isNotificationEnabled', backendNotif);
        }

        _loadSettings();
      }
    } catch (e) {
      debugPrint('Erreur chargement paramètres backend: $e');
    }
  }
}
