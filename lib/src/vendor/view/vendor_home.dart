import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../constant/app_theme.dart';
import '../providers/dashboard_provider.dart' show dashboardProvider;
import 'widgets/vendor_header.dart';
import 'widgets/store_toggle_card.dart';
import 'widgets/store_status_toast.dart';
import 'widgets/stats_row.dart';
import 'widgets/new_order_banner.dart';
import 'widgets/order_card.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vendor_drawer.dart';
import '../features/notifications/view/screens/vendor_notifications_screen.dart';
import 'vendor_orders_view.dart';
import 'vendor_menu_view.dart';
import 'vendor_earnings_view.dart';
import '../model/dummy_orders.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  int _navIndex = 0;
  bool _drawerOpen = false;

  static const _navItems = [
    NavItem(icon: HugeIcons.strokeRoundedHome11, label: 'Home'),
    NavItem(icon: HugeIcons.strokeRoundedReceiptDollar, label: 'Orders'),
    NavItem(icon: HugeIcons.strokeRoundedRestaurant01, label: 'Menu'),
    NavItem(icon: HugeIcons.strokeRoundedAnalyticsUp, label: 'Earnings'),
  ];

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        extendBody: true,
        bottomNavigationBar: FloatingNavBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          items: _navItems,
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _navIndex,
                children: [
                  _DashboardTab(
                    onDrawerTap: _openDrawer,
                    onViewAllOrders: () => setState(() => _navIndex = 1),
                  ),
                  const VendorOrdersView(),
                  const VendorMenuView(),
                  const VendorEarningsView(),
                ],
              ),
            ),
            if (_drawerOpen)
              VendorDrawer(
                userName: "Mama's Kitchen",
                userEmail: 'mama@bagyesrush.com',
                initials: 'MK',
                isVerified: true,
                onClose: _closeDrawer,
                onNotifications: () {
                  _closeDrawer();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, anim, _) =>
                          const VendorNotificationsScreen(),
                      transitionsBuilder: (_, anim, _, child) =>
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, -0.06),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                      transitionDuration: const Duration(milliseconds: 320),
                    ),
                  );
                },
                onPaymentMethods: () {},
                onPrivacyPolicy: () {},
                onHelpSupport: () {},
                onLogout: () {},
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard tab (index 0) ────────────────────────────────────────────

