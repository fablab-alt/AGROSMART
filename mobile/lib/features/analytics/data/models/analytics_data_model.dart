import '../../domain/entities/analytics_data.dart';

class AnalyticsDataModel extends AnalyticsData {
  const AnalyticsDataModel({
    required super.roiPercentage,
    required super.roiTrend,
    required super.rendementData,
    required super.rendementesParCulture,
    required super.economies,
    required super.performanceParcelles,
  });

  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDataModel(
      roiPercentage: (json['roi_percentage'] as num?)?.toDouble() ?? 0.0,
      roiTrend: json['roi_trend'] as String? ?? 'stable',
      rendementData: RendementDataModel.fromJson(json['rendement'] ?? {}),
      rendementesParCulture:
          (json['rendements_par_culture'] as List<dynamic>?)
              ?.map(
                (e) => RendementParCultureModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      economies: EconomiesModel.fromJson(json['economies'] ?? {}),
      performanceParcelles:
          (json['performance_parcelles'] as List<dynamic>?)
              ?.map(
                (e) => PerformanceParcelleModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

class RendementDataModel extends RendementData {
  const RendementDataModel({
    required super.value,
    required super.vsTraditional,
    super.isPrediction,
    super.confidence,
    super.predictionDetails,
  });

  factory RendementDataModel.fromJson(Map<String, dynamic> json) {
    PredictionDetailsModel? predictionDetails;
    if (json['prediction_details'] != null) {
      predictionDetails = PredictionDetailsModel.fromJson(
        json['prediction_details'] as Map<String, dynamic>,
      );
    }

    return RendementDataModel(
      value: json['value'] as String? ?? '0%',
      vsTraditional: json['vs_traditional'] as bool? ?? false,
      isPrediction: json['is_prediction'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      predictionDetails: predictionDetails,
    );
  }
}

class PredictionDetailsModel extends PredictionDetails {
  const PredictionDetailsModel({
    required super.predictedYield,
    required super.minYield,
    required super.maxYield,
    required super.factors,
    required super.predictionDate,
    required super.modelVersion,
    super.realTimeInputs,
  });

  factory PredictionDetailsModel.fromJson(Map<String, dynamic> json) {
    return PredictionDetailsModel(
      predictedYield: (json['predicted_yield'] as num?)?.toDouble() ?? 0.0,
      minYield: (json['min_yield'] as num?)?.toDouble() ?? 0.0,
      maxYield: (json['max_yield'] as num?)?.toDouble() ?? 0.0,
      factors:
          (json['factors'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PredictionFactorModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      predictionDate: json['prediction_date'] != null
          ? DateTime.parse(json['prediction_date'] as String)
          : DateTime.now(),
      modelVersion: json['model_version'] as String? ?? 'v1.0',
      realTimeInputs:
          (json['real_time_inputs'] as List<dynamic>?)
              ?.map(
                (e) => RealTimeDataModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PredictionFactorModel extends PredictionFactor {
  const PredictionFactorModel({
    required super.name,
    required super.impact,
    required super.description,
    required super.status,
  });

  factory PredictionFactorModel.fromJson(Map<String, dynamic> json) {
    FactorStatus status;
    switch (json['status'] as String? ?? 'optimal') {
      case 'warning':
        status = FactorStatus.warning;
        break;
      case 'critical':
        status = FactorStatus.critical;
        break;
      default:
        status = FactorStatus.optimal;
    }

    return PredictionFactorModel(
      name: json['name'] as String? ?? '',
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      status: status,
    );
  }
}

class RealTimeDataModel extends RealTimeData {
  const RealTimeDataModel({
    required super.source,
    required super.name,
    required super.value,
    required super.unit,
    required super.timestamp,
  });

  factory RealTimeDataModel.fromJson(Map<String, dynamic> json) {
    return RealTimeDataModel(
      source: json['source'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class RendementParCultureModel extends RendementParCulture {
  const RendementParCultureModel({
    required super.culture,
    required super.rendementActuel,
    required super.rendementObjectif,
    required super.improvement,
  });

  factory RendementParCultureModel.fromJson(Map<String, dynamic> json) {
    return RendementParCultureModel(
      culture: json['culture'] as String? ?? '',
      rendementActuel: (json['rendement_actuel'] as num?)?.toDouble() ?? 0.0,
      rendementObjectif:
          (json['rendement_objectif'] as num?)?.toDouble() ?? 0.0,
      improvement: (json['improvement'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EconomiesModel extends Economies {
  const EconomiesModel({
    required super.eau,
    required super.engrais,
    required super.pertesEvitees,
    required super.total,
  });

  factory EconomiesModel.fromJson(Map<String, dynamic> json) {
    return EconomiesModel(
      eau: (json['eau'] as num?)?.toDouble() ?? 0.0,
      engrais: (json['engrais'] as num?)?.toDouble() ?? 0.0,
      pertesEvitees: (json['pertes_evitees'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PerformanceParcelleModel extends PerformanceParcelle {
  const PerformanceParcelleModel({
    required super.parcelleId,
    required super.nom,
    required super.rendement,
    required super.scoreQualite,
    required super.meilleurePratique,
  });

  factory PerformanceParcelleModel.fromJson(Map<String, dynamic> json) {
    return PerformanceParcelleModel(
      parcelleId: json['parcelle_id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      rendement: (json['rendement'] as num?)?.toDouble() ?? 0.0,
      scoreQualite: (json['score_qualite'] as num?)?.toDouble() ?? 0.0,
      meilleurePratique: json['meilleure_pratique'] as String? ?? '',
    );
  }
}
