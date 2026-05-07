import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

abstract class ParcelleRepository {
  Future<List<Parcelle>> getParcelles();
  Future<Parcelle> getParcelleById(String id);
  Future<void> createParcelle(Map<String, dynamic> data);
}
