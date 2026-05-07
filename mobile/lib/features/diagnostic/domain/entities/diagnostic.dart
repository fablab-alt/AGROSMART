import 'package:equatable/equatable.dart';

class Diagnostic extends Equatable {
  final String id;
  final String diseaseName;
  final String cropType;
  final double confidenceScore;
  final String severity;
  final String imageUrl;
  final String recommendations;
  final String treatmentSuggestions;
  final DateTime createdAt;

  const Diagnostic({
    required this.id,
    required this.diseaseName,
    required this.cropType,
    required this.confidenceScore,
    required this.severity,
    required this.imageUrl,
    required this.recommendations,
    required this.treatmentSuggestions,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        diseaseName,
        cropType,
        confidenceScore,
        severity,
        imageUrl,
        recommendations,
        treatmentSuggestions,
        createdAt,
      ];
}
