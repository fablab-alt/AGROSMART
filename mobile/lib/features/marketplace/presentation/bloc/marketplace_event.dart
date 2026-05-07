

part of 'marketplace_bloc.dart';

abstract class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();

  @override
  List<Object> get props => [];
}

class LoadMarketplaceProducts extends MarketplaceEvent {}

class AddMarketplaceProduct extends MarketplaceEvent {
  final Map<String, dynamic> data;
  final List<File> images; // Changed from dynamic to File
  
  const AddMarketplaceProduct({required this.data, required this.images});

  @override
  List<Object> get props => [data, images];
}
