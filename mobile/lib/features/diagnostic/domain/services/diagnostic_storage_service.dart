import 'dart:async';
import 'package:agriculture/features/diagnostic/data/models/diagnostic_model.dart';

/// Service pour stocker et partager les résultats de diagnostic entre les features
/// Utilise un pattern Singleton pour être accessible globalement
class DiagnosticStorageService {
  static final DiagnosticStorageService _instance =
      DiagnosticStorageService._internal();
  factory DiagnosticStorageService() => _instance;
  DiagnosticStorageService._internal();

  final List<DiagnosticResult> _diagnosticResults = [];
  final _diagnosticStreamController =
      StreamController<List<DiagnosticResult>>.broadcast();

  /// Stream pour écouter les changements de diagnostics
  Stream<List<DiagnosticResult>> get diagnosticsStream =>
      _diagnosticStreamController.stream;

  /// Liste des diagnostics enregistrés
  List<DiagnosticResult> get diagnostics =>
      List.unmodifiable(_diagnosticResults);

  /// Ajouter un nouveau diagnostic
  void addDiagnostic(
    DiagnosticModel model,
    String parcelleId,
    String parcelleNom,
  ) {
    final result = DiagnosticResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      diagnostic: model,
      parcelleId: parcelleId,
      parcelleNom: parcelleNom,
      dateCreation: DateTime.now(),
      isProcessed: false,
    );

    _diagnosticResults.insert(0, result);
    _diagnosticStreamController.add(_diagnosticResults);
  }

  /// Ajouter un diagnostic avec l'objet DiagnosticResult complet
  void addDiagnosticResult(DiagnosticResult result) {
    _diagnosticResults.insert(0, result);
    _diagnosticStreamController.add(_diagnosticResults);
  }

  /// Marquer un diagnostic comme traité
  void markAsProcessed(String diagnosticId) {
    final index = _diagnosticResults.indexWhere((d) => d.id == diagnosticId);
    if (index != -1) {
      _diagnosticResults[index] = _diagnosticResults[index].copyWith(
        isProcessed: true,
      );
      _diagnosticStreamController.add(_diagnosticResults);
    }
  }

  /// Supprimer un diagnostic
  void removeDiagnostic(String diagnosticId) {
    _diagnosticResults.removeWhere((d) => d.id == diagnosticId);
    _diagnosticStreamController.add(_diagnosticResults);
  }

  /// Obtenir les diagnostics non traités (pour les recommandations)
  List<DiagnosticResult> get unprocessedDiagnostics =>
      _diagnosticResults.where((d) => !d.isProcessed).toList();

  /// Obtenir les diagnostics avec problèmes (maladies détectées)
  List<DiagnosticResult> get problemDiagnostics =>
      _diagnosticResults.where((d) => !d.diagnostic.isHealthy).toList();

  /// Effacer tous les diagnostics
  void clearAll() {
    _diagnosticResults.clear();
    _diagnosticStreamController.add(_diagnosticResults);
  }

  /// Libérer les ressources
  void dispose() {
    _diagnosticStreamController.close();
  }
}

/// Classe représentant un résultat de diagnostic enregistré
class DiagnosticResult {
  final String id;
  final DiagnosticModel diagnostic;
  final String parcelleId;
  final String parcelleNom;
  final DateTime dateCreation;
  final bool isProcessed;

  const DiagnosticResult({
    required this.id,
    required this.diagnostic,
    required this.parcelleId,
    required this.parcelleNom,
    required this.dateCreation,
    this.isProcessed = false,
  });

  DiagnosticResult copyWith({
    String? id,
    DiagnosticModel? diagnostic,
    String? parcelleId,
    String? parcelleNom,
    DateTime? dateCreation,
    bool? isProcessed,
  }) {
    return DiagnosticResult(
      id: id ?? this.id,
      diagnostic: diagnostic ?? this.diagnostic,
      parcelleId: parcelleId ?? this.parcelleId,
      parcelleNom: parcelleNom ?? this.parcelleNom,
      dateCreation: dateCreation ?? this.dateCreation,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}
