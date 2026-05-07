import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/create_product.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final GetProducts getProducts;
  final CreateProduct createProduct;

  MarketplaceBloc({required this.getProducts, required this.createProduct})
    : super(MarketplaceInitial()) {
    on<LoadMarketplaceProducts>(_onLoadProducts);
    on<AddMarketplaceProduct>(_onAddProduct);
  }

  Future<void> _onLoadProducts(
    LoadMarketplaceProducts event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final failureOrProducts = await getProducts(1);

      failureOrProducts.fold(
        (failure) =>
            emit(MarketplaceError(message: _mapFailureToMessage(failure))),
        (products) => emit(MarketplaceLoaded(products: products)),
      );
    } catch (e) {
      emit(
        const MarketplaceError(message: "Une erreur inattendue est survenue."),
      );
    }
  }

  Future<void> _onAddProduct(
    AddMarketplaceProduct event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    final failureOrProduct = await createProduct(
      CreateProductParams(data: event.data, images: event.images),
    );

    failureOrProduct.fold(
      (failure) =>
          emit(MarketplaceError(message: _mapFailureToMessage(failure))),
      (product) {
        // Reload products or emit success
        add(LoadMarketplaceProducts());
      },
    );
  }

  String _mapFailureToMessage(dynamic failure) {
    // Basic error mapping
    return "Une erreur est survenue lors du chargement des produits.";
  }
}
