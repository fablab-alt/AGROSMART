import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_stocks.dart';
import '../../domain/usecases/create_stock.dart';
import '../../domain/usecases/add_mouvement.dart';
import '../../domain/repositories/stock_repository.dart';
import 'stock_event.dart';
import 'stock_state.dart';
import '../../data/models/stock_model.dart';

/// BLoC pour gérer l'état des stocks
class StockBloc extends Bloc<StockEvent, StockState> {
  final GetStocks getStocksUseCase;
  final CreateStock createStockUseCase;
  final AddMouvement addMouvementUseCase;
  final StockRepository repository;

  StockBloc({
    required this.getStocksUseCase,
    required this.createStockUseCase,
    required this.addMouvementUseCase,
    required this.repository,
  }) : super(StockInitial()) {
    on<LoadStocks>(_onLoadStocks);
    on<LoadStockDetail>(_onLoadStockDetail);
    on<CreateNewStock>(_onCreateNewStock);
    on<AddStockMouvement>(_onAddStockMouvement);
    on<MarkAlerteAsRead>(_onMarkAlerteAsRead);
    on<DeleteStockEvent>(_onDeleteStock);
    on<LoadStockStatistics>(_onLoadStatistics);
    on<RefreshStocks>(_onRefreshStocks);
  }

  Future<void> _onLoadStocks(LoadStocks event, Emitter<StockState> emit) async {
    emit(StockLoading());

    final result = await getStocksUseCase(
      GetStocksParams(
        categorie: event.categorie,
        parcelleId: event.parcelleId,
        estActif: event.estActif,
      ),
    );

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (stocks) => emit(StocksLoaded(stocks)),
    );
  }

  Future<void> _onLoadStockDetail(LoadStockDetail event, Emitter<StockState> emit) async {
    emit(StockLoading());

    final stockResult = await repository.getStockById(event.stockId);
    
    stockResult.fold(
      (failure) => emit(StockError(failure.message)),
      (stock) async {
        // Charger aussi les alertes
        final alertesResult = await repository.getAlertes(event.stockId);
        
        alertesResult.fold(
          (failure) => emit(StockDetailLoaded(stock)),
          (alertes) => emit(StockDetailLoaded(stock, alertes: alertes)),
        );
      },
    );
  }

  Future<void> _onCreateNewStock(CreateNewStock event, Emitter<StockState> emit) async {
    emit(StockLoading());

    final result = await createStockUseCase(
      CreateStockParams(
        nom: event.nom,
        categorie: event.categorie,
        type: event.type,
        quantite: event.quantite,
        unite: event.unite,
        seuilAlerte: event.seuilAlerte,
        parcelleId: event.parcelleId,
        prixUnitaire: event.prixUnitaire,
        dateAchat: event.dateAchat,
        dateExpiration: event.dateExpiration,
        fournisseur: event.fournisseur,
        localisation: event.localisation,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (stock) => emit(StockCreated(stock)),
    );
  }

  Future<void> _onAddStockMouvement(AddStockMouvement event, Emitter<StockState> emit) async {
    emit(StockLoading());

    final result = await addMouvementUseCase(
      AddMouvementParams(
        stockId: event.stockId,
        typeMouvement: event.typeMouvement,
        quantite: event.quantite,
        motif: event.motif,
        reference: event.reference,
      ),
    );

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (data) {
        final stock = StockModel.fromJson(data['stock'] as Map<String, dynamic>);
        final mouvement = MouvementStockModel.fromJson(data['mouvement'] as Map<String, dynamic>);
        emit(MouvementAdded(stock, mouvement));
      },
    );
  }

  Future<void> _onMarkAlerteAsRead(MarkAlerteAsRead event, Emitter<StockState> emit) async {
    final result = await repository.marquerAlerteLue(event.stockId, event.alerteId);

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (alerte) => emit(AlerteMarkedAsRead(alerte)),
    );
  }

  Future<void> _onDeleteStock(DeleteStockEvent event, Emitter<StockState> emit) async {
    emit(StockLoading());

    final result = await repository.deleteStock(event.stockId);

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (_) => emit(StockDeleted()),
    );
  }

  Future<void> _onLoadStatistics(LoadStockStatistics event, Emitter<StockState> emit) async {
    final result = await repository.getStatistiques();

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (stats) => emit(StockStatisticsLoaded(stats)),
    );
  }

  Future<void> _onRefreshStocks(RefreshStocks event, Emitter<StockState> emit) async {
    // Recharger les stocks sans passer par l'état loading
    final result = await getStocksUseCase(const GetStocksParams());

    result.fold(
      (failure) => emit(StockError(failure.message)),
      (stocks) => emit(StocksLoaded(stocks)),
    );
  }
}
