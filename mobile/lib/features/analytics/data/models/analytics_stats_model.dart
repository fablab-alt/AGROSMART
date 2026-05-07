import '../../domain/entities/analytics_stats.dart';

class AnalyticsStatsModel extends AnalyticsStats {
  const AnalyticsStatsModel({
    required super.roiPercentage,
    required super.roiTrend,
    required super.rendementValue,
    required super.eauEconomisee,
    required super.engraisReduction,
    required super.pertesMaladies,
    required super.rendementsCulture,
    required super.economies,
    required super.performanceParcelles,
  });

  factory AnalyticsStatsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsStatsModel(
      roiPercentage: json['roi_percentage'] ?? 0,
      roiTrend: json['roi_trend'] ?? '0%',
      rendementValue: json['rendement']?['value'] ?? '+0%',
      eauEconomisee: json['eau_economisee'] ?? '0%',
      engraisReduction: json['engrais_reduction'] ?? '0%',
      pertesMaladies: json['pertes_maladies'] ?? '0%',
      rendementsCulture: (json['rendements_par_culture'] as List<dynamic>?)
              ?.map((e) => CultureYieldModel.fromJson(e))
              .toList() ??
          [],
      economies: EconomiesModel.fromJson(json['economies'] ?? {}),
      performanceParcelles: (json['performance_parcelles'] as List<dynamic>?)
              ?.map((e) => ParcellePerformanceModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CultureYieldModel extends CultureYield {
  const CultureYieldModel({
    required super.culture,
    required super.rendementActuel,
    required super.rendementTraditionnel,
    required super.improvement,
  });

  factory CultureYieldModel.fromJson(Map<String, dynamic> json) {
    return CultureYieldModel(
      culture: json['culture'] ?? '',
      rendementActuel: (json['rendement_actuel'] ?? 0).toDouble(),
      rendementTraditionnel: (json['rendement_traditionnel'] ?? 0).toDouble(),
      improvement: json['improvement'] ?? 0,
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
      eau: json['eau'] ?? 0,
      engrais: json['engrais'] ?? 0,
      pertesEvitees: json['pertes_evitees'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class ParcellePerformanceModel extends ParcellePerformance {
  const ParcellePerformanceModel({
    required super.nom,
    required super.score,
    required super.aboveAverage,
  });

  factory ParcellePerformanceModel.fromJson(Map<String, dynamic> json) {
    return ParcellePerformanceModel(
      nom: json['nom'] ?? '',
      score: json['score'] ?? 0,
      aboveAverage: json['above_average'] ?? false,
    );
  }
}
