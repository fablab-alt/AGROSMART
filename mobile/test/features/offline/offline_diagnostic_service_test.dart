/// Tests pour le service de diagnostic hors-ligne
/// AgriSmart CI - Application Mobile
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:agriculture/features/offline/services/offline_diagnostic_service.dart';

void main() {
  late OfflineDiagnosticService diagnosticService;

  setUp(() {
    diagnosticService = OfflineDiagnosticService();
  });

  group('OfflineDiagnosticService', () {
    test('should initialize successfully', () async {
      await diagnosticService.initialize();
      expect(diagnosticService.isModelLoaded, true);
    });

    test('should return all diseases', () {
      final diseases = diagnosticService.getAllDiseases();
      expect(diseases.isNotEmpty, true);
      expect(diseases.length, greaterThanOrEqualTo(6));
    });

    test('should return disease by id', () {
      final disease = diagnosticService.getDiseaseInfo('anthracnose');
      expect(disease, isNotNull);
      expect(disease!.name, 'Anthracnose');
    });

    test('should return null for unknown disease', () {
      final disease = diagnosticService.getDiseaseInfo('unknown_disease');
      expect(disease, isNull);
    });

    test('should return diseases for crop type', () {
      final cacaoDiseases = diagnosticService.getDiseasesForCrop('cacao');
      expect(cacaoDiseases.isNotEmpty, true);

      // Anthracnose et pourriture brune affectent le cacao
      expect(cacaoDiseases.any((d) => d.id == 'anthracnose'), true);
      expect(cacaoDiseases.any((d) => d.id == 'pourriture_brune'), true);
    });

    test('should search diseases by name', () {
      final results = diagnosticService.searchDiseases('rouille');
      expect(results.isNotEmpty, true);
      expect(results.first.id, 'rouille_cafe');
    });

    test('should search diseases by symptom', () {
      final results = diagnosticService.searchDiseases('taches brunes');
      expect(results.isNotEmpty, true);
    });

    test('DiseaseInfo should return localized name', () {
      final disease = diagnosticService.getDiseaseInfo('anthracnose')!;

      expect(disease.getLocalizedName('fr'), 'Anthracnose');
      expect(disease.getLocalizedName('bci'), "N'gban fɛ wɔ");
      expect(disease.getLocalizedName('dyu'), 'Fɛnbana');
      // Fallback to French for unknown language
      expect(disease.getLocalizedName('xx'), 'Anthracnose');
    });

    test('DiseaseInfo should return localized symptoms', () {
      final disease = diagnosticService.getDiseaseInfo('anthracnose')!;

      final symptomsFr = disease.getLocalizedSymptoms('fr');
      expect(symptomsFr.isNotEmpty, true);

      final symptomsBci = disease.getLocalizedSymptoms('bci');
      expect(symptomsBci.isNotEmpty, true);
    });

    test('DiseaseInfo should return localized treatments', () {
      final disease = diagnosticService.getDiseaseInfo('anthracnose')!;

      final treatmentsFr = disease.getLocalizedTreatments('fr');
      expect(treatmentsFr.isNotEmpty, true);

      final treatmentsBci = disease.getLocalizedTreatments('bci');
      expect(treatmentsBci.isNotEmpty, true);
    });

    test('healthy plant should have no treatments', () {
      final healthy = diagnosticService.getDiseaseInfo('healthy')!;
      expect(healthy.treatments.isEmpty, true);
      expect(healthy.severity, 'Aucune');
    });

    test('OfflineDiagnosticResult should serialize to JSON', () {
      final result = OfflineDiagnosticResult(
        diseaseId: 'anthracnose',
        diseaseName: 'Anthracnose',
        diseaseNameLocal: "N'gban fɛ wɔ",
        confidence: 0.85,
        severity: 'Modérée à Sévère',
        symptoms: ['Taches brunes'],
        recommendations: ['Éviter l\'arrosage'],
        treatments: ['Fongicide cuivre'],
        imagePath: '/path/to/image.jpg',
        isOffline: true,
      );

      final json = result.toJson();

      expect(json['diseaseId'], 'anthracnose');
      expect(json['confidence'], 0.85);
      expect(json['isOffline'], true);
    });

    test('OfflineDiagnosticResult should deserialize from JSON', () {
      final json = {
        'diseaseId': 'anthracnose',
        'diseaseName': 'Anthracnose',
        'diseaseNameLocal': "N'gban fɛ wɔ",
        'confidence': 0.85,
        'severity': 'Modérée à Sévère',
        'symptoms': ['Taches brunes'],
        'recommendations': ['Éviter l\'arrosage'],
        'treatments': ['Fongicide cuivre'],
        'imagePath': '/path/to/image.jpg',
        'diagnosedAt': '2025-01-25T10:00:00.000',
        'isOffline': true,
      };

      final result = OfflineDiagnosticResult.fromJson(json);

      expect(result.diseaseId, 'anthracnose');
      expect(result.confidence, 0.85);
      expect(result.isOffline, true);
      expect(result.symptoms.first, 'Taches brunes');
    });

    test('diseases should have crops list', () {
      final diseases = diagnosticService.getAllDiseases();

      for (final disease in diseases) {
        expect(disease.crops.isNotEmpty, true);
      }
    });

    test('diseases should have recommendations', () {
      final diseases = diagnosticService.getAllDiseases();

      for (final disease in diseases) {
        if (disease.id != 'healthy') {
          expect(disease.recommendations.isNotEmpty, true);
        }
      }
    });
  });
}
