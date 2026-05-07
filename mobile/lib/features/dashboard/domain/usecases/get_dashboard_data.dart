import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardData implements UseCase<DashboardData, NoParams> {
  final DashboardRepository repository;

  GetDashboardData(this.repository);

  @override
  Future<Either<Failure, DashboardData>> call(NoParams params) async {
    return await repository.getDashboardData();
  }
}
