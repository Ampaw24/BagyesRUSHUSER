import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_state.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart'
    as consumer_orders;
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/delivery_location.dart';
import 'package:bagyesrushappusernew/src/customer_address/repositories/customer_address_repository.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

import '../consumer_orders/support/order_test_support.dart';
import '../core/support/auth_test_support.dart';

/// Records what checkout asks the backend to create.
class _Orders extends Fake implements consumer_orders.OrdersViewModel {
  final placed = <({String paymentMethod, bool useWallet, int quoteId})>[];

  @override
  Future<ConsumerOrder> placeOrder({
    required String vendorId,
    required String paymentMethod,
    int? customerAddressId,
    DeliveryLocation? location,
    required int deliveryQuoteId,
    required bool useWallet,
    String? notes,
  }) async {
    placed.add((
      paymentMethod: paymentMethod,
      useWallet: useWallet,
      quoteId: deliveryQuoteId,
    ));
    return ConsumerOrder.fromJson(fullOrder());
  }
}

class _OrdersRepo extends Fake implements ConsumerOrdersRepository {}

class _Addresses extends Fake implements CustomerAddressRepository {}

CartModel _cart() => CartModel.fromJson({
      'vendor_id': 'v1',
      'items': [
        {'id': 1, 'menu_item_id': 5, 'name': 'Jollof', 'quantity': 2, 'unit_price': 25},
      ],
      'totals': {'subtotal': 50.0, 'delivery_fee': 10.0, 'total': 60.0},
      'delivery': {'quote_id': 77},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('placing an order', () {
    late _Orders orders;
    late CheckoutViewModel vm;

    setUp(() {
      orders = _Orders();
      vm = CheckoutViewModel(
        ordersViewModel: orders,
        ordersRepository: _OrdersRepo(),
        addressRepository: _Addresses(),
        session: CurrentUserProvider(),
      );
      vm.emit(const CheckoutIdle(
        form: CheckoutForm(
          selectedAddress: CustomerAddress(id: 1, address: 'East Legon', isDefault: true),
        ),
      ));
    });

    tearDown(() => vm.dispose());

    test('needs no saved payment method — Paystack takes the payment',
        () async {
      await vm.placeOrder(_cart());

      expect(vm.state, isA<CheckoutSuccess>());
      expect(orders.placed.single.quoteId, 77);
      expect(
        (vm.state as CheckoutSuccess).requiresPayment,
        isTrue,
        reason: 'the order still has to be paid, through Paystack',
      );
    });

    test('a wallet that covers it all skips payment entirely', () async {
      vm.setUseWallet(true);

      await vm.placeOrder(_cart(), walletCoversTotal: true);

      expect(orders.placed.single.useWallet, isTrue);
      expect((vm.state as CheckoutSuccess).requiresPayment, isFalse);
    });

    test('a partly covering wallet still sends the rest to Paystack',
        () async {
      vm.setUseWallet(true);

      await vm.placeOrder(_cart(), walletCoversTotal: false);

      expect((vm.state as CheckoutSuccess).requiresPayment, isTrue);
    });

    test('it still insists on a delivery address', () async {
      vm.emit(const CheckoutIdle(form: CheckoutForm()));

      await vm.placeOrder(_cart());

      expect((vm.state as CheckoutError).message, 'Please choose a delivery address');
      expect(orders.placed, isEmpty);
    });
  });

  group('booking a parcel', () {
    ParcelQuote quote() => ParcelQuote.fromJson({
          'delivery_quote_id': 5141,
          'fee': 28,
          'service_fee': 2.4,
          'total': 30.4,
          'currency': 'GHS',
          'eta_minutes': 18,
          'distance_km': 6.4,
          'expires_at': '2099-01-01T00:00:00.000000Z',
          'rider': {'id': 31, 'name': 'Kofi O.'},
        });

    test('the summary step proceeds on a live quote, with no payment method',
        () {
      final state = SendParcelState(
        currentStep: ParcelStep.summary,
        riderQuotes: [quote()],
        selectedRiderId: '31',
      );

      expect(state.canProceed, isTrue);
    });

    test('but never on a quote the customer has not got', () {
      const state = SendParcelState(currentStep: ParcelStep.summary);

      expect(state.canProceed, isFalse);
    });
  });

  test('starting the payment sends only the payment method — no number, no '
      'network', () async {
    final adapter = ScriptedAdapter(
      (o) => (200, {'data': {'reference': 'r1', 'authorization_url': 'https://checkout.paystack.com/x'}}),
    );
    final repo = ConsumerOrdersRepository(client: Dio()..httpClientAdapter = adapter);

    final response = await repo.payOrder('9', paymentMethod: 'mobile_money');

    final request = adapter.requests.single;
    expect('${request.method} ${request.path}', 'POST /customer/orders/9/pay');
    expect(request.data, {'payment_method': 'mobile_money'});
    expect(response['authorization_url'], 'https://checkout.paystack.com/x');
  });
}
