import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/core/network/api_client.dart';
import '../../domain/entities/equipment.dart';

// Events
abstract class EquipmentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEquipments extends EquipmentEvent {
  final String? categorie;
  LoadEquipments({this.categorie});

  @override
  List<Object?> get props => [categorie];
}

class CreateRentalRequest extends EquipmentEvent {
  final String equipmentId;
  final DateTime dateDebut;
  final DateTime dateFin;

  CreateRentalRequest({
    required this.equipmentId,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  List<Object?> get props => [equipmentId, dateDebut, dateFin];
}

class LoadMyRentals extends EquipmentEvent {}

class CancelRental extends EquipmentEvent {
  final String rentalId;
  CancelRental(this.rentalId);

  @override
  List<Object?> get props => [rentalId];
}

// States
abstract class EquipmentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EquipmentInitial extends EquipmentState {}

class EquipmentLoading extends EquipmentState {}

class EquipmentLoaded extends EquipmentState {
  final List<Equipment> equipments;
  EquipmentLoaded(this.equipments);

  @override
  List<Object?> get props => [equipments];
}

class RentalsLoaded extends EquipmentState {
  final List<Rental> rentals;
  RentalsLoaded(this.rentals);

  @override
  List<Object?> get props => [rentals];
}

class RentalRequestSuccess extends EquipmentState {
  final Rental rental;
  RentalRequestSuccess(this.rental);

  @override
  List<Object?> get props => [rental];
}

class EquipmentError extends EquipmentState {
  final String message;
  EquipmentError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EquipmentBloc extends Bloc<EquipmentEvent, EquipmentState> {
  final ApiClient _apiClient;

  EquipmentBloc({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(EquipmentInitial()) {
    on<LoadEquipments>(_onLoadEquipments);
    on<CreateRentalRequest>(_onCreateRentalRequest);
    on<LoadMyRentals>(_onLoadMyRentals);
    on<CancelRental>(_onCancelRental);
  }

  Future<void> _onLoadEquipments(
    LoadEquipments event,
    Emitter<EquipmentState> emit,
  ) async {
    emit(EquipmentLoading());
    try {
      String endpoint = '/equipements';
      if (event.categorie != null) {
        endpoint += '?categorie=${event.categorie}';
      }

      final response = await _apiClient.get(endpoint);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final equipments = data
            .map(
              (json) => Equipment(
                id: json['id'] ?? '',
                proprietaireId: json['proprietaireId'] ?? '',
                nom: json['nom'] ?? '',
                categorie: json['categorie'] ?? 'autre',
                description: json['description'] ?? '',
                etat: json['etat'] ?? 'bon',
                disponible: json['disponible'] ?? false,
                prixParJour:
                    (json['prixParJour'] ?? json['prixJournalier'] ?? 0)
                        .toDouble(),
                localisation: json['localisation'],
                images:
                    (json['images'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                createdAt: json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'])
                    : DateTime.now(),
              ),
            )
            .toList();
        emit(EquipmentLoaded(equipments));
      } else {
        emit(
          EquipmentError(response.data['message'] ?? 'Erreur de chargement'),
        );
      }
    } catch (e) {
      emit(EquipmentLoaded([]));
    }
  }

  Future<void> _onCreateRentalRequest(
    CreateRentalRequest event,
    Emitter<EquipmentState> emit,
  ) async {
    emit(EquipmentLoading());
    try {
      final response = await _apiClient.post(
        '/locations',
        data: {
          'equipementId': event.equipmentId,
          'dateDebut': event.dateDebut.toIso8601String(),
          'dateFin': event.dateFin.toIso8601String(),
        },
      );

      if (response.data['success'] == true) {
        final json = response.data['data'];
        final rental = Rental(
          id: json['id'] ?? '',
          equipmentId: json['equipementId'] ?? event.equipmentId,
          locataireId: json['locataireId'] ?? '',
          dateDebut: json['dateDebut'] != null
              ? DateTime.parse(json['dateDebut'])
              : event.dateDebut,
          dateFin: json['dateFin'] != null
              ? DateTime.parse(json['dateFin'])
              : event.dateFin,
          dureeJours:
              json['dureeJours'] ??
              event.dateFin.difference(event.dateDebut).inDays,
          prixTotal: (json['prixTotal'] ?? 0).toDouble(),
          statut: json['statut'] ?? 'demande',
          createdAt: DateTime.now(),
        );
        emit(RentalRequestSuccess(rental));
      } else {
        emit(
          EquipmentError(response.data['message'] ?? 'Erreur de réservation'),
        );
      }
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }

  Future<void> _onLoadMyRentals(
    LoadMyRentals event,
    Emitter<EquipmentState> emit,
  ) async {
    emit(EquipmentLoading());
    try {
      final response = await _apiClient.get('/locations/mes-locations');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final rentals = data
            .map(
              (json) => Rental(
                id: json['id'] ?? '',
                equipmentId: json['equipementId'] ?? '',
                locataireId: json['locataireId'] ?? '',
                dateDebut: json['dateDebut'] != null
                    ? DateTime.parse(json['dateDebut'])
                    : DateTime.now(),
                dateFin: json['dateFin'] != null
                    ? DateTime.parse(json['dateFin'])
                    : DateTime.now(),
                dureeJours: json['dureeJours'] ?? 0,
                prixTotal: (json['prixTotal'] ?? 0).toDouble(),
                statut: json['statut'] ?? 'demande',
                createdAt: json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'])
                    : DateTime.now(),
              ),
            )
            .toList();
        emit(RentalsLoaded(rentals));
      } else {
        emit(RentalsLoaded([]));
      }
    } catch (e) {
      emit(RentalsLoaded([]));
    }
  }

  Future<void> _onCancelRental(
    CancelRental event,
    Emitter<EquipmentState> emit,
  ) async {
    try {
      await _apiClient.delete('/locations/${event.rentalId}');
      add(LoadMyRentals());
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }
}