class _DashboardTab extends ConsumerStatefulWidget {
  final VoidCallback? onDrawerTap;
  final VoidCallback? onViewAllOrders;
  const _DashboardTab({this.onDrawerTap, this.onViewAllOrders});

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  String? _currentLocation;
  bool _isTogglingStore = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() => _currentLocation = 'Location unavailable');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
        ];
        if (parts.isNotEmpty) {
          setState(() => _currentLocation = parts.join(', '));
        }
      }
    } catch (_) {
      setState(() => _currentLocation = 'Location unavailable');
    }
  }

  /// Pre-checks internet + location before opening the store.
  /// Closing the store skips these checks.
  Future<void> _handleStoreToggle(bool wantsOpen) async {
    if (_isTogglingStore) return;

    // Closing the store needs no pre-checks
    if (!wantsOpen) {
      await ref.read(dashboardProvider.notifier).toggleStore(false);
      return;
    }

    setState(() => _isTogglingStore = true);

    try {
      // 1. Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      if (!hasInternet) {
        if (mounted) {
          StoreStatusToast.show(
            context,
            isSuccess: false,
            title: 'No Internet Connection',
            subtitle: 'Please check your network connection and try again.',
          );
        }
        return;
      }

      // 2. Check location availability
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled) {
        if (mounted) {
          StoreStatusToast.show(
            context,
            isSuccess: false,
            title: 'Location Services Disabled',
            subtitle:
                'Enable location services so customers can find your store.',
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          StoreStatusToast.show(
            context,
            isSuccess: false,
            title: 'Location Permission Denied',
            subtitle: 'Grant location access so customers can see your store.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Validate that we actually got coordinates
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        if (mounted) {
          StoreStatusToast.show(
            context,
            isSuccess: false,
            title: 'Unable to Determine Location',
            subtitle: 'Could not get your current location. Please try again.',
          );
        }
        return;
      }

      // 3. All checks passed — open the store
      await ref.read(dashboardProvider.notifier).toggleStore(true);

      if (mounted) {
        StoreStatusToast.show(
          context,
          isSuccess: true,
          title: 'Store Open',
          subtitle:
              'You\'re ready to receive orders! Customers can now find you.',
        );
      }
    } catch (e) {
      if (mounted) {
        StoreStatusToast.show(
          context,
          isSuccess: false,
          title: 'Something Went Wrong',
          subtitle: 'Could not open your store. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingStore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w * 0.05;
    final sectionGap = w * 0.04;

    return Column(
      children: [
        // ── Fixed top section ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            w * 0.03,
            horizontalPad,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VendorHeader(
                title: "Mama's Kitchen",
                location: _currentLocation,
                initials: 'MK',
                onDrawerTap: widget.onDrawerTap,
                onNotificationTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, anim, _) =>
                        const VendorNotificationsScreen(),
                    transitionsBuilder: (_, anim, _, child) => SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.06),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    transitionDuration: const Duration(milliseconds: 320),
                  ),
                ),
                onAvatarTap: () {},
              ),
              Padding(
                padding: EdgeInsets.only(top: w * 0.07),
                child: StoreToggleCard(
                  isOpen: state.storeOpen,
                  isLoading: _isTogglingStore,
                  onToggle: _handleStoreToggle,
                ),
              ),
              SizedBox(height: sectionGap),
              StatsRow(
                stats: [
                  StatItem(
                    value: state.todayRevenue,
                    label: "Today's Rev",
                    icon: HugeIcons.strokeRoundedMoneyBag01,
                    iconColor: AppColors.success,
                  ),
                  StatItem(
                    value: '${state.activeOrderCount}',
                    label: 'Active Orders',
                    icon: HugeIcons.strokeRoundedFire,
                    iconColor: AppColors.accent,
                  ),
                  StatItem(
                    value: state.avgRating,
                    label: 'Avg Rating',
                    icon: HugeIcons.strokeRoundedStarCircle,
                    iconColor: AppColors.warning,
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              if (DummyOrders.newOrders.isNotEmpty)
                Builder(
                  builder: (_) {
                    final newest = DummyOrders.newOrders.first;
                    return NewOrderBanner(
                      orderId: newest.id,
                      amount: newest.amount,
                      customerName: newest.customerName,
                      itemCount: newest.itemList.length,
                      secondsLeft: 87,
                      onTap: () {},
                      onAccept: () {},
                    );
                  },
                ),
              SizedBox(height: w * 0.05),
              _ActiveOrdersLabel(
                count: DummyOrders.activeOrders.length,
                onViewAll: widget.onViewAllOrders,
              ),
              SizedBox(height: w * 0.03),
            ],
          ),
        ),

        // ── Scrollable orders only ──
        Expanded(
          child: DummyOrders.activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: w * 0.14,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: w * 0.04),
                      Text(
                        'No active orders',
                        style: TextStyle(
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: w * 0.015),
                      Text(
                        'New orders will appear here',
                        style: TextStyle(
                          fontSize: w * 0.032,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    0,
                    horizontalPad,
                    w * 0.25,
                  ),
                  itemCount: DummyOrders.activeOrders.length,
                  separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
                  itemBuilder: (_, index) {
                    final order = DummyOrders.activeOrders[index];
                    return OrderCard(
                      order: order,
                      onTap: () {},
                      onAccept: () {},
                      onDecline: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Active orders section label ────────────────────────────────────────

class _ActiveOrdersLabel extends StatelessWidget {
  final int count;
  final VoidCallback? onViewAll;
  const _ActiveOrdersLabel({this.count = 0, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Text(
          'Active Orders',
          style: TextStyle(
            fontSize: w * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (count > 0) ...[
          SizedBox(width: w * 0.02),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * 0.005,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
