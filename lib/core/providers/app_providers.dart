import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/transaction/viewmodels/transaction_viewmodel.dart';

final _sl = GetIt.instance;

class AppProviders {
  static List<SingleChildWidget> get allProviders => [
        ChangeNotifierProvider<CurrentUserProvider>(
          create: (_) => _sl<CurrentUserProvider>(),
        ),
        ChangeNotifierProvider<AuthViewmodel>(
          create: (_) => _sl<AuthViewmodel>(),
        ),
        ChangeNotifierProvider<OrderViewModel>(
          create: (_) => _sl<OrderViewModel>(),
        ),
        ChangeNotifierProvider<TransactionViewmodel>(
          create: (_) => _sl<TransactionViewmodel>(),
        ),
      ];
}
