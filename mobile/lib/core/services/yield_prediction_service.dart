import '../../features/capteurs/domain/entities/sensor.dart';
import '../../features/analytics/domain/entities/analytics_data.dart';

/// Service de prédiction du rendement basé sur les données temps réel
class YieldPredictionService {
  /// Calcule une prédiction de rendement basée sur les données temps réel
  PredictionDetails calculatePrediction({
    required List<Sensor> sensors,
    List<dynamic>? weatherForecasts,
    String? cropType,
    double? surfaceHa,
  }) {
    final factors = <PredictionFactor>[];
    final realTimeInputs = <RealTimeData>[];
    double baseYield = 2500.0; // kg/ha base pour le cacao en CI
    double multiplier = 1.0;

    // Analyser les données des capteurs
    for (final sensor in sensors) {
      if (sensor.type.toLowerCase().contains('npk')) {
        // Analyse NPK
        final npkAnalysis = _analyzeNPK(sensor);
        factors.add(npkAnalysis.factor);
        multiplier *= npkAnalysis.multiplier;

        if (sensor.nitrogen != null) {
          realTimeInputs.add(
            RealTimeData(
              source: 'sensor',
              name: 'Azote (N)',
              value: sensor.nitrogen!,
              unit: 'mg/kg',
              timestamp: sensor.lastUpdate,
            ),
          );
        }
        if (sensor.phosphorus != null) {
          realTimeInputs.add(
            RealTimeData(
              source: 'sensor',
              name: 'Phosphore (P)',
              value: sensor.phosphorus!,
              unit: 'mg/kg',
              timestamp: sensor.lastUpdate,
            ),
          );
        }
        if (sensor.potassium != null) {
          realTimeInputs.add(
            RealTimeData(
              source: 'sensor',
              name: 'Potassium (K)',
              value: sensor.potassium!,
              unit: 'mg/kg',
              timestamp: sensor.lastUpdate,
            ),
          );
        }
      } else if (sensor.type.toLowerCase().contains('humid') ||
          sensor.type.toLowerCase().contains('sol')) {
        // Analyse humidité du sol
        final humidityAnalysis = _analyzeHumidity(sensor);
        factors.add(humidityAnalysis.factor);
        multiplier *= humidityAnalysis.multiplier;

        if (sensor.lastValue != null) {
          realTimeInputs.add(
            RealTimeData(
              source: 'sensor',
              name: 'Humidité sol',
              value: sensor.lastValue!,
              unit: sensor.unit ?? '%',
              timestamp: sensor.lastUpdate,
            ),
          );
        }
      } else if (sensor.type.toLowerCase().contains('temp')) {
        // Analyse température
        final tempAnalysis = _analyzeTemperature(sensor);
        factors.add(tempAnalysis.factor);
        multiplier *= tempAnalysis.multiplier;

        if (sensor.lastValue != null) {
          realTimeInputs.add(
            RealTimeData(
              source: 'sensor',
              name: 'Température',
              value: sensor.lastValue!,
              unit: sensor.unit ?? '°C',
              timestamp: sensor.lastUpdate,
            ),
          );
        }
      }
    }

    // Ajouter un facteur météo si disponible
    if (weatherForecasts != null && weatherForecasts.isNotEmpty) {
      final weatherFactor = _analyzeWeather(weatherForecasts);
      factors.add(weatherFactor.factor);
      multiplier *= weatherFactor.multiplier;
    }

    // Calculer le rendement prédit
    final predictedYield = baseYield * multiplier;
    final variance = predictedYield * 0.15; // ±15% de variance

    return PredictionDetails(
      predictedYield: predictedYield,
      minYield: predictedYield - variance,
      maxYield: predictedYield + variance,
      factors: factors,
      predictionDate: DateTime.now(),
      modelVersion: 'v2.1-realtime',
      realTimeInputs: realTimeInputs,
    );
  }

  /// Analyse les données NPK du capteur
  _AnalysisResult _analyzeNPK(Sensor sensor) {
    double impact = 0;
    double multiplier = 1.0;
    FactorStatus status = FactorStatus.optimal;
    String description = '';

    final n = sensor.nitrogen ?? 0;
    final p = sensor.phosphorus ?? 0;
    final k = sensor.potassium ?? 0;

    // Valeurs optimales pour le cacao: N: 50-200, P: 30-100, K: 150-300
    if (n < 50 || p < 30 || k < 150) {
      status = FactorStatus.warning;
      multiplier = 0.85;
      impact = -15;
      description = 'Niveaux NPK sous-optimaux. Fertilisation recommandée.';
    } else if (n > 250 || p > 150 || k > 400) {
      status = FactorStatus.warning;
      multiplier = 0.90;
      impact = -10;
      description = 'Niveaux NPK élevés. Risque de stress pour les plantes.';
    } else {
      status = FactorStatus.optimal;
      multiplier = 1.10;
      impact = 10;
      description = 'Niveaux NPK optimaux. Conditions idéales de fertilité.';
    }

    return _AnalysisResult(
      factor: PredictionFactor(
        name: 'Fertilité du sol (NPK)',
        impact: impact,
        description: description,
        status: status,
      ),
      multiplier: multiplier,
    );
  }

