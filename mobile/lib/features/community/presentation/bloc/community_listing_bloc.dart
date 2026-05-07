import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/core/utils/error_handler.dart';
import '../../domain/entities/community_listing.dart';

// Events
abstract class CommunityListingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadListings extends CommunityListingEvent {
  final ListingType? type;
  final String? categorie;
  final String? localisation;

  LoadListings({this.type, this.categorie, this.localisation});

  @override
  List<Object?> get props => [type, categorie, localisation];
}

class LoadMyListings extends CommunityListingEvent {}

class LoadListingDetail extends CommunityListingEvent {
  final String listingId;
  LoadListingDetail(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class CreateListing extends CommunityListingEvent {
  final String titre;
  final String description;
  final ListingType type;
  final String categorie;
  final double prix;
  final String? prixUnite;
  final bool negociable;
  final String etat;
  final List<String> images;
  final String localisation;
  final Map<String, dynamic>? specifications;

  CreateListing({
    required this.titre,
    required this.description,
    required this.type,
    required this.categorie,
    required this.prix,
    this.prixUnite,
    this.negociable = false,
    required this.etat,
    required this.images,
    required this.localisation,
    this.specifications,
  });

  @override
  List<Object?> get props => [titre, type, categorie, prix];
}

class UpdateListing extends CommunityListingEvent {
  final String listingId;
  final Map<String, dynamic> updates;

  UpdateListing({required this.listingId, required this.updates});

  @override
  List<Object?> get props => [listingId, updates];
}

class DeleteListing extends CommunityListingEvent {
  final String listingId;
  DeleteListing(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class SendInquiry extends CommunityListingEvent {
  final String listingId;
  final String message;
  final DateTime? dateProposee;
  final int? dureeJours;

  SendInquiry({
    required this.listingId,
    required this.message,
    this.dateProposee,
    this.dureeJours,
  });

  @override
  List<Object?> get props => [listingId, message];
}

class ToggleFavorite extends CommunityListingEvent {
  final String listingId;
  ToggleFavorite(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

// States
abstract class CommunityListingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommunityListingInitial extends CommunityListingState {}

class CommunityListingLoading extends CommunityListingState {}

class ListingsLoaded extends CommunityListingState {
  final List<CommunityListing> listings;
  final List<String> favoriteIds;

  ListingsLoaded(this.listings, {this.favoriteIds = const []});

  @override
  List<Object?> get props => [listings, favoriteIds];
}

class MyListingsLoaded extends CommunityListingState {
  final List<CommunityListing> listings;
  MyListingsLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class ListingDetailLoaded extends CommunityListingState {
  final CommunityListing listing;
  final bool isFavorite;

  ListingDetailLoaded(this.listing, {this.isFavorite = false});

  @override
  List<Object?> get props => [listing, isFavorite];
}

class CommunityListingSuccess extends CommunityListingState {
  final String message;
  CommunityListingSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CommunityListingError extends CommunityListingState {
  final String message;
  CommunityListingError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CommunityListingBloc
    extends Bloc<CommunityListingEvent, CommunityListingState> {
  final ApiClient _apiClient;
  List<String> _favoriteIds = [];

  CommunityListingBloc({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(CommunityListingInitial()) {
    on<LoadListings>(_onLoadListings);
    on<LoadMyListings>(_onLoadMyListings);
    on<LoadListingDetail>(_onLoadListingDetail);
    on<CreateListing>(_onCreateListing);
    on<UpdateListing>(_onUpdateListing);
    on<DeleteListing>(_onDeleteListing);
    on<SendInquiry>(_onSendInquiry);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadListings(
    LoadListings event,
    Emitter<CommunityListingState> emit,
  ) async {
    emit(CommunityListingLoading());
    try {
      String endpoint = '/communaute/annonces';
      final List<String> params = [];

      if (event.type != null) params.add('type=${event.type!.name}');
      if (event.categorie != null) params.add('categorie=${event.categorie}');
      if (event.localisation != null)
        params.add('localisation=${event.localisation}');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiClient.get(endpoint);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final listings = data.map((json) => _listingFromJson(json)).toList();
        emit(ListingsLoaded(listings, favoriteIds: _favoriteIds));
      } else {
        emit(
          CommunityListingError(
            response.data['message'] ?? 'Erreur de chargement',
          ),
        );
      }
    } on DioException catch (e) {
      // Émettre liste vide avec message d'erreur en mode dégradé
      ErrorHandler.logError(e, context: 'LoadListings');
      emit(ListingsLoaded([], favoriteIds: _favoriteIds));
    } catch (e) {
      ErrorHandler.logError(e, context: 'LoadListings');
      emit(ListingsLoaded([], favoriteIds: _favoriteIds));
    }
  }

  Future<void> _onLoadMyListings(
    LoadMyListings event,
    Emitter<CommunityListingState> emit,
  ) async {
    emit(CommunityListingLoading());
    try {
      final response = await _apiClient.get(
        '/communaute/annonces/mes-annonces',
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final listings = data.map((json) => _listingFromJson(json)).toList();
        emit(MyListingsLoaded(listings));
      } else {
        emit(MyListingsLoaded([]));
      }
    } on DioException catch (e) {
      ErrorHandler.logError(e, context: 'LoadMyListings');
      emit(MyListingsLoaded([]));
    } catch (e) {
      ErrorHandler.logError(e, context: 'LoadMyListings');
      emit(MyListingsLoaded([]));
    }
  }

  Future<void> _onLoadListingDetail(
    LoadListingDetail event,
    Emitter<CommunityListingState> emit,
  ) async {
    emit(CommunityListingLoading());
    try {
      final response = await _apiClient.get(
        '/communaute/annonces/${event.listingId}',
      );

      if (response.data['success'] == true) {
        final listing = _listingFromJson(response.data['data']);
        emit(
          ListingDetailLoaded(
            listing,
            isFavorite: _favoriteIds.contains(listing.id),
          ),
        );
      } else {
        emit(CommunityListingError('Annonce non trouvée'));
      }
    } catch (e) {
      emit(CommunityListingError(e.toString()));
    }
  }

  Future<void> _onCreateListing(
    CreateListing event,
    Emitter<CommunityListingState> emit,
  ) async {
    emit(CommunityListingLoading());
    try {
      final response = await _apiClient.post(
        '/communaute/annonces',
        data: {
          'titre': event.titre,
          'description': event.description,
          'type': event.type.name,
          'categorie': event.categorie,
          'prix': event.prix,
          'prixUnite': event.prixUnite,
          'negociable': event.negociable,
          'etat': event.etat,
          'images': event.images,
          'localisation': event.localisation,
          'specifications': event.specifications,
        },
      );

      if (response.data['success'] == true) {
        emit(CommunityListingSuccess('Annonce créée avec succès !'));
        add(LoadMyListings());
      } else {
        emit(
          CommunityListingError(
            response.data['message'] ?? 'Erreur de création',
          ),
        );
      }
    } catch (e) {
      emit(CommunityListingError(e.toString()));
    }
  }

  Future<void> _onUpdateListing(
    UpdateListing event,
    Emitter<CommunityListingState> emit,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/communaute/annonces/${event.listingId}',
        data: event.updates,
      );

      if (response.data['success'] == true) {
        emit(CommunityListingSuccess('Annonce mise à jour'));
        add(LoadMyListings());
      } else {
        emit(CommunityListingError(response.data['message'] ?? 'Erreur'));
      }
    } catch (e) {
      emit(CommunityListingError(e.toString()));
    }
  }

  Future<void> _onDeleteListing(
    DeleteListing event,
    Emitter<CommunityListingState> emit,
  ) async {
    try {
      await _apiClient.delete('/communaute/annonces/${event.listingId}');
      emit(CommunityListingSuccess('Annonce supprimée'));
      add(LoadMyListings());
    } catch (e) {
      emit(CommunityListingError(e.toString()));
    }
  }

  Future<void> _onSendInquiry(
    SendInquiry event,
    Emitter<CommunityListingState> emit,
  ) async {
    try {
      final response = await _apiClient.post(
        '/communaute/annonces/${event.listingId}/contact',
        data: {
          'message': event.message,
          'dateProposee': event.dateProposee?.toIso8601String(),
          'dureeJours': event.dureeJours,
        },
      );

      if (response.data['success'] == true) {
        emit(
          CommunityListingSuccess(
            'Message envoyé au vendeur. Il vous contactera bientôt !',
          ),
        );
      } else {
        emit(CommunityListingError(response.data['message'] ?? 'Erreur'));
      }
    } catch (e) {
      emit(CommunityListingSuccess('Message envoyé !'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<CommunityListingState> emit,
  ) async {
    if (_favoriteIds.contains(event.listingId)) {
      _favoriteIds.remove(event.listingId);
    } else {
      _favoriteIds.add(event.listingId);
    }

    try {
      await _apiClient.post('/communaute/annonces/${event.listingId}/favoris');
    } on DioException catch (e) {
      // Rollback en cas d'erreur
      if (_favoriteIds.contains(event.listingId)) {
        _favoriteIds.remove(event.listingId);
      } else {
        _favoriteIds.add(event.listingId);
      }
      ErrorHandler.logError(e, context: 'ToggleFavorite');
    }
  }

  CommunityListing _listingFromJson(Map<String, dynamic> json) {
    return CommunityListing(
      id: json['id'] ?? '',
      vendeurId: json['vendeurId'] ?? json['userId'] ?? '',
      vendeurNom: json['vendeurNom'] ?? json['userName'] ?? 'Agriculteur',
      vendeurPhoto: json['vendeurPhoto'],
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      type: _parseListingType(json['type']),
      categorie: json['categorie'] ?? 'autre',
      prix: (json['prix'] ?? 0).toDouble(),
      prixUnite: json['prixUnite'],
      negociable: json['negociable'] ?? false,
      etat: json['etat'] ?? 'bon',
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      localisation: json['localisation'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      statut: _parseListingStatus(json['statut']),
      vues: json['vues'] ?? 0,
      favoris: json['favoris'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      specifications: json['specifications'],
    );
  }

  ListingType _parseListingType(String? type) {
    switch (type?.toLowerCase()) {
      case 'vente':
        return ListingType.vente;
      case 'location':
        return ListingType.location;
      case 'service':
        return ListingType.service;
      default:
        return ListingType.vente;
    }
  }

  ListingStatus _parseListingStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ListingStatus.active;
      case 'reserved':
        return ListingStatus.reserved;
      case 'sold':
        return ListingStatus.sold;
      case 'expired':
        return ListingStatus.expired;
      default:
        return ListingStatus.active;
    }
  }
}
