import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.nom,
    super.description,
    required super.categorie,
    required super.prix,
    super.unite,
    required super.quantiteDisponible,
    super.localisation,
    required super.images,
    required super.vendeurId,
    super.vendeurNom,
    super.vendeurTelephone,
    required super.createdAt,
    super.typeOffre,
    super.prixLocationJour,
    super.dureeMinLocation,
    super.caution,
    super.etat,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return ProductModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      categorie: json['categorie'],
      prix: _toDouble(json['prix']) ?? 0.0,
      unite: json['unite'],
      quantiteDisponible:
          _toDouble(json['quantite_disponible'] ?? json['stock']) ?? 0.0,
      localisation: json['localisation'] ?? json['adresse'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      vendeurId: json['vendeur_id'] ?? json['vendeurId'],
      vendeurNom: json['vendeur_nom'],
      vendeurTelephone: json['vendeur_telephone'],
      createdAt: createdAtValue != null
          ? DateTime.parse(createdAtValue.toString())
          : DateTime.now(),
      typeOffre: (json['type_offre'] ?? json['typeOffre'] ?? 'vente').toString(),
      prixLocationJour: _toDouble(json['prix_location_jour'] ?? json['prixLocationJour']),
      dureeMinLocation: _toInt(json['duree_min_location'] ?? json['dureeMinLocation']),
      caution: _toDouble(json['caution']),
      etat: json['etat']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'prix': prix,
      'unite': unite,
      'quantite_disponible': quantiteDisponible,
      'localisation': localisation,
      'images': images,
      'vendeur_id': vendeurId,
      'vendeur_nom': vendeurNom,
      'vendeur_telephone': vendeurTelephone,
      'created_at': createdAt.toIso8601String(),
      'type_offre': typeOffre,
      if (prixLocationJour != null) 'prix_location_jour': prixLocationJour,
      if (dureeMinLocation != null) 'duree_min_location': dureeMinLocation,
      if (caution != null) 'caution': caution,
      if (etat != null) 'etat': etat,
    };
  }
}
