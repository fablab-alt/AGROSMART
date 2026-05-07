import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/marketplace/domain/entities/payment_transaction.dart';

// Events
abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends PaymentEvent {}

class InitiatePayment extends PaymentEvent {
  final double amount;
  final String provider; // orange_money, mtn_money, moov_money
  final String phoneNumber;
  final String? description;
  final String? orderId;
  final String? rentalId; // locationId
  final String? groupPurchaseId;

  InitiatePayment({
    required this.amount,
    required this.provider,
    required this.phoneNumber,
    this.description,
    this.orderId,
    this.rentalId,
    this.groupPurchaseId,
  });

  @override
  List<Object?> get props => [
    amount,
    provider,
    phoneNumber,
    description,
    orderId,
    rentalId,
    groupPurchaseId,
  ];
}

// States
abstract class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class TransactionsLoaded extends PaymentState {
  final List<PaymentTransaction> transactions;
  TransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final String message;

  PaymentSuccess({required this.transactionId, required this.message});

  @override
  List<Object?> get props => [transactionId, message];
}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ApiClient _apiClient;

  PaymentBloc({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(PaymentInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<InitiatePayment>(_onInitiatePayment);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final response = await _apiClient.get('/paiements/transactions');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final transactions = data
            .map(
              (json) => PaymentTransaction(
                id: json['id'] ?? '',
                userId: json['userId'] ?? '',
                montant: (json['montant'] ?? 0).toDouble(),
                fournisseur: json['fournisseur'] ?? '',
                numeroTelephone: json['numeroTelephone'] ?? '',
                statut: json['statut'] ?? 'en_attente',
                createdAt: json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'])
                    : DateTime.now(),
                description: json['description'],
              ),
            )
            .toList();
        emit(TransactionsLoaded(transactions));
      } else {
        emit(PaymentError(response.data['message'] ?? 'Erreur de chargement'));
      }
    } catch (e) {
      // Retourner liste vide si erreur API
      emit(TransactionsLoaded([]));
    }
  }

  Future<void> _onInitiatePayment(
    InitiatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final response = await _apiClient.post(
        '/paiements/initier',
        data: {
          'montant': event.amount,
          'fournisseur': event.provider,
          'numeroTelephone': event.phoneNumber,
          'description': event.description,
          'orderId': event.orderId,
          'locationId': event.rentalId,
          'groupPurchaseId': event.groupPurchaseId,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        emit(
          PaymentSuccess(
            transactionId:
                data?['transactionId'] ??
                'TX_${DateTime.now().millisecondsSinceEpoch}',
            message:
                'Paiement de ${event.amount} FCFA initié via ${event.provider}',
          ),
        );

        // Recharger la liste
        add(LoadTransactions());
      } else {
        emit(PaymentError(response.data['message'] ?? 'Erreur de paiement'));
      }
    } catch (e) {
      emit(PaymentError('Erreur lors du paiement: $e'));
    }
  }
}
