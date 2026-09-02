import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/report/domain/entities/report.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../model/vendor_profile.dart';
import '../providers/dashboard_provider.dart' show dashboardProvider;
import 'widgets/vendor_header.dart';
import 'widgets/store_toggle_card.dart';
import '../../../core/widgets/app_toast.dart';
import 'widgets/new_order_banner.dart';
import 'widgets/order_card.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vendor_drawer.dart';
import 'widgets/setup_progress_card.dart';
import 'vendor_shop_profile_screen.dart';
import '../features/notifications/view/screens/vendor_notifications_screen.dart';
import 'vendor_orders_view.dart';
import 'vendor_menu_view.dart';
import 'vendor_earnings_view.dart';
import '../model/vendor_order.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/change_password_sheet.dart';
import '../../notification/viewmodel/notification_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewmodel>().registerDeviceToken();
      context.read<NotificationViewmodel>().getUnreadCount();
    });
  }

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
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle:
          'This action is permanent and cannot be undone. '
          'All your shop data, menu items, order history, and earnings records will be permanently deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {
        // TODO: Call deleteAccount via ViewModel when API is ready
      },
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
    final unreadNotifications = context
        .watch<NotificationViewmodel>()
        .unreadCount;

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
                imageUrl: vendorProfile?.logoUrl,
                isVerified: user?.phoneVerified ?? false,
                onClose: _closeDrawer,
                notificationBadgeCount: unreadNotifications,
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
                onPayoutSettings: () {
                  _closeDrawer();
                  context.push(AppRoutes.vendorPayout);
                },
                onChangePassword: () {
                  _closeDrawer();
                  ChangePasswordSheet.show(context);
                },
                onPrivacyPolicy: () {},
                onHelpSupport: () {
                  _closeDrawer();
                  context.push(AppRoutes.helpSupport);
                },
                onReport: () {
                  _closeDrawer();
                  context.push(AppRoutes.myReports, extra: ReportRole.vendor);
                },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  Future<void> _fetchLocation() async {
    final result = await LocationHelper.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = result.address);
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
          AppToast.show(
            context,
            isSuccess: false,
            title: 'No Internet Connection',
            subtitle: 'Please check your network connection and try again.',
          );
        }
        return;
      }

      // 2. Check location availability + fetch a fresh, live fix — this
      // must not reuse the header's cached _currentLocation, since the
      // vendor may have moved since the dashboard first loaded.
      final result = await LocationHelper.getCurrentLocation(
        resolveAddress: false,
      );

      switch (result.status) {
        case LocationStatus.serviceDisabled:
          if (mounted) {
            AppToast.show(
              context,
              isSuccess: false,
              title: 'Location Services Disabled',
              subtitle:
                  'Enable location services so customers can find your store.',
            );
          }
          return;
        case LocationStatus.permissionDenied:
        case LocationStatus.permissionDeniedForever:
          if (mounted) {
            AppToast.show(
              context,
              isSuccess: false,
              title: 'Location Required',
              subtitle:
                  'Enable location services so customers can find your store.',
            );
          }
          return;
        case LocationStatus.timeout:
        case LocationStatus.error:
          if (mounted) {
            AppToast.show(
              context,
              isSuccess: false,
              title: 'Unable to Determine Location',
              subtitle:
                  'Could not get your current location. Please try again.',
            );
          }
          return;
        case LocationStatus.success:
          break;
      }

      // 3. All checks passed — open the store
      await ref.read(dashboardProvider.notifier).toggleStore(true);

      if (mounted) {
        AppToast.show(
          context,
          isSuccess: true,
          title: 'Store Open',
          subtitle:
              'You\'re ready to receive orders! Customers can now find you.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
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
    ref.listen(dashboardProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppToast.show(
          context,
          isSuccess: false,
          title: 'Something Went Wrong',
          subtitle: next.errorMessage!,
        );
      }
    });
    final state = ref.watch(dashboardProvider);
    final w = MediaQuery.sizeOf(context).width;
    final h = w * 0.05;
    final profile = widget.vendorProfile;
    final location = _currentLocation ?? profile?.businessAddress;
    final hasUnreadNotifications =
        context.watch<NotificationViewmodel>().unreadCount > 0;

    // `is_profile_complete` is the backend's own boolean form of
    // `missing_profile_fields.isEmpty` — trust it directly rather than
    // re-deriving completeness client-side from separate sub-signals.
    final setupIncomplete = profile?.isProfileComplete != true;

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
                  imageUrl: widget.vendorProfile?.logoUrl,
                  onDrawerTap: widget.onDrawerTap,
                  hasUnreadNotifications: hasUnreadNotifications,
                  onNotificationTap: () => Navigator.of(context).push(
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
                  ),
                  onAvatarTap: widget.onAvatarTap,
                ),
                SizedBox(height: w * 0.05),

                // Greeting
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
                SizedBox(height: w * 0.035),

                // Location / hours / radius pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      if (location != null) ...[
                        _InfoPill(label: location, w: w, showDot: true),
                        SizedBox(width: w * 0.02),
                      ],
                      if (profile != null) ...[
                        _InfoPill(
                          label:
                              '${profile.openingTime} – ${profile.closingTime}',
                          w: w,
                        ),
                        SizedBox(width: w * 0.02),
                        //["Removed radius pill for vendors "]
                        // _InfoPill(
                        //   label: profile.deliveryRadiusKm > 0
                        //       ? '${profile.deliveryRadiusKm}km Radius'
                        //       : 'Radius not set',
                        //   w: w,
                        //   muted: profile.deliveryRadiusKm <= 0,
                        // ),
                      ],
                    ],
                  ),
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

                SizedBox(height: w * 0.05),
                if (setupIncomplete && profile != null)
                  SetupProgressCard(
                    steps: buildVendorSetupSteps(
                      profile,
                      onBusinessProfile: () {
                        if (widget.onAvatarTap != null) {
                          widget.onAvatarTap!();
                        } else {
                          context.push(AppRoutes.vendorKyc);
                        }
                      },
                      onDocuments: () =>
                          context.push(AppRoutes.vendorKyc, extra: 1),
                      onPayouts: () => context.push(AppRoutes.vendorPayout),
                    ),
                  )
                else
                  StoreToggleCard(
                    isOpen: state.storeOpen,
                    isLoading: _isTogglingStore,
                    onToggle: _handleStoreToggle,
                    revenue: state.todayRevenue,
                    orders: '${state.activeOrderCount}',
                    rating: profile?.rating.toString() ?? state.avgRating,
                  ),

                if (setupIncomplete) ...[
                  SizedBox(height: w * 0.04),
                  _SetupPendingStoreRow(w: w),
                ],

                if (state.activeOrders.any(
                  (o) => o.status == OrderStatus.pending,
                )) ...[
                  SizedBox(height: w * 0.05),
                  Builder(
                    builder: (_) {
                      final newest = state.activeOrders.firstWhere(
                        (o) => o.status == OrderStatus.pending,
                      );
                      return NewOrderBanner(
                        orderId: newest.id,
                        amount: newest.amount,
                        customerName: newest.customerName,
                        itemCount: newest.itemList.length,
                        secondsLeft: 87,
                        onTap: () {},
                        onAccept: () => ref
                            .read(dashboardProvider.notifier)
                            .acceptOrder(newest.id),
                      );
                    },
                  ),
                ],

                SizedBox(height: w * 0.06),
                _ActiveOrdersLabel(
                  count: state.activeOrders.length,
                  onViewAll: widget.onViewAllOrders,
                ),
                SizedBox(height: w * 0.025),
              ],
            ),
          ),
        ),

        // ── Active Orders List ──
        if (state.activeOrders.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.28),
            sliver: SliverToBoxAdapter(
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: Radius.circular(w * 0.05),
                strokeWidth: 1.5,
                dashPattern: const [6, 5],
                color: AppColors.border,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.05),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: w * 0.08,
                      horizontal: w * 0.06,
                    ),
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(w * 0.045),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedShoppingBag01,
                            size: w * 0.07,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: w * 0.035),
                        Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Mukta',
                          ),
                        ),
                        SizedBox(height: w * 0.012),
                        Text(
                          'New orders land here the moment you go live.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: AppColors.textSecondary,
                            fontFamily: 'Mukta',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final order = state.activeOrders[index];
                final notifier = ref.read(dashboardProvider.notifier);
                return Padding(
                  padding: EdgeInsets.only(bottom: w * 0.035),
                  child: OrderCard(
                    order: order,
                    onTap: () {},
                    onAccept: () => notifier.acceptOrder(order.id),
                    onDecline: () => notifier.rejectOrder(order.id),
                    onMarkPreparing: () => notifier.markPreparing(order.id),
                    onMarkReady: () => notifier.markReady(order.id),
                    onMarkOutForDelivery: () =>
                        notifier.markOutForDelivery(order.id),
                    onMarkDelivered: () => notifier.markDelivered(order.id),
                    onCancel: () => notifier.cancelOrder(order.id),
                  ),
                );
              }, childCount: state.activeOrders.length),
            ),
          ),
      ],
    );
  }
}

// ─── Location / hours / radius pill ─────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final String label;
  final double w;
  final bool showDot;
  final bool muted;

  const _InfoPill({
    required this.label,
    required this.w,
    this.showDot = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.032, vertical: w * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: w * 0.018,
              height: w * 0.018,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: w * 0.018),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w * 0.32),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.03,
                fontWeight: FontWeight.w700,
                color: muted ? AppColors.textHint : AppColors.textPrimary,
                fontFamily: 'Mukta',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Disabled store row shown while setup is incomplete ────────────────

class _SetupPendingStoreRow extends StatelessWidget {
  final double w;
  const _SetupPendingStoreRow({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.02,
            height: w * 0.02,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store closed',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Mukta',
                  ),
                ),
                Text(
                  'Opens once verification clears',
                  style: TextStyle(
                    fontSize: w * 0.028,
                    color: AppColors.textSecondary,
                    fontFamily: 'Mukta',
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Opacity(
              opacity: 0.5,
              child: Switch(
                value: false,
                onChanged: null,
                activeThumbColor: AppColors.primary,
              ),
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
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.025),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border(left: BorderSide(color: color, width: 3)),
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
