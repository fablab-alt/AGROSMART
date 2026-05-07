/// Service de notifications push Firebase Cloud Messaging
/// AgroSmart - Application Mobile
///
/// Ce service gère:
/// - L'initialisation de FCM
/// - La réception des notifications
/// - Les permissions de notification
/// - La gestion des tokens FCM
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

// ignore: unused_import - kept for potential debug usage
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications push
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;
  Function(Map<String, dynamic>)? _onNotificationTap;

  /// Token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Initialise le service de notifications
  Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationTap,
  }) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;

    // Initialiser les notifications locales
    await _initializeLocalNotifications();

    // FCM token: firebase_messaging n'est pas encore dans les dépendances.
    // Ce token local permet aux notifications locales de fonctionner.
    // TODO: Ajouter firebase_messaging et utiliser FirebaseMessaging.instance.getToken()
    _fcmToken = 'local_device_${DateTime.now().millisecondsSinceEpoch}';

    _isInitialized = true;
    developer.log('[PushNotification] Service initialized', name: 'FCM');
  }

  /// Initialise les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Créer les canaux de notification Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Crée les canaux de notification Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Canal pour les alertes critiques
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'critical_alerts',
        'Alertes Critiques',
        description: 'Notifications pour les alertes critiques',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Canal pour les avertissements
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'warnings',
        'Avertissements',
        description: 'Notifications pour les avertissements',
        importance: Importance.high,
      ),
    );

    // Canal pour les diagnostics
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'diagnostics',
        'Diagnostics',
        description: 'Notifications pour les résultats de diagnostic',
        importance: Importance.high,
      ),
    );

    // Canal pour les messages
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Notifications pour les nouveaux messages',
        importance: Importance.defaultImportance,
      ),
    );

    // Canal pour les commandes
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'orders',
        'Commandes',
        description: 'Notifications pour les mises à jour de commandes',
        importance: Importance.defaultImportance,
      ),
    );

    // Canal par défaut
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'default',
        'Général',
        description: 'Notifications générales',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Gère la réponse au tap sur une notification
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _onNotificationTap?.call(data);
        developer.log(
          '[PushNotification] Notification tapped: $data',
          name: 'FCM',
        );
      } catch (e) {
        developer.log(
          '[PushNotification] Error parsing payload: $e',
          name: 'FCM',
        );
      }
    }
  }

  /// Demande les permissions de notification
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted;
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted =
          await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    return true;
  }

  /// Affiche une notification locale
  Future<void> showNotification({
    required String title,
    required String body,
    String? channelId,
    Map<String, dynamic>? data,
    NotificationImportance importance =
        NotificationImportance.defaultImportance,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'default',
      _getChannelName(channelId ?? 'default'),
      channelDescription: 'AgroSmart notifications',
      importance: _mapImportance(importance),
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Affiche une alerte critique
  Future<void> showCriticalAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      title: '🚨 $title',
      body: body,
      channelId: 'critical_alerts',
      data: data,
      importance: NotificationImportance.max,
    );
  }

  /// Affiche une notification de maladie détectée
  Future<void> showDiseaseNotification({
    required String diseaseName,
    required double confidence,
    String? parcelleId,
  }) async {
    await showNotification(
      title: '🔬 Maladie Détectée',
      body:
          '$diseaseName détectée avec ${(confidence * 100).toStringAsFixed(0)}% de confiance',
      channelId: 'diagnostics',
      data: {
        'type': 'disease_detected',
        'disease': diseaseName,
        'parcelleId': parcelleId,
      },
      importance: NotificationImportance.high,
    );
  }

  /// Affiche une notification de rappel d'irrigation
  Future<void> showIrrigationReminder({
    required String parcelleName,
    String? parcelleId,
  }) async {
    await showNotification(
      title: '💧 Rappel Irrigation',
      body: 'Il est temps d\'irriguer votre parcelle "$parcelleName"',
      channelId: 'default',
      data: {'type': 'irrigation_reminder', 'parcelleId': parcelleId},
    );
  }

  /// Affiche une notification de commande
  Future<void> showOrderNotification({
    required String orderId,
    required String status,
    String? message,
  }) async {
    final statusMessages = {
      'CONFIRMED': 'Votre commande a été confirmée',
      'SHIPPED': 'Votre commande est en cours de livraison',
      'DELIVERED': 'Votre commande a été livrée',
      'CANCELLED': 'Votre commande a été annulée',
    };

    await showNotification(
      title: '🛒 Mise à jour commande',
      body: message ?? statusMessages[status] ?? 'Statut: $status',
      channelId: 'orders',
      data: {'type': 'order_update', 'orderId': orderId, 'status': status},
    );
  }

  /// Affiche une notification de nouveau message
  Future<void> showNewMessageNotification({
    required String senderName,
    required String messagePreview,
    String? messageId,
    String? senderId,
  }) async {
    await showNotification(
      title: '💬 Message de $senderName',
      body: messagePreview.length > 100
          ? '${messagePreview.substring(0, 100)}...'
          : messagePreview,
      channelId: 'messages',
      data: {
        'type': 'new_message',
        'messageId': messageId,
        'senderId': senderId,
      },
    );
  }

  /// Affiche une alerte météo
  Future<void> showWeatherAlert({
    required String message,
    String? severity,
    String? region,
  }) async {
    await showNotification(
      title: '⛈️ Alerte Météo',
      body: message,
      channelId: severity == 'critical' ? 'critical_alerts' : 'warnings',
      data: {'type': 'weather_alert', 'severity': severity, 'region': region},
      importance: severity == 'critical'
          ? NotificationImportance.max
          : NotificationImportance.high,
    );
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Retourne le nom du canal
  String _getChannelName(String channelId) {
    final names = {
      'critical_alerts': 'Alertes Critiques',
      'warnings': 'Avertissements',
      'diagnostics': 'Diagnostics',
      'messages': 'Messages',
      'orders': 'Commandes',
      'default': 'Général',
    };
    return names[channelId] ?? 'Général';
  }

  /// Mappe l'importance vers le format Flutter
  Importance _mapImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.max:
        return Importance.max;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.min:
        return Importance.min;
    }
  }
}

/// Niveaux d'importance des notifications
enum NotificationImportance { max, high, defaultImportance, low, min }
