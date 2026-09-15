import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../models/customer_wallet_model.dart';
import '../repositories/customer_wallet_repository.dart';
import 'customer_wallet_state.dart';

class CustomerWalletViewmodel extends ViewModel<CustomerWalletState> {
  CustomerWalletViewmodel({required CustomerWalletRepository repository})
    : _repository = repository,
      super(const CustomerWalletInitial());

  final CustomerWalletRepository _repository;

  /// Last successfully loaded wallet — cached so other screens can read the
  /// balance without re-fetching (mirrors [PaymentViewmodel]'s cached getter).
  CustomerWalletModel? _wallet;
  CustomerWalletModel? get wallet => _wallet;

  Future<void> fetchWallet() async {
    appLogger.d('CustomerWalletViewmodel.fetchWallet → initiated');
    emit(const CustomerWalletLoading());

    final result = await _repository.getWallet();

    result.fold(
      (failure) {
        appLogger.w('CustomerWalletViewmodel.fetchWallet → error: ${failure.message}');
        emit(CustomerWalletError.fromFailure(failure));
      },
      (data) {
        _wallet = data;
        appLogger.i('CustomerWalletViewmodel.fetchWallet → balance=${data.balance}');
        emit(CustomerWalletLoaded(data));
      },
    );
  }
}
