import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/marketplace/domain/entities/group_purchase.dart';

// Events
abstract class GroupPurchaseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroupPurchases extends GroupPurchaseEvent {
  final String? categorie;
  LoadGroupPurchases({this.categorie});

  @override
  List<Object?> get props => [categorie];
}

class JoinGroupPurchase extends GroupPurchaseEvent {
  final String groupPurchaseId;
  final int quantity;

  JoinGroupPurchase({required this.groupPurchaseId, required this.quantity});

  @override
  List<Object?> get props => [groupPurchaseId, quantity];
}

class CreateGroupPurchase extends GroupPurchaseEvent {
  // Add fields
  @override
  List<Object?> get props => [];
}

// States
abstract class GroupPurchaseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupPurchaseInitial extends GroupPurchaseState {}

class GroupPurchaseLoading extends GroupPurchaseState {}

class GroupPurchasesLoaded extends GroupPurchaseState {
  final List<GroupPurchase> groupPurchases;
  GroupPurchasesLoaded(this.groupPurchases);

  @override
  List<Object?> get props => [groupPurchases];
}

class GroupPurchaseSuccess extends GroupPurchaseState {
  final String message;
  GroupPurchaseSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupPurchaseError extends GroupPurchaseState {
  final String message;
  GroupPurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class GroupPurchaseBloc extends Bloc<GroupPurchaseEvent, GroupPurchaseState> {
  final ApiClient _apiClient;

  GroupPurchaseBloc({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(GroupPurchaseInitial()) {
    on<LoadGroupPurchases>(_onLoadGroupPurchases);
    on<JoinGroupPurchase>(_onJoinGroupPurchase);
  }

  Future<void> _onLoadGroupPurchases(
    LoadGroupPurchases event,
    Emitter<GroupPurchaseState> emit,
  ) async {
    emit(GroupPurchaseLoading());
    try {
      String endpoint = '/achats-groupes';
      if (event.categorie != null) {
        endpoint += '?categorie=${event.categorie}';
      }

      final response = await _apiClient.get(endpoint);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final purchases = data
            .map(
              (json) => GroupPurchase(
                id: json['id'] ?? '',
                organisateurId: json['organisateurId'] ?? '',
                produitType: json['produitType'] ?? '',
                description: json['description'] ?? '',
                categorie: json['categorie'] ?? 'autre',
                quantiteObjectif: json['quantiteObjectif'] ?? 0,
                quantiteActuelle: json['quantiteActuelle'] ?? 0,
                unite: json['unite'] ?? '',
                prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
                prixGroupe: (json['prixGroupe'] ?? 0).toDouble(),
                economiePourcentage: (json['economiePourcentage'] ?? 0)
                    .toDouble(),
                dateLimite: json['dateLimite'] != null
                    ? DateTime.parse(json['dateLimite'])
                    : DateTime.now().add(const Duration(days: 30)),
                statut: json['statut'] ?? 'ouvert',
                localisationLivraison: json['localisationLivraison'] ?? '',
              ),
            )
            .toList();
        emit(GroupPurchasesLoaded(purchases));
      } else {
        emit(
          GroupPurchaseError(
            response.data['message'] ?? 'Erreur de chargement',
          ),
        );
      }
    } catch (e) {
      emit(GroupPurchasesLoaded([]));
    }
  }

  Future<void> _onJoinGroupPurchase(
    JoinGroupPurchase event,
    Emitter<GroupPurchaseState> emit,
  ) async {
    emit(GroupPurchaseLoading());
    try {
      final response = await _apiClient.post(
        '/achats-groupes/${event.groupPurchaseId}/rejoindre',
        data: {'quantite': event.quantity},
      );

      if (response.data['success'] == true) {
        emit(
          GroupPurchaseSuccess(
            "Vous avez rejoint l'achat groupé avec succès !",
          ),
        );
        add(LoadGroupPurchases());
      } else {
        emit(
          GroupPurchaseError(
            response.data['message'] ?? "Erreur lors de l'inscription",
          ),
        );
      }
    } catch (e) {
      emit(GroupPurchaseError(e.toString()));
    }
  }
}
