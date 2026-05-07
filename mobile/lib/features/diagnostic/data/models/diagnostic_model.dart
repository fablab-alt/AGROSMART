import '../../domain/entities/diagnostic.dart';

class DiagnosticModel extends Diagnostic {
  const DiagnosticModel({
    required super.id,
    required super.diseaseName,
    required super.cropType,
    required super.confidenceScore,
    required super.severity,
    required super.imageUrl,
    required super.recommendations,
    required super.treatmentSuggestions,
    required super.createdAt,
  });

  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticModel(
      id: json['id'] as String,
      diseaseName: json['disease_name'] as String,
      cropType: json['crop_type'] as String? ?? 'Inconnu',
      confidenceScore: (json['confidence_score'] is num)
          ? (json['confidence_score'] as num).toDouble()
          : double.tryParse(json['confidence_score']?.toString() ?? '0') ?? 0.0,
      severity: json['severity'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      recommendations: json['recommendations'] as String? ?? '',
      treatmentSuggestions: json['treatment_suggestions'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  bool get isHealthy => diseaseName.toLowerCase().contains('sain') || diseaseName.toLowerCase() == 'healthy';
}
