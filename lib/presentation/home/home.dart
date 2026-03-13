import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../constant/app_theme.dart';
import '../../core/router/app_navigator.dart';
import '../../core/router/app_routes.dart';
import '../../src/vendor/view/widgets/floating_nav_bar.dart';
import '../../features/consumer/restaurant/presentation/providers/restaurant_providers.dart';
import '../../features/consumer/restaurant/presentation/widgets/food_category_chip.dart';
import '../../features/consumer/restaurant/presentation/widgets/restaurant_card.dart';
import '../../features/consumer/orders/presentation/views/consumer_orders_view.dart';
import '../../features/consumer/search/presentation/views/consumer_search_view.dart';
import '../../features/consumer/profile/presentation/views/consumer_profile_view.dart';

// ─── Main Shell ───────────────────────────────────────────────────────────

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _navIndex = 0;
  bool _drawerOpen = false;

  static const _navItems = [
    NavItem(icon: HugeIcons.strokeRoundedHome11, label: 'Home'),
    NavItem(icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'Orders'),
    NavItem(icon: HugeIcons.strokeRoundedSearch01, label: 'Search'),
    NavItem(icon: HugeIcons.strokeRoundedUser, label: 'Profile'),
  ];

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

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
          'All your order history and personal data will be permanently deleted.',
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
            onPressed: () => Navigator.of(ctx).pop(),
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

  @override
  Widget build(BuildContext context) {
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
                  _HomeDiscoveryTab(onDrawerTap: _openDrawer),
                  const ConsumerOrdersView(),
                  const ConsumerSearchView(),
                  const ConsumerProfileView(),
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
              _CustomerDrawer(
                userName: 'Ampaw Justice',
                userEmail: 'john@bagyesrush.com',
                initials: 'JD',
                isVerified: true,
                onClose: _closeDrawer,
                onProfile: () {
                  _closeDrawer();
                  setState(() => _navIndex = 3);
                },
                onOrders: () {
                  _closeDrawer();
                  setState(() => _navIndex = 1);
                },
                onNotifications: () {
                  _closeDrawer();
                  context.push(AppRoutes.notifications);
                },
                onWallet: () {
                  _closeDrawer();
                  context.push(AppRoutes.wallet);
                },
                onPaymentMethods: () => _closeDrawer(),
                onInviteFriends: () {
                  _closeDrawer();
                  AppNavigator.toInviteFriend(context);
                },
                onPrivacyPolicy: () => _closeDrawer(),
                onHelpSupport: () => _closeDrawer(),
                onDeleteAccount: _showDeleteAccountDialog,
                onLogout: () {
                  _closeDrawer();
                  context.go(AppRoutes.login);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Discovery Tab ───────────────────────────────────────────────────

class _HomeDiscoveryTab extends ConsumerStatefulWidget {
  final VoidCallback? onDrawerTap;

  const _HomeDiscoveryTab({this.onDrawerTap});

  @override
  ConsumerState<_HomeDiscoveryTab> createState() => _HomeDiscoveryTabState();
}

class _HomeDiscoveryTabState extends ConsumerState<_HomeDiscoveryTab> {
  String? _currentLocation;
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    // Auto-scroll banners every 4 seconds
    Future.delayed(const Duration(seconds: 4), _autoscrollBanner);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _autoscrollBanner() {
    if (!mounted || !_bannerController.hasClients) return;
    final featured = ref.read(featuredRestaurantsProvider);
    final count = featured.valueOrNull?.length ?? 0;
    if (count < 2) return;
    final next = (_bannerIndex + 1) % count;
    _bannerController.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoscrollBanner);
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
          if (place.locality?.isNotEmpty == true) place.locality!,
          if (place.administrativeArea?.isNotEmpty == true)
            place.administrativeArea!,
        ];
        if (parts.isNotEmpty) {
          setState(() => _currentLocation = parts.join(', '));
        }
      }
    } catch (_) {
      setState(() => _currentLocation = 'Accra, Ghana');
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final hPad = w * 0.05;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return CustomScrollView(
      slivers: [
        // ── Fixed header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, w * 0.03, hPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onDrawerTap,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.022),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(w * 0.03),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMenu02,
                          color: AppColors.textPrimary,
                          size: w * 0.055,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hey, Safo 👋',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: w * 0.008),
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedLocation01,
                                color: AppColors.primary,
                                size: w * 0.035,
                              ),
                              SizedBox(width: w * 0.01),
                              Expanded(
                                child: Text(
                                  _currentLocation ?? 'Fetching location...',
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primary,
                                size: w * 0.04,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.notifications),
                      child: Container(
                        padding: EdgeInsets.all(w * 0.022),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(w * 0.03),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          color: AppColors.textPrimary,
                          size: w * 0.055,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.025),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
                      child: CircleAvatar(
                        radius: w * 0.05,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          'JD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.045),

                // Search bar
                GestureDetector(
                  onTap: () => context.push(AppRoutes.consumerSearch),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: w * 0.038,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.04),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: w * 0.055,
                        ),
                        SizedBox(width: w * 0.03),
                        Expanded(
                          child: Text(
                            'Search restaurants, dishes...',
                            style: TextStyle(
                              fontSize: w * 0.035,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(w * 0.018),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: w * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: w * 0.045),

                // ── Service shortcuts ──
                Row(
                  children: [
                    _QuickServiceChip(
                      emoji: '📦',
                      label: 'Send',
                      onTap: () => AppNavigator.toSendPackages(context),
                    ),
                    SizedBox(width: w * 0.025),
                    _QuickServiceChip(
                      emoji: '🛒',
                      label: 'Grocery',
                      onTap: () => AppNavigator.toGroceryDelivery(context),
                    ),
                    SizedBox(width: w * 0.025),
                    _QuickServiceChip(
                      emoji: '🎁',
                      label: 'Invite',
                      onTap: () => AppNavigator.toInviteFriend(context),
                    ),
                    SizedBox(width: w * 0.025),
                    _QuickServiceChip(
                      emoji: '💳',
                      label: 'Wallet',
                      onTap: () => context.push(AppRoutes.wallet),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.045),
              ],
            ),
          ),
        ),

        // ── Promo banners ──
        SliverToBoxAdapter(
          child: _PromoBannerSection(
            controller: _bannerController,
            currentIndex: _bannerIndex,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: w * 0.045)),

        // ── Food categories ──
        SliverToBoxAdapter(
          child: SizedBox(
            height: w * 0.115,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              itemCount: FoodCategory.all.length,
              separatorBuilder: (_, s) => SizedBox(width: w * 0.025),
              itemBuilder: (ctx, i) {
                final cat = FoodCategory.all[i];
                return FoodCategoryChip(
                  category: cat,
                  isSelected: selectedCategory == cat.label,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        cat.label;
                  },
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: w * 0.045)),

        // ── Popular restaurants (horizontal scroll) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Near You',
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.consumerSearch),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: w * 0.033,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: w * 0.03)),
        SliverToBoxAdapter(child: _PopularRestaurantsRow()),

        SliverToBoxAdapter(child: SizedBox(height: w * 0.045)),

        // ── All restaurants (filtered by category) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Text(
              selectedCategory == 'All'
                  ? 'All Restaurants'
                  : '$selectedCategory Restaurants',
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: w * 0.03)),
        if (restaurantsAsync.isLoading)
          SliverToBoxAdapter(
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.04),
                  child: _ShimmerCard(width: double.infinity, height: w * 0.5),
                ),
              ),
            ),
          )
        else if (restaurantsAsync.hasError)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(w * 0.05),
                child: Text('Could not load restaurants'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            sliver: SliverList.builder(
              itemCount: restaurantsAsync.value!.length,
              itemBuilder: (ctx, i) {
                final r = restaurantsAsync.value![i];
                return RestaurantListCard(
                  restaurant: r,
                  onTap: () =>
                      context.push(AppRoutes.restaurantDetailPath(r.id)),
                );
              },
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: h * 0.12)),
      ],
    );
  }
}

