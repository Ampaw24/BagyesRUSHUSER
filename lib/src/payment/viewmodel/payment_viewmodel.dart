import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../model/payment_method.dart';
import '../repository/payment_repository.dart';
import 'payment_state.dart';

/// Manages saved payout payment methods (mobile money accounts).
///
/// A single implementation backs both the customer and vendor screens —
/// the endpoints only differ by base path, selected via [isVendor].
class PaymentViewModel extends ViewModel<PaymentState> {
  PaymentViewModel({
    required PaymentRepository repository,
    required bool isVendor,
  })  : _repository = repository,
        _isVendor = isVendor,
        super(const PaymentInitial());

  final PaymentRepository _repository;
  final bool _isVendor;

  Future<void> loadPaymentMethods() async {
    appLogger.d('PaymentViewModel.loadPaymentMethods → initiated');
    emit(const PaymentLoading());

    final result = _isVendor
        ? await _repository.getVendorPaymentMethods()
        : await _repository.getCustomerPaymentMethods();

    result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewModel.loadPaymentMethods → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
      },
      (methods) {
        appLogger.i(
          'PaymentViewModel.loadPaymentMethods → loaded ${methods.length} methods',
        );
        emit(PaymentMethodsLoaded(methods));
      },
    );
  }

  Future<PaymentMethod?> addPaymentMethod({
    required int payoutProviderId,
    required String phoneNumber,
    String? label,
  }) async {
    appLogger.d('PaymentViewModel.addPaymentMethod → initiated');
    emit(const PaymentLoading());

    final result = _isVendor
        ? await _repository.addVendorPaymentMethod(
            payoutProviderId: payoutProviderId,
            phoneNumber: phoneNumber,
            label: label,
          )
        : await _repository.addCustomerPaymentMethod(
            payoutProviderId: payoutProviderId,
            phoneNumber: phoneNumber,
            label: label,
          );

    return result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewModel.addPaymentMethod → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
        return null;
      },
      (method) {
        appLogger.i(
          'PaymentViewModel.addPaymentMethod → success, id=${method.id}',
        );
        emit(PaymentMethodAdded(method));
        return method;
      },
    );
  }

  Future<bool> deletePaymentMethod(String id) async {
    appLogger.d('PaymentViewModel.deletePaymentMethod → id=$id');
    emit(const PaymentLoading());

    final result = _isVendor
        ? await _repository.deleteVendorPaymentMethod(id: id)
        : await _repository.deleteCustomerPaymentMethod(id: id);

    return result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewModel.deletePaymentMethod → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
        return false;
      },
      (_) {
        appLogger.i('PaymentViewModel.deletePaymentMethod → success, id=$id');
        emit(PaymentMethodDeleted(id));
        return true;
      },
    );
  }

  Future<bool> setDefault(String id) async {
    appLogger.d('PaymentViewModel.setDefault → id=$id');
    emit(const PaymentLoading());

    final result = _isVendor
        ? await _repository.makeVendorPaymentMethodDefault(id: id)
        : await _repository.makeCustomerPaymentMethodDefault(id: id);

    return result.fold(
      (failure) {
        appLogger.w(
          'PaymentViewModel.setDefault → error: ${failure.message}',
        );
        emit(PaymentError.fromFailure(failure));
        return false;
      },
      (method) {
        appLogger.i('PaymentViewModel.setDefault → success, id=$id');
        emit(PaymentMethodDefaultSet(method));
        return true;
      },
    );
  }
}
