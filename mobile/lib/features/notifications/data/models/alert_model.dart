import 'package:agriculture/features/notifications/domain/entities/alert.dart';

class AlertModel extends Alert {
  const AlertModel({
    required super.id,
    required super.title,
    required super.message,
    required super.level,
    required super.category,
    required super.date,
    super.isRead,
    super.priority,
    super.deadlineResponse,
    super.actionRecommandee,
    super.valeurDeclencheur,
    super.seuilReference,
    super.parcelleId,
    super.parcelleName,
    super.sensorId,
    super.envoyeSMS,
    super.envoyeWhatsApp,
    super.envoyePush,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final  createdAt = json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now();
    
    final level = _parseLevel(json['niveau']);
    
    return AlertModel(
      id: json['id'] ?? '',
      title: json['titre'] ?? 'Nouvelle alerte',
      message: json['message'] ?? '',
      level: level,
      category: _parseCategory(json['categorie']),
      date: createdAt,
      isRead: json['lu_at'] != null,
      priority: Alert.priorityFromLevel(level),
      deadlineResponse: Alert.calculateDeadline(level, createdAt),
      actionRecommandee: json['action_recommandee'],
      valeurDeclencheur: json['valeur_declencheur'] != null 
          ? double.tryParse(json['valeur_declencheur'].toString())
          : null,
      seuilReference: json['seuil_reference'] != null
          ? double.tryParse(json['seuil_reference'].toString())
          : null,
      parcelleId: json['parcelle_id'],
      parcelleName: json['parcelle_nom'], // Assuming join in backend
      sensorId: json['capteur_id'],
      envoyeSMS: json['envoye_sms'] ?? false,
      envoyeWhatsApp: json['envoye_whatsapp'] ?? false,
      envoyePush: json['envoye_push'] ?? false,
    );
  }

  static AlertLevel _parseLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'critical':
      case 'critique':
        return AlertLevel.critique;
      case 'warning':
      case 'attention':
      case 'important':
        return AlertLevel.important;
      default:
        return AlertLevel.info;
    }
  }

  static AlertCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'irrigation': return AlertCategory.irrigation;
      case 'maladie': return AlertCategory.maladie;
      case 'meteo': return AlertCategory.meteo;
      case 'sol': return AlertCategory.sol;
      case 'maintenance': return AlertCategory.maintenance;
      case 'order': 
      case 'commande': return AlertCategory.commande;
      default: return AlertCategory.general;
    }
  }
}
