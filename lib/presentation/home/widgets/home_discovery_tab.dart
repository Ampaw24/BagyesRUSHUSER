import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/router/app_navigator.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import '../../../features/consumer/restaurant/presentation/widgets/food_category_chip.dart';
import '../../../features/consumer/restaurant/presentation/widgets/restaurant_card.dart';
import 'promo_banner_section.dart';
import 'popular_restaurants_row.dart';
import 'quick_service_chip.dart';
import 'shimmer_card.dart';

class HomeDiscoveryTab extends ConsumerStatefulWidget {
  final VoidCallback? onDrawerTap;
  const HomeDiscoveryTab({super.key, this.onDrawerTap});

  @override
  ConsumerState<HomeDiscoveryTab> createState() => _HomeDiscoveryTabState();
}

class _HomeDiscoveryTabState extends ConsumerState<HomeDiscoveryTab> {
  String? _currentLocation;
  Position? _gpsPosition;
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
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
    final count = (featured.valueOrNull?.length ?? 0) + 1;
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
          appLogger.w(
            '[Location] Permission denied (status: $permission) — skipping location fetch',
          );
          setState(() => _currentLocation = 'Location unavailable');
          return;
        }
      }
      _gpsPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      appLogger.i(
        '[Location] Home coordinates — '
        'lat: ${_gpsPosition!.latitude}, lng: ${_gpsPosition!.longitude}, '
        'accuracy: ${_gpsPosition!.accuracy.toStringAsFixed(1)} m',
      );
      final placemarks = await placemarkFromCoordinates(
        _gpsPosition!.latitude,
        _gpsPosition!.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      if (place != null) {
        appLogger.d(
          '[Location] Placemark fields — '
          'name: ${place.name} | '
          'street: ${place.street} | '
          'subLocality: ${place.subLocality} | '
          'locality: ${place.locality} | '
          'subAdminArea: ${place.subAdministrativeArea} | '
          'adminArea: ${place.administrativeArea} | '
          'country: ${place.country}',
        );
      }
      final resolved = _resolveAddress(place, _gpsPosition!);
      appLogger.d('[Location] Resolved address: $resolved');
      setState(() => _currentLocation = resolved);
    } catch (e, s) {
      appLogger.e(
        '[Location] Failed to fetch home location',
        error: e,
        stackTrace: s,
      );
      final fallback = _gpsPosition != null
          ? '${_gpsPosition!.latitude.toStringAsFixed(4)}, ${_gpsPosition!.longitude.toStringAsFixed(4)}'
          : 'Location unavailable';
      setState(() => _currentLocation = fallback);
    }
  }

  String _resolveAddress(Placemark? p, Position pos) {
    if (p != null) {
      final sub = p.subLocality?.isNotEmpty == true ? p.subLocality : null;
      final locality = p.locality?.isNotEmpty == true ? p.locality : null;
      final area = p.administrativeArea?.isNotEmpty == true
          ? p.administrativeArea
          : null;
      final country = p.country?.isNotEmpty == true ? p.country : null;
      final street = p.street?.isNotEmpty == true ? p.street : null;

      if (street != null && locality != null) return '$street, $locality';
      if (street != null) return street;
      if (sub != null && locality != null) return '$sub, $locality';
      if (sub != null) return sub;
      final parts = [locality, area ?? country].whereType<String>().toList();
      if (parts.isNotEmpty) return parts.join(', ');
      if (country != null) return country;
    }
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final hPad = w * 0.05;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final user = context.watch<CurrentUserProvider>().user;
    final firstName = user?.profile?.firstName ?? '';
    final lastName = user?.profile?.lastName ?? '';
    final avatarInitials =
        '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}'
        '${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';

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
                            'Hey, ${firstName.isNotEmpty ? user?.profile?.firstName : 'there'} 👋',
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
                    CircleAvatar(
                      radius: w * 0.05,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        avatarInitials.isNotEmpty ? avatarInitials : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.035,
                          fontWeight: FontWeight.w600,
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
                    QuickServiceChip(
                      emoji: '📦',
                      label: 'Send',
                      onTap: () => AppNavigator.toSendPackages(context),
                    ),
                    SizedBox(width: w * 0.025),
                    //Todo: Add back grocery delivery when feature is ready and uncomment import at top
                    // QuickServiceChip(
                    //   emoji: '🛒',
                    //   label: 'Grocery',
                    //   onTap: () => AppNavigator.toGroceryDelivery(context),
                    // ),
                    SizedBox(width: w * 0.025),
                    QuickServiceChip(
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
          child: PromoBannerSection(
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
            child: ref
                .watch(categoriesProvider)
                .when(
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    itemCount: FoodCategory.all.length,
                    separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
                    itemBuilder: (_, i) => FoodCategoryChip(
                      category: FoodCategory.all[i],
                      isSelected: selectedCategory == FoodCategory.all[i].label,
                      onTap: () {},
                    ),
                  ),
                  error: (_, _) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    itemCount: FoodCategory.all.length,
                    separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
                    itemBuilder: (_, i) {
                      final cat = FoodCategory.all[i];
                      return FoodCategoryChip(
                        category: cat,
                        isSelected: selectedCategory == cat.label,
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state =
                                cat.label,
                      );
                    },
                  ),
                  data: (categories) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      return FoodCategoryChip(
                        category: cat,
                        isSelected: selectedCategory == cat.label,
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state =
                                cat.label,
                      );
                    },
                  ),
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
        const SliverToBoxAdapter(child: PopularRestaurantsRow()),

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
                  child: ShimmerCard(width: double.infinity, height: w * 0.5),
                ),
              ),
            ),
          )
        else if (restaurantsAsync.hasError)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(w * 0.05),
                child: const Text('Could not load restaurants'),
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
