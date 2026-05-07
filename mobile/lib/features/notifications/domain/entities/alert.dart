import 'package:equatable/equatable.dart';

enum AlertLevel { info, important, critique }
enum AlertCategory { irrigation, maladie, meteo, sol, maintenance, general, commande }

/// Priority mapping for CDC compliance:
/// - critique (critical): Response required within 24h
/// - important: Response required within 48h  
/// - info: Informational, no specific deadline
enum AlertPriority { haute, moyenne, basse }

class Alert extends Equatable {
  final String id;
  final String title;
  final String message;
  final AlertLevel level;
  final AlertCategory category;
  final DateTime date;
  final bool isRead;
  
  // CDC Enhancements
  final AlertPriority priority;
  final DateTime? deadlineResponse; // Calculated based on level
  final String? actionRecommandee; // Recommended action
  final double? valeurDeclencheur; // Trigger value
  final double? seuilReference; // Reference threshold
  
  // References
  final String? parcelleId;
  final String? parcelleName;
  final String? sensorId;
  
  // Notification tracking
  final bool envoyeSMS;
  final bool envoyeWhatsApp;
  final bool envoyePush;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.category,
    required this.date,
    this.isRead = false,
    this.priority = AlertPriority.basse,
    this.deadlineResponse,
    this.actionRecommandee,
    this.valeurDeclencheur,
    this.seuilReference,
    this.parcelleId,
    this.parcelleName,
    this.sensorId,
    this.envoyeSMS = false,
    this.envoyeWhatsApp = false,
    this.envoyePush = false,
  });

  /// Check if alert is overdue based on CDC deadlines
  bool get isOverdue {
    if (deadlineResponse == null) return false;
    return DateTime.now().isAfter(deadlineResponse!);
  }

  /// Time remaining before deadline
  Duration? get timeRemaining {
    if (deadlineResponse == null) return null;
    return deadlineResponse!.difference(DateTime.now());
  }

  /// Calculate priority from level (for backward compatibility)
  static AlertPriority priorityFromLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.critique:
        return AlertPriority.haute;
      case AlertLevel.important:
        return AlertPriority.moyenne;
      case AlertLevel.info:
        return AlertPriority.basse;
    }
  }

  /// Calculate deadline based on level (CDC requirements)
  static DateTime calculateDeadline(AlertLevel level, DateTime createdAt) {
    switch (level) {
      case AlertLevel.critique:
        return createdAt.add(const Duration(hours: 24)); // <24h
      case AlertLevel.important:
        return createdAt.add(const Duration(hours: 48)); // <48h
      case AlertLevel.info:
        return createdAt.add(const Duration(days: 7)); // 7 days for info
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        level,
        category,
        date,
        isRead,
        priority,
        deadlineResponse,
        actionRecommandee,
        valeurDeclencheur,
        seuilReference,
        parcelleId,
        parcelleName,
        sensorId,
        envoyeSMS,
        envoyeWhatsApp,
        envoyePush,
      ];
}
