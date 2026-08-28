import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';

/// The customer's saved mobile-money payment methods, for the checkout
/// payment-method picker. Reuses the same [PaymentRepository] the
/// Profile → Payment Methods screen uses, bridged into Riverpod since
/// checkout is Riverpod-based while that repository's usual consumers are
/// GetIt/ChangeNotifier based.
final checkoutPaymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final result = await sl<PaymentRepository>().getCustomerPaymentMethods();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (methods) => methods,
  );
});
