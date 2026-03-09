import 'package:equatable/equatable.dart';
import '../models/payment_method_model.dart';

// ── State ──────────────────────────────────────────────────────────────────

enum PaymentMethodsStatus { initial, loading, loaded, error }

class PaymentMethodsState extends Equatable {
  final PaymentMethodsStatus status;
  final List<PaymentMethodModel> paymentMethods;
  final String? errorMessage;

  /// ID currently being processed (delete / toggle / set-default).
  final String? processingId;

  const PaymentMethodsState({
    this.status = PaymentMethodsStatus.initial,
    this.paymentMethods = const [],
    this.errorMessage,
    this.processingId,
  });

  PaymentMethodsState copyWith({
    PaymentMethodsStatus? status,
    List<PaymentMethodModel>? paymentMethods,
    String? errorMessage,
    String? processingId,
    bool clearError = false,
    bool clearProcessingId = false,
  }) {
    return PaymentMethodsState(
      status: status ?? this.status,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      processingId:
          clearProcessingId ? null : (processingId ?? this.processingId),
    );
  }

  bool get isEmpty =>
      status == PaymentMethodsStatus.loaded && paymentMethods.isEmpty;

  @override
  List<Object?> get props =>
      [status, paymentMethods, errorMessage, processingId];
}
