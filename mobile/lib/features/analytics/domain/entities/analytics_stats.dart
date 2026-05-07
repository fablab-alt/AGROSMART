import 'package:equatable/equatable.dart';

class AnalyticsStats extends Equatable {
  final int roiPercentage;
  final String roiTrend;
  final String rendementValue;
  final String eauEconomisee;
  final String engraisReduction;
  final String pertesMaladies;
  final List<CultureYield> rendementsCulture;
  final Economies economies;
  final List<ParcellePerformance> performanceParcelles;

  const AnalyticsStats({
    required this.roiPercentage,
    required this.roiTrend,
    required this.rendementValue,
    required this.eauEconomisee,
    required this.engraisReduction,
    required this.pertesMaladies,
    required this.rendementsCulture,
    required this.economies,
    required this.performanceParcelles,
  });

  @override
  List<Object?> get props => [
        roiPercentage,
        roiTrend,
        rendementValue,
        eauEconomisee,
        engraisReduction,
        pertesMaladies,
        rendementsCulture,
        economies,
        performanceParcelles,
      ];
}

class CultureYield extends Equatable {
  final String culture;
  final double rendementActuel;
  final double rendementTraditionnel;
  final int improvement;

  const CultureYield({
    required this.culture,
    required this.rendementActuel,
    required this.rendementTraditionnel,
    required this.improvement,
  });

  @override
  List<Object?> get props => [culture, rendementActuel, rendementTraditionnel, improvement];
}

class Economies extends Equatable {
  final int eau;
  final int engrais;
  final int pertesEvitees;
  final int total;

  const Economies({
    required this.eau,
    required this.engrais,
    required this.pertesEvitees,
    required this.total,
  });

  @override
  List<Object?> get props => [eau, engrais, pertesEvitees, total];
}

class ParcellePerformance extends Equatable {
  final String nom;
  final int score;
  final bool aboveAverage;

  const ParcellePerformance({
    required this.nom,
    required this.score,
    required this.aboveAverage,
  });

  @override
  List<Object?> get props => [nom, score, aboveAverage];
}
