import 'package:agriculture/features/parcelles/data/datasources/parcelle_remote_data_source.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:agriculture/features/parcelles/domain/repositories/parcelle_repository.dart';

class ParcelleRepositoryImpl implements ParcelleRepository {
  final ParcelleRemoteDataSource remoteDataSource;

  ParcelleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Parcelle>> getParcelles() async {
    return await remoteDataSource.getParcelles();
  }

  @override
  Future<Parcelle> getParcelleById(String id) async {
    // Basic implementation filtering from list or separate call
    // For now simple placeholder
    throw UnimplementedError(); 
  }

  @override
  Future<void> createParcelle(Map<String, dynamic> data) async {
    await remoteDataSource.createParcelle(data);
  }
}
