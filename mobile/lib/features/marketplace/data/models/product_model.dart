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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return ProductModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      categorie: json['categorie'],
      prix: (json['prix'] is num)
          ? (json['prix'] as num).toDouble()
          : double.tryParse(json['prix'].toString()) ?? 0.0,
      unite: json['unite'],
      quantiteDisponible:
          ((json['quantite_disponible'] ?? json['stock']) is num)
          ? (json['quantite_disponible'] ?? json['stock'] as num).toDouble()
          : double.tryParse(
                  (json['quantite_disponible'] ?? json['stock']).toString(),
                ) ??
                0.0,
      localisation: json['localisation'] ?? json['adresse'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      vendeurId: json['vendeur_id'] ?? json['vendeurId'],
      vendeurNom: json['vendeur_nom'],
      vendeurTelephone: json['vendeur_telephone'],
      createdAt: createdAtValue != null
          ? DateTime.parse(createdAtValue.toString())
          : DateTime.now(),
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
    };
  }
}