  /// Analyse les données d'humidité
  _AnalysisResult _analyzeHumidity(Sensor sensor) {
    final humidity = sensor.lastValue ?? 50;
    double impact = 0;
    double multiplier = 1.0;
    FactorStatus status = FactorStatus.optimal;
    String description = '';

    if (humidity < 30) {
      status = FactorStatus.critical;
      multiplier = 0.70;
      impact = -30;
      description = 'Sol trop sec. Irrigation urgente nécessaire.';
    } else if (humidity < 50) {
      status = FactorStatus.warning;
      multiplier = 0.85;
      impact = -15;
      description = 'Humidité insuffisante. Augmenter l\'irrigation.';
    } else if (humidity > 85) {
      status = FactorStatus.warning;
      multiplier = 0.90;
      impact = -10;
      description = 'Sol trop humide. Risque de maladies fongiques.';
    } else {
      status = FactorStatus.optimal;
      multiplier = 1.05;
      impact = 5;
      description = 'Humidité optimale pour la croissance.';
    }

    return _AnalysisResult(
      factor: PredictionFactor(
        name: 'Humidité du sol',
        impact: impact,
        description: description,
        status: status,
      ),
      multiplier: multiplier,
    );
  }

  /// Analyse les données de température
  _AnalysisResult _analyzeTemperature(Sensor sensor) {
    final temp = sensor.lastValue ?? 25;
    double impact = 0;
    double multiplier = 1.0;
    FactorStatus status = FactorStatus.optimal;
    String description = '';

    // Température optimale pour le cacao: 20-30°C
    if (temp < 18) {
      status = FactorStatus.warning;
      multiplier = 0.85;
      impact = -15;
      description = 'Température trop basse. Croissance ralentie.';
    } else if (temp > 35) {
      status = FactorStatus.critical;
      multiplier = 0.75;
      impact = -25;
      description = 'Température excessive. Stress thermique des plantes.';
    } else if (temp >= 22 && temp <= 28) {
      status = FactorStatus.optimal;
      multiplier = 1.08;
      impact = 8;
      description = 'Température idéale pour la croissance.';
    } else {
      status = FactorStatus.optimal;
      multiplier = 1.0;
      impact = 0;
      description = 'Température acceptable.';
    }

    return _AnalysisResult(
      factor: PredictionFactor(
        name: 'Température',
        impact: impact,
        description: description,
        status: status,
      ),
      multiplier: multiplier,
    );
  }

  /// Analyse les prévisions météo
  _AnalysisResult _analyzeWeather(List<dynamic> forecasts) {
    // Analyse simplifiée des prévisions
    double impact = 0;
    double multiplier = 1.0;
    FactorStatus status = FactorStatus.optimal;
    String description = 'Conditions météorologiques favorables prévues.';

    // Pour une implémentation réelle, analyser les prévisions de pluie, etc.
    return _AnalysisResult(
      factor: PredictionFactor(
        name: 'Prévisions météo',
        impact: impact,
        description: description,
        status: status,
      ),
      multiplier: multiplier,
    );
  }

  /// Formate le rendement pour l'affichage
  String formatYield(double yield, {bool showUnit = true}) {
    if (yield >= 1000) {
      final tonnes = yield / 1000;
      return showUnit
          ? '${tonnes.toStringAsFixed(1)} t/ha'
          : tonnes.toStringAsFixed(1);
    }
    return showUnit
        ? '${yield.toStringAsFixed(0)} kg/ha'
        : yield.toStringAsFixed(0);
  }

  /// Calcule le pourcentage d'amélioration par rapport à la méthode traditionnelle
  String calculateImprovement(
    double predictedYield, {
    double traditionalYield = 2000,
  }) {
    final improvement =
        ((predictedYield - traditionalYield) / traditionalYield * 100);
    if (improvement >= 0) {
      return '+${improvement.toStringAsFixed(0)}%';
    }
    return '${improvement.toStringAsFixed(0)}%';
  }
}

class _AnalysisResult {
  final PredictionFactor factor;
  final double multiplier;

  _AnalysisResult({required this.factor, required this.multiplier});
}
