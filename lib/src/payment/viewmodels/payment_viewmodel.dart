import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_wallet.dart';
import 'package:bagyesrushappusernew/src/payment/repositories/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodels/payment_state.dart';

class PaymentViewmodel extends ViewModel<PaymentState> {
  PaymentViewmodel({required PaymentGatewayRepository repository})
      : _repository = repository,
        super(const PaymentInitial());

  final PaymentGatewayRepository _repository;

  /// Last successfully loaded wallet — cached so other screens can read the
  /// balance without re-fetching (mirrors [AuthViewmodel]'s cached getters).
  PaymentWallet? _wallet;
  PaymentWallet? get wallet => _wallet;

  Future<void> getWallet() async {
    appLogger.d('PaymentViewmodel.getWallet → initiated');
    emit(const PaymentLoading());

    final result = await _repository.getWallet();

    result.fold(
      (failure) {
        appLogger.w('PaymentViewmodel.getWallet → error: ${failure.message}');
        emit(PaymentError.fromFailure(failure));
      },
      (data) {
        _wallet = data;
        appLogger.i('PaymentViewmodel.getWallet → balance=${data.balance}');
        emit(PaymentWalletLoaded(data));
      },
    );
  }

  Future<void> topUpWallet({
    required double amount,
    required PaymentChannel paymentMethod,
    MobileMoneyProvider? mobileMoneyProvider,
    String? phone,
  }) async {
    appLogger.d('PaymentViewmodel.topUpWallet → amount=$amount');
    emit(const PaymentLoading());

    final result = await _repository.topUpWallet(
      amount: amount,
      paymentMethod: paymentMethod,
      mobileMoneyProvider: mobileMoneyProvider,
      phone: phone,
    );

    result.fold(
      (failure) {
        appLogger.w('PaymentViewmodel.topUpWallet → error: ${failure.message}');
        emit(PaymentError.fromFailure(failure));
      },
      (data) {
        appLogger.i('PaymentViewmodel.topUpWallet → success ref=${data.reference}');
        emit(PaymentTopUpSuccess(data));
      },
    );
  }

  Future<void> withdrawFromWallet({
    required double amount,
    required MobileMoneyProvider mobileMoneyProvider,
    required String phone,
    required String accountName,
  }) async {
    appLogger.d('PaymentViewmodel.withdrawFromWallet → amount=$amount');
    emit(const PaymentLoading());

    final result = await _repository.withdrawFromWallet(
      amount: amount,
      mobileMoneyProvider: mobileMoneyProvider,
      phone: phone,
      accountName: accountName,
    );

    result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewmodel.withdrawFromWallet → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
      },
      (data) {
        appLogger.i('PaymentViewmodel.withdrawFromWallet → success');
        emit(PaymentWithdrawSuccess(data));
      },
    );
  }

  Future<void> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    appLogger.d('PaymentViewmodel.getTransactionHistory → page=$page');
    emit(const PaymentLoading());

    final result = await _repository.getTransactionHistory(
      page: page,
      limit: limit,
      type: type,
    );

    result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewmodel.getTransactionHistory → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
      },
      (data) {
        appLogger.i(
          'PaymentViewmodel.getTransactionHistory → loaded ${data.transactions.length} transactions',
        );
        emit(PaymentHistoryLoaded(data));
      },
    );
  }

  /// Resets state to [PaymentInitial] after a one-shot action has been handled.
  void resetState() => emit(const PaymentInitial());
}
