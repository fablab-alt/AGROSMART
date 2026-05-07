class AnalyticsData {
  final double roiPercentage;
  final String roiTrend;
  final RendementData rendementData;
  final List<RendementParCulture> rendementesParCulture;
  final Economies economies;
  final List<PerformanceParcelle> performanceParcelles;

  const AnalyticsData({
    required this.roiPercentage,
    required this.roiTrend,
    required this.rendementData,
    required this.rendementesParCulture,
    required this.economies,
    required this.performanceParcelles,
  });

  /// Getter pour la compatibilité avec les widgets
  RendementData get rendement => rendementData;

  /// Getters pour les métriques économiques
  String get eauEconomisee => '${economies.eau.toStringAsFixed(0)}%';
  String get engraisReduction => '${economies.engrais.toStringAsFixed(0)}%';
  String get pertesMaladies =>
      '${economies.pertesEvitees.toStringAsFixed(0)} FCFA';
}

class RendementData {
  final String value;
  final bool vsTraditional;
  final bool isPrediction;
  final double confidence; // 0.0 to 1.0
  final PredictionDetails? predictionDetails;

  const RendementData({
    required this.value,
    required this.vsTraditional,
    this.isPrediction = false,
    this.confidence = 1.0,
    this.predictionDetails,
  });
}

/// Détails de la prédiction IA basée sur les données temps réel
class PredictionDetails {
  final double predictedYield; // Rendement prédit en kg/ha
  final double minYield; // Fourchette basse
  final double maxYield; // Fourchette haute
  final List<PredictionFactor> factors; // Facteurs influençant la prédiction
  final DateTime predictionDate;
  final String modelVersion;
  final List<RealTimeData> realTimeInputs; // Données temps réel utilisées

  const PredictionDetails({
    required this.predictedYield,
    required this.minYield,
    required this.maxYield,
    required this.factors,
    required this.predictionDate,
    required this.modelVersion,
    this.realTimeInputs = const [],
  });
}

/// Facteur influençant la prédiction
class PredictionFactor {
  final String name;
  final double impact; // -100 à +100 (négatif = impact négatif)
  final String description;
  final FactorStatus status;

  const PredictionFactor({
    required this.name,
    required this.impact,
    required this.description,
    required this.status,
  });
}

enum FactorStatus { optimal, warning, critical }

/// Données temps réel utilisées pour la prédiction
class RealTimeData {
  final String source; // 'sensor', 'weather', 'historical'
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  const RealTimeData({
    required this.source,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}

class RendementParCulture {
  final String culture;
  final double rendementActuel;
  final double rendementObjectif;
  final double improvement;

  const RendementParCulture({
    required this.culture,
    required this.rendementActuel,
    required this.rendementObjectif,
    required this.improvement,
  });
}

class Economies {
  final double eau;
  final double engrais;
  final double pertesEvitees;
  final double total;

  const Economies({
    required this.eau,
    required this.engrais,
    required this.pertesEvitees,
    required this.total,
  });
}

class PerformanceParcelle {
  final String parcelleId;
  final String nom;
  final double rendement;
  final double scoreQualite;
  final String meilleurePratique;

  const PerformanceParcelle({
    required this.parcelleId,
    required this.nom,
    required this.rendement,
    required this.scoreQualite,
    required this.meilleurePratique,
  });
}
