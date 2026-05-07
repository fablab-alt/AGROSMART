part of 'marketplace_bloc.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  
  @override
  List<Object> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<Product> products;

  const MarketplaceLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class MarketplaceError extends MarketplaceState {
  final String message;

  const MarketplaceError({required this.message});

  @override
  List<Object> get props => [message];
}
