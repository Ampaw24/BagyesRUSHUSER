import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../model/vendor_order.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.storeOpen,
    required this.todayRevenue,
    required this.activeOrderCount,
    required this.avgRating,
    required this.activeOrders,
  });

  final bool storeOpen;
  final String todayRevenue;
  final int activeOrderCount;
  final String avgRating;
  final List<VendorOrder> activeOrders;

  DashboardLoaded copyWith({
    bool? storeOpen,
    String? todayRevenue,
    int? activeOrderCount,
    String? avgRating,
    List<VendorOrder>? activeOrders,
  }) =>
      DashboardLoaded(
        storeOpen: storeOpen ?? this.storeOpen,
        todayRevenue: todayRevenue ?? this.todayRevenue,
        activeOrderCount: activeOrderCount ?? this.activeOrderCount,
        avgRating: avgRating ?? this.avgRating,
        activeOrders: activeOrders ?? this.activeOrders,
      );

  @override
  List<Object?> get props =>
      [storeOpen, todayRevenue, activeOrderCount, avgRating, activeOrders];
}

final class DashboardError extends DashboardState {
  const DashboardError({required this.message, required this.title});

  DashboardError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
