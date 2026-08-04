import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/router/app_routes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../model/vendor_profile.dart';
import '../providers/dashboard_provider.dart' show dashboardProvider;
import 'widgets/vendor_header.dart';
import 'widgets/store_toggle_card.dart';
import 'widgets/store_status_toast.dart';
import 'widgets/new_order_banner.dart';
import 'widgets/order_card.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vendor_drawer.dart';
import 'widgets/kyc_prompt_banner.dart';
import 'vendor_shop_profile_screen.dart';
import '../features/notifications/view/screens/vendor_notifications_screen.dart';
import 'vendor_orders_view.dart';
import 'vendor_menu_view.dart';
import 'vendor_earnings_view.dart';
import '../model/dummy_orders.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../../states/app.state.dart';
import '../../../services/auth.service.dart' show ISignup;
import '../../../core/widgets/custom_dialogs.dart';
import '../../../core/utils/location_helper.dart';

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
    NavItem(icon: HugeIcons.strokeRoundedCheckList, label: 'Orders'),
    NavItem(icon: HugeIcons.strokeRoundedRestaurant01, label: 'Menu'),
    NavItem(icon: HugeIcons.strokeRoundedAnalyticsUp, label: 'Earnings'),
  ];

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _navigateToShopProfile() {
    _closeDrawer();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => const VendorShopProfileScreen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    _closeDrawer();
    final w = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.05),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: w * 0.06,
              ),
            ),
            SizedBox(width: w * 0.03),
            const Expanded(child: Text('Delete Account')),
          ],
        ),
        titleTextStyle: TextStyle(
          fontSize: w * 0.045,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Mukta',
        ),
        content: Text(
          'This action is permanent and cannot be undone. '
          'All your shop data, menu items, order history, and earnings records will be permanently deleted.',
          style: TextStyle(
            fontSize: w * 0.034,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Call deleteAccount via ViewModel when API is ready
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    _closeDrawer();
    CustomDialog.showConfirmation(
      context: context,
      title: 'Logout',
      subtitle: 'Are you sure you want to log out?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      onConfirm: () async {
        if (!mounted) return;

        // Clear MVVM auth session
        await context.read<AuthViewmodel>().logout();

        if (!mounted) return;

        // Clear legacy AppState user data
        final appState = context.read<AppState>();
        appState.setUser(IUser());
        appState.setPayload(ISignup());

        // Navigate to login, replacing the entire stack
        context.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<CurrentUserProvider>().user;
    final vendorProfile = user?.profile as VendorProfile?;

    String initials = '??';
    if (vendorProfile != null) {
      final name = vendorProfile.businessName;
      if (name.isNotEmpty) {
        final parts = name.split(' ');
        if (parts.length > 1) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          initials = name[0].toUpperCase();
        }
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _navIndex,
                children: [
                  _DashboardTab(
                    vendorProfile: vendorProfile,
                    initials: initials,
                    onDrawerTap: _openDrawer,
                    onViewAllOrders: () => setState(() => _navIndex = 1),
                    onAvatarTap: _navigateToShopProfile,
                  ),
                  const VendorOrdersView(),
                  const VendorMenuView(),
                  const VendorEarningsView(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingNavBar(
                currentIndex: _navIndex,
                onTap: (i) => setState(() => _navIndex = i),
                items: _navItems,
              ),
            ),
            if (_drawerOpen)
              VendorDrawer(
                userName: vendorProfile?.businessName ?? "Vendor",
                userEmail: user?.email ?? '',
                initials: initials,
                isVerified: user?.phoneVerified ?? false,
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
                onShopProfile: _navigateToShopProfile,
                onWallet: () {
                  _closeDrawer();
                  context.push(AppRoutes.vendorWallet);
                },
                onPaymentMethods: () {
                  _closeDrawer();
                  context.push(AppRoutes.vendorPaymentMethods);
                },
                onPrivacyPolicy: () {},
                onHelpSupport: () {},
                onDeleteAccount: _showDeleteAccountDialog,
                onLogout: _handleLogout,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard tab (index 0) ────────────────────────────────────────────

class _DashboardTab extends ConsumerStatefulWidget {
  final VendorProfile? vendorProfile;
  final String initials;
  final VoidCallback? onDrawerTap;
  final VoidCallback? onViewAllOrders;
  final VoidCallback? onAvatarTap;
  const _DashboardTab({
    this.vendorProfile,
    required this.initials,
    this.onDrawerTap,
    this.onViewAllOrders,
    this.onAvatarTap,
  });

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
    final result = await LocationHelper.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = result['address']);
    }
  }

  String _formatOperatingDays(List<String> days) {
    if (days.isEmpty) return 'Closed';
    final dayMap = {
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
    };
    return days.map((d) => dayMap[d.toLowerCase()] ?? d).join(', ');
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

      final result = await LocationHelper.getCurrentLocation();
      final position = result['position'] as Position?;

      if (position == null) {
        if (mounted) {
          StoreStatusToast.show(
            context,
            isSuccess: false,
            title: 'Location Required',
            subtitle:
                'Enable location services so customers can find your store.',
          );
        }
        return;
      }

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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final w = MediaQuery.sizeOf(context).width;
    final h = w * 0.05;
    final profile = widget.vendorProfile;
    final location = _currentLocation ?? profile?.businessAddress;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header & Greeting Section ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(h, w * 0.02, h, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VendorHeader(
                  initials: widget.initials,
                  onDrawerTap: widget.onDrawerTap,
                  onNotificationTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, anim, _) => const VendorNotificationsScreen(),
                      transitionsBuilder: (_, anim, _, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      transitionDuration: const Duration(milliseconds: 320),
                    ),
                  ),
                  onAvatarTap: widget.onAvatarTap,
                ),
                SizedBox(height: w * 0.05),
                
                // Greeting + location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: TextStyle(
                              fontSize: w * 0.036,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Mukta',
                            ),
                          ),
                          Text(
                            profile?.businessName ?? 'Vendor',
                            style: TextStyle(
                              fontSize: w * 0.068,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.1,
                              fontFamily: 'Mukta',
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (location != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.015),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(w * 0.05),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: AppColors.primary,
                              size: w * 0.035,
                            ),
                            SizedBox(width: w * 0.015),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: w * 0.25),
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: w * 0.028,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Mukta',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Status Banners (compact)
                if (profile?.status == 'pending_review')
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.vendorKyc),
                    child: _StatusBanner(
                      icon: HugeIcons.strokeRoundedClock01,
                      label: 'Account pending review (Tap to check)',
                      color: AppColors.warning,
                      w: w,
                    ),
                  ),
                if (profile?.isProfileComplete == false) ...[
                  SizedBox(height: w * 0.025),
                  KYCPromptBanner(
                    onTap: () => context.push(AppRoutes.vendorKyc),
                  ),
                ],
                
                SizedBox(height: w * 0.05),
                StoreToggleCard(
                  isOpen: state.storeOpen,
                  isLoading: _isTogglingStore,
                  onToggle: _handleStoreToggle,
                  revenue: state.todayRevenue,
                  orders: '${state.activeOrderCount}',
                  rating: profile?.rating.toString() ?? state.avgRating,
                ),
                
                // Quick info chips
                if (profile != null) ...[
                  SizedBox(height: w * 0.035),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _DashboardChip(
                          icon: HugeIcons.strokeRoundedClock01,
                          label: '${profile.openingTime} – ${profile.closingTime}',
                          w: w,
                        ),
                        SizedBox(width: w * 0.02),
                        _DashboardChip(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          label: _formatOperatingDays(profile.operatingDays),
                          w: w,
                        ),
                        SizedBox(width: w * 0.02),
                        _DashboardChip(
                          icon: HugeIcons.strokeRoundedDeliveryTruck01,
                          label: '${profile.deliveryRadiusKm}km Radius',
                          w: w,
                        ),
                      ],
                    ),
                  ),
                ],

                if (DummyOrders.newOrders.isNotEmpty) ...[
                  SizedBox(height: w * 0.05),
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
                ],

                SizedBox(height: w * 0.06),
                _ActiveOrdersLabel(
                  count: DummyOrders.activeOrders.length,
                  onViewAll: widget.onViewAllOrders,
                ),
                SizedBox(height: w * 0.025),
              ],
            ),
          ),
        ),

        // ── Active Orders List ──
        if (DummyOrders.activeOrders.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.06),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedShoppingBag01,
                      size: w * 0.1,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(height: w * 0.04),
                  Text(
                    'No active orders',
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Mukta',
                    ),
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    'New orders will appear here',
                    style: TextStyle(
                      fontSize: w * 0.034,
                      color: AppColors.textSecondary,
                      fontFamily: 'Mukta',
                    ),
                  ),
                  SizedBox(height: w * 0.1), // Spacing for floating bar
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = DummyOrders.activeOrders[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: w * 0.035),
                    child: OrderCard(
                      order: order,
                      onTap: () {},
                      onAccept: () {},
                      onDecline: () {},
                    ),
                  );
                },
                childCount: DummyOrders.activeOrders.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final double w;

  const _DashboardChip({required this.icon, required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.textSecondary, size: w * 0.035),
          SizedBox(width: w * 0.018),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.028,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontFamily: 'Mukta',
            ),
          ),
        ],
      ),
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

// ─── Status Banner ───────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final double w;

  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.color,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: w * 0.025),
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.035,
        vertical: w * 0.025,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: color, size: w * 0.04),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.03,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
