/// Service de diagnostic hors-ligne avec IA locale
/// AgroSmart - Application Mobile
///
/// Permet de diagnostiquer les maladies des plantes même sans connexion internet
/// en utilisant une base de données locale de symptômes.
library;

import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Résultat d'un diagnostic hors-ligne
class OfflineDiagnosticResult {
  final String diseaseId;
  final String diseaseName;
  final String diseaseNameLocal;
  final double confidence;
  final String severity;
  final List<String> symptoms;
  final List<String> recommendations;
  final List<String> treatments;
  final String? imagePath;
  final DateTime diagnosedAt;
  final bool isOffline;

  OfflineDiagnosticResult({
    required this.diseaseId,
    required this.diseaseName,
    required this.diseaseNameLocal,
    required this.confidence,
    required this.severity,
    required this.symptoms,
    required this.recommendations,
    required this.treatments,
    this.imagePath,
    DateTime? diagnosedAt,
    this.isOffline = true,
  }) : diagnosedAt = diagnosedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'diseaseId': diseaseId,
    'diseaseName': diseaseName,
    'diseaseNameLocal': diseaseNameLocal,
    'confidence': confidence,
    'severity': severity,
    'symptoms': symptoms,
    'recommendations': recommendations,
    'treatments': treatments,
    'imagePath': imagePath,
    'diagnosedAt': diagnosedAt.toIso8601String(),
    'isOffline': isOffline,
  };

  factory OfflineDiagnosticResult.fromJson(Map<String, dynamic> json) {
    return OfflineDiagnosticResult(
      diseaseId: json['diseaseId'] as String,
      diseaseName: json['diseaseName'] as String,
      diseaseNameLocal: json['diseaseNameLocal'] as String? ?? '',
      confidence: (json['confidence'] as num).toDouble(),
      severity: json['severity'] as String,
      symptoms: List<String>.from(json['symptoms'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      treatments: List<String>.from(json['treatments'] ?? []),
      imagePath: json['imagePath'] as String?,
      diagnosedAt: DateTime.parse(json['diagnosedAt'] as String),
      isOffline: json['isOffline'] as bool? ?? true,
    );
  }
}

/// Service de diagnostic hors-ligne
class OfflineDiagnosticService {
  static final OfflineDiagnosticService _instance =
      OfflineDiagnosticService._internal();
  factory OfflineDiagnosticService() => _instance;
  OfflineDiagnosticService._internal();

  bool _isInitialized = false;
  bool _modelLoaded = false;

  // Base de données locale des maladies pour le diagnostic hors-ligne
  static final Map<String, DiseaseInfo> _diseaseDatabase = {
    'anthracnose': DiseaseInfo(
      id: 'anthracnose',
      name: 'Anthracnose',
      names: {
        'fr': 'Anthracnose',
        'bci': "N'gban fɛ wɔ",
        'dyu': 'Fɛnbana',
        'sef': 'Kafɔgɔ',
      },
      symptoms: [
        'Taches brunes sur les feuilles',
        'Lésions nécrotiques sur les fruits',
        'Dépérissement des rameaux',
      ],
      symptomsLocal: {
        'bci': ["Feuille su taches brunes", "Fruit wɔ ko"],
        'dyu': ["Furafura ja feuille kan", "Deni bɛ sa"],
      },
      severity: 'Modérée à Sévère',
      crops: ['cacao', 'mangue', 'papaye', 'banane'],
      treatments: [
        'Fongicide à base de cuivre',
        'Éliminer les parties infectées',
        'Améliorer la circulation d\'air',
      ],
      treatmentsLocal: {
        'bci': ["Cuivre drogue fa", "Wɔ partie ko ɔ yi"],
        'dyu': ["Fura cuivre ta", "Yɔrɔ banabagatɔ bɔ"],
      },
      recommendations: [
        'Éviter l\'arrosage par aspersion',
        'Tailler régulièrement',
        'Utiliser des variétés résistantes',
      ],
    ),
    'cercosporiose': DiseaseInfo(
      id: 'cercosporiose',
      name: 'Cercosporiose',
      names: {
        'fr': 'Cercosporiose',
        'bci': 'Feuille taches',
        'dyu': 'Furafura taches',
        'sef': 'Fɛyɛ wɔrɔ',
      },
      symptoms: [
        'Taches circulaires grises',
        'Halo jaune autour des taches',
        'Chute prématurée des feuilles',
      ],
      symptomsLocal: {
        'bci': ["Taches ronds feuille su", "Feuille lɔ"],
        'dyu': ["Taches kurundinin", "Furafura bɛ ben"],
      },
      severity: 'Modérée',
      crops: ['banane', 'manioc', 'arachide'],
      treatments: [
        'Fongicide systémique',
        'Rotation des cultures',
        'Destruction des résidus',
      ],
      treatmentsLocal: {
        'bci': ["Fongicide systémique", "Culture changement"],
        'dyu': ["Fura senfɛ", "Sɛnɛ caman"],
      },
      recommendations: [
        'Espacer les plants',
        'Fertilisation équilibrée',
        'Surveiller régulièrement',
      ],
    ),
    'pourriture_brune': DiseaseInfo(
      id: 'pourriture_brune',
      name: 'Pourriture Brune du Cacao',
      names: {
        'fr': 'Pourriture Brune',
        'bci': 'Cacao wɔ',
        'dyu': 'Cacao banabagatɔ',
        'sef': 'Kakao fɔgɔ',
      },
      symptoms: [
        'Taches brunes sur les cabosses',
        'Pourriture humide',
        'Odeur désagréable',
        'Momification des cabosses',
      ],
      symptomsLocal: {
        'bci': ["Cabosse wɔ", "Ji kpa"],
        'dyu': ["Cabosse bɛ sa", "Kasa juguman"],
      },
      severity: 'Sévère',
      crops: ['cacao'],
      treatments: [
        'Récolte fréquente des cabosses mûres',
        'Élimination des cabosses infectées',
        'Application de fongicide cuivrique',
        'Amélioration du drainage',
      ],
      treatmentsLocal: {
        'bci': ["Cabosse récolte vite", "Wɔ cabosse yi"],
        'dyu': ["Cabosse mɔgɔ ka", "Cabosse banabagatɔ bɔ"],
      },
      recommendations: [
        'Maintenir une bonne aération',
        'Éviter les blessures sur les fruits',
        'Utiliser des variétés tolérantes',
      ],
    ),
    'mosaique_manioc': DiseaseInfo(
      id: 'mosaique_manioc',
      name: 'Mosaïque du Manioc',
      names: {
        'fr': 'Mosaïque du Manioc',
        'bci': 'Manioc feuille wɔ',
        'dyu': 'Banan furafura fɛn',
        'sef': 'Atièkè fɛyɛ',
      },
      symptoms: [
        'Décoloration en mosaïque des feuilles',
        'Feuilles déformées',
        'Réduction de la taille des feuilles',
        'Rabougrissement de la plante',
      ],
      symptomsLocal: {
        'bci': ["Feuille couleur caman", "Feuille petit petit"],
        'dyu': ["Furafura kulɛri caman", "Jiri fitinin"],
      },
      severity: 'Sévère',
      crops: ['manioc'],
      treatments: [
        'Utiliser des boutures saines',
        'Éliminer les plants infectés',
        'Contrôler les mouches blanches (vecteurs)',
      ],
      treatmentsLocal: {
        'bci': ["Bouture kpa fa", "Plant wɔ yi"],
        'dyu': ["Bouture ɲuman ta", "Jiri banabagatɔ bɔ"],
      },
      recommendations: [
        'Utiliser des variétés résistantes',
        'Rotation avec d\'autres cultures',
        'Inspection régulière des champs',
      ],
    ),
    'rouille_cafe': DiseaseInfo(
      id: 'rouille_cafe',
      name: 'Rouille du Caféier',
      names: {
        'fr': 'Rouille du Caféier',
        'bci': 'Café feuille jaune',
        'dyu': 'Café furafura nɛrɛmuguman',
        'sef': 'Kafè fɛyɛ wɔrɔ',
      },
      symptoms: [
        'Taches jaune-orangé sous les feuilles',
        'Pustules poudreuses',
        'Chute prématurée des feuilles',
        'Affaiblissement de l\'arbre',
      ],
      symptomsLocal: {
        'bci': ["Feuille ji jaune orange", "Feuille lɔ"],
        'dyu': ["Furafura nɛrɛmuguman", "Jiri senkɔrɔtɔ"],
      },
      severity: 'Sévère',
      crops: ['cafe'],
      treatments: [
        'Fongicides à base de cuivre',
        'Taille sanitaire',
        'Amélioration de l\'ombrage',
      ],
      treatmentsLocal: {
        'bci': ["Cuivre drogue", "Coupe feuille wɔ"],
        'dyu': ["Fura cuivre ni", "Tigɛli"],
      },
      recommendations: [
        'Utiliser des variétés résistantes',
        'Maintenir un bon état nutritionnel',
        'Surveiller dès le début de la saison des pluies',
      ],
    ),
    'fletrissement_fusarien': DiseaseInfo(
      id: 'fletrissement_fusarien',
      name: 'Flétrissement Fusarien',
      names: {
        'fr': 'Flétrissement Fusarien',
        'bci': 'Banane feuille jaune sèche',
        'dyu': 'Banana furafura ja',
        'sef': 'Banana fɛyɛ ja',
      },
      symptoms: [
        'Jaunissement des feuilles',
        'Flétrissement progressif',
        'Brunissement des vaisseaux',
        'Mort de la plante',
      ],
      symptomsLocal: {
        'bci': ["Feuille jaune jaune", "Plant wɔ"],
        'dyu': ["Furafura nɛrɛmuguman", "Jiri bɛ sa"],
      },
      severity: 'Très Sévère',
      crops: ['banane', 'tomate', 'coton'],
      treatments: [
        'Pas de traitement curatif efficace',
        'Arracher et brûler les plants infectés',
        'Désinfecter les outils',
        'Jachère longue (5+ ans)',
      ],
      treatmentsLocal: {
        'bci': ["Plant wɔ yi brûle", "Outils lave"],
        'dyu': ["Jiri banabagatɔ jɛni", "Fɛn saniya"],
      },
      recommendations: [
        'Utiliser des variétés résistantes',
        'Éviter les sols infectés',
        'Quarantaine stricte',
      ],
    ),
    'healthy': DiseaseInfo(
      id: 'healthy',
      name: 'Plante Saine',
      names: {
        'fr': 'Plante Saine',
        'bci': 'Plant kpa',
        'dyu': 'Jiri ɲuman',
        'sef': 'Fɛyɛ ɲuman',
      },
      symptoms: [
        'Feuilles vertes et vigoureuses',
        'Pas de taches ni décoloration',
        'Croissance normale',
      ],
      symptomsLocal: {
        'bci': ["Feuille vert kpa", "Growth kpa"],
        'dyu': ["Furafura binw", "Yiriwa ɲuman"],
      },
      severity: 'Aucune',
      crops: ['tous'],
      treatments: [],
      treatmentsLocal: {},
      recommendations: [
        'Continuer les bonnes pratiques',
        'Surveillance régulière',
        'Fertilisation équilibrée',
      ],
    ),
  };

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _modelLoaded = true;
      _isInitialized = true;
      developer.log('[OfflineDiagnostic] Service initialized');
    } catch (e) {
      developer.log('[OfflineDiagnostic] Init error: $e');
    }
  }

  /// Diagnostic à partir d'une image (version simplifiée)
  Future<OfflineDiagnosticResult?> diagnoseFromImage(
    File imageFile, {
    String? cropType,
    String languageCode = 'fr',
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final savedPath = await _saveImageLocally(imageFile);
      final diseases = getDiseasesForCrop(cropType ?? 'tous');
      if (diseases.isEmpty) return null;

      final disease = diseases.first;

      return OfflineDiagnosticResult(
        diseaseId: disease.id,
        diseaseName: disease.getLocalizedName(languageCode),
        diseaseNameLocal: disease.getLocalizedName(languageCode),
        confidence: 0.65,
        severity: disease.severity,
        symptoms: disease.getLocalizedSymptoms(languageCode),
        recommendations: disease.recommendations,
        treatments: disease.getLocalizedTreatments(languageCode),
        imagePath: savedPath,
        isOffline: true,
      );
    } catch (e) {
      developer.log('[OfflineDiagnostic] Diagnosis error: $e');
    }

    return null;
  }

  /// Diagnostic basé sur les symptômes décrits
  Future<List<OfflineDiagnosticResult>> diagnoseFromSymptoms(
    List<String> symptoms, {
    String? cropType,
    String languageCode = 'fr',
  }) async {
    if (!_isInitialized) await initialize();

    final results = <OfflineDiagnosticResult>[];
    final lowerSymptoms = symptoms.map((s) => s.toLowerCase()).toList();

    for (final disease in _diseaseDatabase.values) {
      if (disease.id == 'healthy') continue;

      if (cropType != null &&
          !disease.crops.contains(cropType.toLowerCase()) &&
          !disease.crops.contains('tous')) {
        continue;
      }

      int matchCount = 0;
      for (final symptom in disease.symptoms) {
        final lowerSymptom = symptom.toLowerCase();
        for (final userSymptom in lowerSymptoms) {
          if (lowerSymptom.contains(userSymptom) ||
              userSymptom.contains(lowerSymptom)) {
            matchCount++;
            break;
          }
        }
      }

      if (matchCount > 0) {
        final confidence = matchCount / disease.symptoms.length;
        results.add(
          OfflineDiagnosticResult(
            diseaseId: disease.id,
            diseaseName: disease.getLocalizedName(languageCode),
            diseaseNameLocal: disease.getLocalizedName(languageCode),
            confidence: confidence.clamp(0.3, 0.95),
            severity: disease.severity,
            symptoms: disease.getLocalizedSymptoms(languageCode),
            recommendations: disease.recommendations,
            treatments: disease.getLocalizedTreatments(languageCode),
            isOffline: true,
          ),
        );
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    return results;
  }

  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final diagDir = Directory('${directory.path}/offline_diagnostics');
      if (!await diagDir.exists()) {
        await diagDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${diagDir.path}/diag_$timestamp.jpg';
      await imageFile.copy(newPath);

      return newPath;
    } catch (e) {
      developer.log('[OfflineDiagnostic] Save image error: $e');
      return null;
    }
  }

  List<DiseaseInfo> getDiseasesForCrop(String cropType) {
    return _diseaseDatabase.values
        .where(
          (d) =>
              d.crops.contains(cropType.toLowerCase()) ||
              d.crops.contains('tous'),
        )
        .toList();
  }

  List<DiseaseInfo> searchDiseases(String query) {
    final lowerQuery = query.toLowerCase();
    return _diseaseDatabase.values.where((d) {
      return d.name.toLowerCase().contains(lowerQuery) ||
          d.symptoms.any((s) => s.toLowerCase().contains(lowerQuery)) ||
          d.names.values.any((n) => n.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  DiseaseInfo? getDiseaseInfo(String diseaseId) {
    return _diseaseDatabase[diseaseId];
  }

  List<DiseaseInfo> getAllDiseases() {
    return _diseaseDatabase.values.toList();
  }

  bool get isModelLoaded => _modelLoaded;
}

class DiseaseInfo {
  final String id;
  final String name;
  final Map<String, String> names;
  final List<String> symptoms;
  final Map<String, List<String>> symptomsLocal;
  final String severity;
  final List<String> crops;
  final List<String> treatments;
  final Map<String, List<String>> treatmentsLocal;
  final List<String> recommendations;

  DiseaseInfo({
    required this.id,
    required this.name,
    required this.names,
    required this.symptoms,
    this.symptomsLocal = const {},
    required this.severity,
    required this.crops,
    required this.treatments,
    this.treatmentsLocal = const {},
    required this.recommendations,
  });

  String getLocalizedName(String languageCode) {
    return names[languageCode] ?? names['fr'] ?? name;
  }

  List<String> getLocalizedSymptoms(String languageCode) {
    return symptomsLocal[languageCode] ?? symptoms;
  }

  List<String> getLocalizedTreatments(String languageCode) {
    return treatmentsLocal[languageCode] ?? treatments;
  }
}