// ─── Promo Banner Section ─────────────────────────────────────────────────

class _PromoBannerSection extends ConsumerWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PromoBannerSection({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final featured = ref.watch(featuredRestaurantsProvider);

    return featured.when(
      loading: () => Container(
        margin: EdgeInsets.symmetric(horizontal: w * 0.05),
        height: w * 0.45,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(w * 0.045),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (restaurants) {
        if (restaurants.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: w * 0.48,
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                itemCount: restaurants.length,
                itemBuilder: (ctx, i) {
                  final r = restaurants[i];
                  return GestureDetector(
                    onTap: () =>
                        context.push(AppRoutes.restaurantDetailPath(r.id)),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: w * 0.05),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(w * 0.045),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(w * 0.045),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              r.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: AppColors.shimmerBase),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xB3000000), // black ~70%
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: w * 0.045,
                              left: w * 0.045,
                              right: w * 0.045,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r.promoText != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.03,
                                        vertical: w * 0.012,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        r.promoText!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: w * 0.028,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: w * 0.02),
                                  Text(
                                    r.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: w * 0.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${r.deliveryTimeLabel} · GHS ${r.deliveryFee.toStringAsFixed(0)} delivery',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: w * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: w * 0.025),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                restaurants.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: w * 0.008),
                  width: i == currentIndex ? w * 0.05 : w * 0.02,
                  height: w * 0.018,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Popular Restaurants Row (horizontal scroll) ──────────────────────────

class _PopularRestaurantsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final nearby = ref.watch(nearbyRestaurantsProvider);

    return nearby.when(
      loading: () => SizedBox(
        height: w * 0.6,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(width: w * 0.035),
          itemBuilder: (_, i) => _ShimmerCard(width: w * 0.55),
        ),
      ),
      error: (_, e) => const SizedBox.shrink(),
      data: (restaurants) => SizedBox(
        height: w * 0.72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          itemCount: restaurants.length,
          separatorBuilder: (_, s) => SizedBox(width: w * 0.035),
          itemBuilder: (ctx, i) => RestaurantCard(
            restaurant: restaurants[i],
            width: w * 0.55,
            onTap: () =>
                context.push(AppRoutes.restaurantDetailPath(restaurants[i].id)),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Service Chip ───────────────────────────────────────────────────

class _QuickServiceChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickServiceChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.03),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: w * 0.05)),
              SizedBox(height: w * 0.01),
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer placeholder card ─────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final double width;
  final double? height;

  const _ShimmerCard({required this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      width: width,
      height: height ?? w * 0.62,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
    );
  }
}

// ─── Customer Drawer (unchanged from original) ────────────────────────────

class _CustomerDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final bool isVerified;
  final VoidCallback onClose;
  final VoidCallback? onProfile;
  final VoidCallback? onOrders;
  final VoidCallback? onNotifications;
  final VoidCallback? onWallet;
  final VoidCallback? onPaymentMethods;
  final VoidCallback? onInviteFriends;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onDeleteAccount;
  final VoidCallback? onLogout;

  const _CustomerDrawer({
    required this.userName,
    required this.userEmail,
    required this.initials,
    this.isVerified = false,
    required this.onClose,
    this.onProfile,
    this.onOrders,
    this.onNotifications,
    this.onWallet,
    this.onPaymentMethods,
    this.onInviteFriends,
    this.onPrivacyPolicy,
    this.onHelpSupport,
    this.onDeleteAccount,
    this.onLogout,
  });

  @override
  State<_CustomerDrawer> createState() => _CustomerDrawerState();
}

class _CustomerDrawerState extends State<_CustomerDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutExpo),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _blurAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  Animation<double> _staggeredFade(int index) {
    final start = 0.3 + (index * 0.07);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = 0.3 + (index * 0.07);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final drawerWidth = w * 0.78;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.35 * _fadeAnimation.value,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(_slideAnimation.value * drawerWidth, 0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: SafeArea(
        child: Container(
          width: drawerWidth,
          margin: EdgeInsets.symmetric(
            vertical: h * 0.02,
            horizontal: w * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(8, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                _DrawerHeader(
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                  initials: widget.initials,
                  isVerified: widget.isVerified,
                  onClose: _close,
                  animation: _controller,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: const Divider(color: AppColors.divider, height: 1),
                ),
                SizedBox(height: w * 0.025),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedUser,
                                label: 'My Profile',
                                onTap: widget.onProfile,
                                fadeAnim: _staggeredFade(0),
                                slideAnim: _staggeredSlide(0),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedDeliveryBox01,
                                label: 'My Orders',
                                onTap: widget.onOrders,
                                fadeAnim: _staggeredFade(1),
                                slideAnim: _staggeredSlide(1),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedNotification01,
                                label: 'Notifications',
                                onTap: widget.onNotifications,
                                fadeAnim: _staggeredFade(2),
                                slideAnim: _staggeredSlide(2),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedWallet01,
                                label: 'Wallet',
                                onTap: widget.onWallet,
                                fadeAnim: _staggeredFade(3),
                                slideAnim: _staggeredSlide(3),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedCreditCard,
                                label: 'Payment Methods',
                                onTap: widget.onPaymentMethods,
                                fadeAnim: _staggeredFade(4),
                                slideAnim: _staggeredSlide(4),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedMoneyBag01,
                                label: 'Invite Friends',
                                onTap: widget.onInviteFriends,
                                fadeAnim: _staggeredFade(5),
                                slideAnim: _staggeredSlide(5),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedShieldKey,
                                label: 'Privacy Policy',
                                onTap: widget.onPrivacyPolicy,
                                fadeAnim: _staggeredFade(6),
                                slideAnim: _staggeredSlide(6),
                              ),
                              _DrawerTile(
                                icon: HugeIcons.strokeRoundedHelpCircle,
                                label: 'Help & Support',
                                onTap: widget.onHelpSupport,
                                fadeAnim: _staggeredFade(7),
                                slideAnim: _staggeredSlide(7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                        child: const Divider(
                          color: AppColors.divider,
                          height: 1,
                        ),
                      ),
                      _DrawerTile(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: 'Delete Account',
                        color: AppColors.warning,
                        onTap: widget.onDeleteAccount,
                        fadeAnim: _staggeredFade(8),
                        slideAnim: _staggeredSlide(8),
                      ),
                      _DrawerTile(
                        icon: HugeIcons.strokeRoundedLogout01,
                        label: 'Logout',
                        color: AppColors.error,
                        onTap: widget.onLogout,
                        fadeAnim: _staggeredFade(9),
                        slideAnim: _staggeredSlide(9),
                      ),
                      SizedBox(height: h * 0.015),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final bool isVerified;
  final VoidCallback onClose;
  final AnimationController animation;

  const _DrawerHeader({
    required this.userName,
    required this.userEmail,
    required this.initials,
    required this.isVerified,
    required this.onClose,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    final avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );
    final textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.055, w * 0.06, w * 0.04, w * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: AppColors.textSecondary,
                  size: w * 0.04,
                ),
              ),
            ),
          ),
          SizedBox(height: w * 0.02),
          Row(
            children: [
              ScaleTransition(
                scale: avatarScale,
                child: CircleAvatar(
                  radius: w * 0.07,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: FadeTransition(
                  opacity: textFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: w * 0.042,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            SizedBox(width: w * 0.012),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                              color: AppColors.info,
                              size: w * 0.045,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: w * 0.003),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final iconColor = color ?? AppColors.primary;
    final labelColor = color ?? AppColors.textPrimary;

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withValues(alpha: 0.08),
            highlightColor: iconColor.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.055,
                vertical: w * 0.034,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: iconColor,
                      size: w * 0.052,
                    ),
                  ),
                  SizedBox(width: w * 0.035),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (color == null)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: AppColors.primary,
                      size: w * 0.038,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
