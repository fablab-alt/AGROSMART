import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/features/recommandations/domain/entities/recommandation.dart';
import 'package:agriculture/features/recommandations/data/datasources/recommandation_remote_data_source.dart';
import 'package:agriculture/features/diagnostic/domain/services/diagnostic_storage_service.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class RecommandationEvent extends Equatable {
  const RecommandationEvent();
  @override
  List<Object> get props => [];
}

class LoadRecommandations extends RecommandationEvent {}

class RefreshFromDiagnostics extends RecommandationEvent {}

// States
abstract class RecommandationState extends Equatable {
  const RecommandationState();
  @override
  List<Object> get props => [];
}

class RecommandationInitial extends RecommandationState {}

class RecommandationLoading extends RecommandationState {}

class RecommandationLoaded extends RecommandationState {
  final List<Recommandation> recommandations;
  final List<DiagnosticRecommandation> diagnosticRecommandations;

  const RecommandationLoaded(
    this.recommandations, {
    this.diagnosticRecommandations = const [],
  });

  @override
  List<Object> get props => [recommandations, diagnosticRecommandations];
}

class RecommandationError extends RecommandationState {
  final String message;
  const RecommandationError(this.message);
  @override
  List<Object> get props => [message];
}

/// Recommandation basée sur un diagnostic
class DiagnosticRecommandation extends Equatable {
  final String id;
  final String diagnosticId;
  final String titre;
  final String description;
  final String diseaseName;
  final double confidenceScore;
  final String severity;
  final String parcelleNom;
  final List<String> treatments;
  final List<String> preventions;
  final DateTime dateCreation;

  const DiagnosticRecommandation({
    required this.id,
    required this.diagnosticId,
    required this.titre,
    required this.description,
    required this.diseaseName,
    required this.confidenceScore,
    required this.severity,
    required this.parcelleNom,
    required this.treatments,
    required this.preventions,
    required this.dateCreation,
  });

  @override
  List<Object?> get props => [
    id,
    diagnosticId,
    titre,
    description,
    diseaseName,
    confidenceScore,
    severity,
    parcelleNom,
    treatments,
    preventions,
    dateCreation,
  ];
}

// Bloc
class RecommandationBloc
    extends Bloc<RecommandationEvent, RecommandationState> {
  final RecommandationRemoteDataSource dataSource;
  final DiagnosticStorageService _diagnosticService =
      DiagnosticStorageService();

  RecommandationBloc({required this.dataSource})
    : super(RecommandationInitial()) {
    on<LoadRecommandations>(_onLoadRecommandations);
    on<RefreshFromDiagnostics>(_onRefreshFromDiagnostics);
  }

  Future<void> _onLoadRecommandations(
    LoadRecommandations event,
    Emitter<RecommandationState> emit,
  ) async {
    emit(RecommandationLoading());
    try {
      // 1. Charger les recommandations depuis l'API
      final apiRecos = await dataSource.getActiveRecommandations();

      // 2. Générer les recommandations basées sur les diagnostics locaux
      final diagnosticRecos = _generateDiagnosticRecommandations();

      if (apiRecos.isEmpty && diagnosticRecos.isEmpty) {
        emit(RecommandationLoaded([], diagnosticRecommandations: []));
        return;
      }

      emit(
        RecommandationLoaded(
          apiRecos,
          diagnosticRecommandations: diagnosticRecos,
        ),
      );
    } catch (e) {
      // En cas d'erreur API, utiliser les recommandations de diagnostics locaux
      final diagnosticRecos = _generateDiagnosticRecommandations();
      emit(
        RecommandationLoaded([], diagnosticRecommandations: diagnosticRecos),
      );
    }
  }

  Future<void> _onRefreshFromDiagnostics(
    RefreshFromDiagnostics event,
    Emitter<RecommandationState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecommandationLoaded) {
      final diagnosticRecos = _generateDiagnosticRecommandations();
      emit(
        RecommandationLoaded(
          currentState.recommandations,
          diagnosticRecommandations: diagnosticRecos,
        ),
      );
    } else {
      add(LoadRecommandations());
    }
  }

  List<DiagnosticRecommandation> _generateDiagnosticRecommandations() {
    final List<DiagnosticRecommandation> recos = [];
    const uuid = Uuid();

    // Récupérer tous les diagnostics problématiques
    final problemDiagnostics = _diagnosticService.problemDiagnostics;

    for (final result in problemDiagnostics) {
      final diagnostic = result.diagnostic;

      // Déterminer la sévérité
      String severity = 'Faible';
      if (diagnostic.confidenceScore >= 80) {
        severity = 'Critique';
      } else if (diagnostic.confidenceScore >= 60) {
        severity = 'Élevée';
      } else if (diagnostic.confidenceScore >= 40) {
        severity = 'Moyenne';
      }

      // Extraire les traitements
      final treatments = diagnostic.treatmentSuggestions
          .split(RegExp(r'[.\n]'))
          .where((t) => t.trim().isNotEmpty)
          .map((t) => t.trim())
          .toList();

      // Générer des préventions basées sur le type de maladie
      final preventions = _generatePreventions(diagnostic.diseaseName);

      recos.add(
        DiagnosticRecommandation(
          id: uuid.v4(),
          diagnosticId: result.id,
          titre: 'Traitement requis: ${diagnostic.diseaseName}',
          description: diagnostic.recommendations,
          diseaseName: diagnostic.diseaseName,
          confidenceScore: diagnostic.confidenceScore,
          severity: severity,
          parcelleNom: result.parcelleNom.isNotEmpty
              ? result.parcelleNom
              : 'Non spécifiée',
          treatments: treatments,
          preventions: preventions,
          dateCreation: result.dateCreation,
        ),
      );
    }

    return recos;
  }

  List<String> _generatePreventions(String diseaseName) {
    final lowerName = diseaseName.toLowerCase();

    if (lowerName.contains('mildiou') || lowerName.contains('mildew')) {
      return [
        'Éviter l\'arrosage par aspersion',
        'Assurer une bonne ventilation',
        'Retirer les feuilles infectées',
        'Utiliser des variétés résistantes',
      ];
    } else if (lowerName.contains('rouille') || lowerName.contains('rust')) {
      return [
        'Espacer les plants pour une meilleure circulation d\'air',
        'Éviter l\'humidité excessive',
        'Appliquer des fongicides préventifs',
        'Rotation des cultures',
      ];
    } else if (lowerName.contains('pourri') || lowerName.contains('rot')) {
      return [
        'Améliorer le drainage du sol',
        'Éviter les blessures aux racines',
        'Réduire l\'irrigation',
        'Utiliser du compost sain',
      ];
    } else if (lowerName.contains('tache') || lowerName.contains('spot')) {
      return [
        'Retirer les débris végétaux',
        'Éviter l\'irrigation sur le feuillage',
        'Appliquer des traitements préventifs',
        'Rotation des cultures sur 3 ans',
      ];
    }

    // Préventions génériques
    return [
      'Maintenir une bonne hygiène des cultures',
      'Surveiller régulièrement les plants',
      'Assurer une nutrition équilibrée',
      'Favoriser la biodiversité',
    ];
  }
}
