import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_state.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart'
    as consumer_orders;
import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_wallet_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/repositories/customer_wallet_repository.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_state.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';
import 'package:bagyesrushappusernew/src/customer_address/repositories/customer_address_repository.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_state.dart'
    as menu_orders;
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart'
    as menu_orders;
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/orders/repositories/orders_repository.dart';
import 'package:bagyesrushappusernew/src/transaction/repositories/transaction_repository.dart';
import 'package:bagyesrushappusernew/src/transaction/viewmodels/transaction_state.dart';
import 'package:bagyesrushappusernew/src/transaction/viewmodels/transaction_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor-wallet/models/vendor_wallet_model.dart';
import 'package:bagyesrushappusernew/src/vendor-wallet/repositories/vendor_wallet_repository.dart';
import 'package:bagyesrushappusernew/src/vendor-wallet/viewmodels/vendor_wallet_state.dart';
import 'package:bagyesrushappusernew/src/vendor-wallet/viewmodels/vendor_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/repository/vendor_dashboard_repository.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/dashboard_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/orders_viewmodel.dart'
    as vendor_orders;
import 'package:bagyesrushappusernew/src/vendor/viewmodel/settings_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/vendor_kyc_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/repositories/review_repository.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/viewmodels/reviews_state.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/viewmodels/reviews_viewmodel.dart';

class _Orders extends Fake implements ConsumerOrdersRepository {}

class _Consumer extends Fake implements consumer_orders.OrdersViewModel {}

class _Transactions extends Fake implements TransactionRepository {}

class _MenuOrders extends Fake implements OrdersRepository {}

class _VendorRepo extends Fake implements VendorDashboardRepository {}

class _ReviewRepo extends Fake implements ReviewRepository {}

class _Payments extends Fake implements PaymentRepository {
  @override
  ResultFuture<List<PaymentMethod>> getCustomerPaymentMethods() async =>
      const Right([]);
}

class _Addresses extends Fake implements CustomerAddressRepository {
  @override
  ResultFuture<List<CustomerAddress>> getAddresses() async => const Right([]);
}

class _CustomerWallet extends Fake implements CustomerWalletRepository {
  @override
  ResultFuture<CustomerWalletModel> getWallet() async => const Right(
        CustomerWalletModel(
          balance: 120.5,
          currency: 'GHS',
          withdrawable: 0,
          spendableOnly: 0,
          lifetimeEarned: 0,
          lifetimeWithdrawn: 0,
          pendingEarnings: 0,
          pendingWithdrawal: 0,
          minimumWithdrawal: 0,
          canWithdraw: false,
          hasPayoutDetails: false,
          withdrawalsEnabled: false,
        ),
      );
}

class _VendorWallet extends Fake implements VendorWalletRepository {
  @override
  ResultFuture<VendorWalletModel> getWallet() async =>
      const Right(VendorWalletModel(balance: 75));
}

User _user({String email = 'a@example.com'}) => User(
      id: '1',
      email: email,
      phone: '+233241234567',
      role: 'customer',
      status: 'active',
      phoneVerified: true,
      profile: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentUserProvider session;

  setUp(() {
    Cache.instance.setSessionToken('token');
    session = CurrentUserProvider()..setUser(_user());
  });

  tearDown(Cache.instance.resetSession);

  /// Ends the session the way logout / an expired token does.
  void signOut() {
    Cache.instance.resetSession();
    session.clearUser();
  }

  group('wallets drop the previous account balance on sign-out', () {
    test('customer wallet', () async {
      final vm = CustomerWalletViewmodel(
        repository: _CustomerWallet(),
        session: session,
      );
      await vm.fetchWallet();
      expect(vm.wallet?.balance, 120.5);

      signOut();

      expect(vm.wallet, isNull);
      expect(vm.state, isA<CustomerWalletInitial>());
    });

    test('vendor wallet', () async {
      final vm = VendorWalletViewmodel(
        repository: _VendorWallet(),
        session: session,
      );
      await vm.fetchWallet();
      expect(vm.wallet?.balance, 75);

      signOut();

      expect(vm.wallet, isNull);
      expect(vm.transactionsResult, isNull);
      expect(vm.withdrawalsResult, isNull);
      expect(vm.state, isA<VendorWalletInitial>());
    });

    test('a profile update while signed in keeps the cached balance',
        () async {
      final vm = CustomerWalletViewmodel(
        repository: _CustomerWallet(),
        session: session,
      );
      await vm.fetchWallet();

      session.setUser(_user(email: 'renamed@example.com'));

      expect(vm.wallet?.balance, 120.5);
    });
  });

  test('transactions are cleared on sign-out', () {
    final vm = TransactionViewmodel(
      repository: _Transactions(),
      session: session,
    )..emit(const TransactionLoading());

    signOut();

    expect(vm.state, isA<TransactionInitial>());
  });

  test('checkout drops saved methods, addresses and the half-filled form',
      () async {
    final vm = CheckoutViewModel(
      ordersViewModel: _Consumer(),
      ordersRepository: _Orders(),
      paymentRepository: _Payments(),
      addressRepository: _Addresses(),
      session: session,
    );
    await vm.refreshPaymentMethods();
    await vm.loadAddresses('vendor-1');
    vm.emit(const CheckoutIdle(
      form: CheckoutForm(deliveryInstructions: 'Leave at the gate'),
    ));
    expect(vm.paymentMethodsStatus, PaymentMethodsStatus.loaded);
    expect(vm.addressesStatus, AddressesStatus.loaded);

    signOut();

    expect(vm.paymentMethodsStatus, PaymentMethodsStatus.loading);
    expect(vm.paymentMethods, isEmpty);
    expect(vm.addressesStatus, AddressesStatus.loading);
    expect(vm.addresses, isEmpty);
    expect(
      (vm.state as CheckoutIdle).form.deliveryInstructions,
      isEmpty,
    );
  });

  group('vendor screens drop the previous vendor on sign-out', () {
    test('dashboard', () {
      final vm = DashboardViewModel(_VendorRepo(), session)
        ..emit(const DashboardState(status: DashboardStatus.loaded));

      signOut();

      expect(vm.state, const DashboardState());
    });

    test('orders', () {
      final vm = vendor_orders.OrdersViewModel(_VendorRepo(), session)
        ..emit(const vendor_orders.OrdersState(
          status: vendor_orders.OrdersStatus.loaded,
        ));

      signOut();

      expect(vm.state, const vendor_orders.OrdersState());
    });

    test('settings / payout profile', () {
      final vm = SettingsViewModel(_VendorRepo(), session)
        ..emit(const SettingsState(status: SettingsStatus.loaded));

      signOut();

      expect(vm.state, const SettingsState());
    });

    test('kyc form', () {
      final vm = VendorKycViewModel(
        dashboardRepository: _VendorRepo(),
        currentUserProvider: session,
      );
      vm.emit(vm.state.copyWith(businessCertPath: '/tmp/cert.pdf'));
      expect(vm.state.businessCertPath, '/tmp/cert.pdf');

      signOut();

      expect(vm.state, const VendorKycState());
    });

    test('menu items', () {
      final vm = menu_orders.OrderViewModel(
        repository: _MenuOrders(),
        session: session,
      )..emit(const menu_orders.OrdersLoading());

      signOut();

      expect(vm.state, isA<menu_orders.OrdersInitial>());
    });

    test('reviews', () {
      final vm = ReviewsViewModel(_ReviewRepo(), session)
        ..emit(const ReviewsState.initial().copyWith(ratingFilter: 5));

      signOut();

      expect(vm.state, const ReviewsState.initial());
    });
  });
}
