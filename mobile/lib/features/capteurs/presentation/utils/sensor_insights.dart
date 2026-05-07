import 'package:flutter/material.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';

class SensorInsight {
  final String label;
  final String message;
  final String recommendation;
  final Color color;

  const SensorInsight({
    required this.label,
    required this.message,
    required this.recommendation,
    required this.color,
  });
}

SensorInsight getSensorInsight(Sensor sensor) {
  final type = sensor.type.toLowerCase();
  final value = sensor.lastValue;

  if (value == null) {
    return const SensorInsight(
      label: 'Donnée indisponible',
      message: 'Le capteur ne remonte pas encore de mesure fiable.',
      recommendation: 'Vérifiez l’alimentation et la connexion du capteur.',
      color: Colors.grey,
    );
  }

  if (type.contains('humid')) {
    if (value < 30) {
      return const SensorInsight(
        label: 'Action requise',
        message: 'Le sol est trop sec pour une bonne croissance.',
        recommendation: 'Arrosez rapidement pour remonter l’humidité du sol.',
        color: Colors.red,
      );
    }
    if (value < 40) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Le sol commence à manquer d’eau.',
        recommendation:
            'Préparez un arrosage léger dans les prochaines heures.',
        color: Colors.orange,
      );
    }
    if (value <= 70) {
      return const SensorInsight(
        label: 'Bon',
        message: 'L’humidité du sol est correcte pour la plupart des cultures.',
        recommendation: 'Aucune action urgente, continuez la surveillance.',
        color: Colors.green,
      );
    }
    if (value <= 85) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Le sol est un peu trop humide.',
        recommendation: 'Réduisez l’arrosage et vérifiez le drainage.',
        color: Colors.orange,
      );
    }
    return const SensorInsight(
      label: 'Action requise',
      message: 'Le sol est saturé en eau, risque de stress racinaire.',
      recommendation: 'Stoppez l’arrosage et améliorez le drainage.',
      color: Colors.red,
    );
  }

  if (type.contains('uv') || type.contains('ultra')) {
    if (value < 3) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'L’ensoleillement est faible.',
        recommendation: 'Vérifiez si la parcelle est ombragée trop longtemps.',
        color: Colors.orange,
      );
    }
    if (value <= 7) {
      return const SensorInsight(
        label: 'Bon',
        message: 'Les plantes sont bien éclairées, exposition correcte.',
        recommendation: 'Tout va bien, maintenez les pratiques actuelles.',
        color: Colors.green,
      );
    }
    if (value <= 10) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Rayonnement UV élevé, risque de stress en heures chaudes.',
        recommendation:
            'Prévoyez l’arrosage tôt le matin ou en fin de journée.',
        color: Colors.orange,
      );
    }
    return const SensorInsight(
      label: 'Action requise',
      message: 'Rayonnement UV très fort, stress potentiel pour la culture.',
      recommendation:
          'Protégez les plants sensibles (ombrage, paillage, arrosage adapté).',
      color: Colors.red,
    );
  }

  if (type.contains('temp')) {
    if (value < 12) {
      return const SensorInsight(
        label: 'Action requise',
        message: 'Température trop basse pour une croissance active.',
        recommendation:
            'Protégez les plants sensibles et limitez les stress hydriques.',
        color: Colors.red,
      );
    }
    if (value < 18) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Température un peu basse.',
        recommendation:
            'Surveillez l’évolution, surtout en matinée et la nuit.',
        color: Colors.orange,
      );
    }
    if (value <= 32) {
      return const SensorInsight(
        label: 'Bon',
        message: 'Température favorable à la plupart des cultures.',
        recommendation: 'Conditions correctes, poursuivez le suivi normal.',
        color: Colors.green,
      );
    }
    if (value <= 36) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Température élevée, risque de stress thermique.',
        recommendation:
            'Renforcez l’irrigation et évitez les interventions en plein midi.',
        color: Colors.orange,
      );
    }
    return const SensorInsight(
      label: 'Action requise',
      message:
          'Température trop élevée pour un fonctionnement optimal des plantes.',
      recommendation:
          'Arrosez aux heures fraîches et envisagez un ombrage temporaire.',
      color: Colors.red,
    );
  }

  if (type.contains('ph')) {
    if (value < 5.5) {
      return const SensorInsight(
        label: 'Action requise',
        message: 'Sol trop acide pour de nombreuses cultures.',
        recommendation: 'Corrigez progressivement le pH (apports adaptés).',
        color: Colors.red,
      );
    }
    if (value <= 7.2) {
      return const SensorInsight(
        label: 'Bon',
        message: 'pH du sol équilibré pour la majorité des cultures.',
        recommendation: 'Rien d’urgent, maintenez les apports actuels.',
        color: Colors.green,
      );
    }
    return const SensorInsight(
      label: 'À surveiller',
      message: 'pH du sol élevé, assimilation de certains nutriments limitée.',
      recommendation:
          'Ajustez la fertilisation et surveillez l’évolution du pH.',
      color: Colors.orange,
    );
  }

  if (type.contains('npk') || type.contains('nutriment')) {
    final n = sensor.nitrogen;
    final p = sensor.phosphorus;
    final k = sensor.potassium;

    if (n == null || p == null || k == null) {
      return const SensorInsight(
        label: 'À surveiller',
        message: 'Mesure NPK partielle.',
        recommendation:
            'Complétez l’analyse avant de corriger la fertilisation.',
        color: Colors.orange,
      );
    }

    final average = (n + p + k) / 3;
    if (average < 15) {
      return const SensorInsight(
        label: 'Action requise',
        message: 'Nutriments globalement faibles.',
        recommendation: 'Planifiez un apport fertilisant adapté à la culture.',
        color: Colors.red,
      );
    }
    if (average <= 35) {
      return const SensorInsight(
        label: 'Bon',
        message: 'Niveau nutritif global correct.',
        recommendation: 'Maintenez le plan de fertilisation en cours.',
        color: Colors.green,
      );
    }
    return const SensorInsight(
      label: 'À surveiller',
      message: 'Niveau nutritif élevé.',
      recommendation:
          'Évitez la sur-fertilisation et contrôlez les prochains relevés.',
      color: Colors.orange,
    );
  }

  return const SensorInsight(
    label: 'Information',
    message:
        'Mesure reçue, interprétation spécifique non disponible pour ce type.',
    recommendation: 'Suivez la tendance des valeurs sur plusieurs jours.',
    color: Colors.blue,
  );
}
