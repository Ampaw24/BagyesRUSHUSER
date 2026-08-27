import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import '../../../features/consumer/restaurant/presentation/widgets/food_category_chip.dart';
import '../../../features/consumer/restaurant/presentation/widgets/restaurant_card.dart';
import '../../../src/notification/viewmodel/notification_viewmodel.dart';
import 'promo_banner_section.dart';
import 'popular_restaurants_row.dart';
import 'shimmer_card.dart';
import '../../../core/utils/location_helper.dart';

class HomeDiscoveryTab extends ConsumerStatefulWidget {
  final VoidCallback? onDrawerTap;
  const HomeDiscoveryTab({super.key, this.onDrawerTap});

  @override
  ConsumerState<HomeDiscoveryTab> createState() => _HomeDiscoveryTabState();
}

class _HomeDiscoveryTabState extends ConsumerState<HomeDiscoveryTab> {
  String? _currentLocation;
  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    Future.delayed(const Duration(seconds: 4), _autoscrollBanner);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Trigger load-more when 200px from the bottom
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final category = ref.read(selectedCategoryProvider);
      ref.read(vendorListProvider(category).notifier).loadMore();
    }
  }

  void _autoscrollBanner() {
    if (!mounted || !_bannerController.hasClients) return;
    final banners = ref.read(homeBannersProvider);
    final count = banners.valueOrNull?.banners.length ?? 0;
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
    final result = await LocationHelper.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = result['address'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final hPad = w * 0.05;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final listAsync = ref.watch(vendorListProvider(selectedCategory));
    final user = context.watch<CurrentUserProvider>().user;
    final hasUnreadNotifications =
        context.watch<NotificationViewmodel>().unreadCount > 0;
    final firstName = user?.profile?.firstName ?? '';
    final lastName = user?.profile?.lastName ?? '';
    final avatarInitials =
        '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}'
        '${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
    final String? avatarUrl = user?.profile?.profilePictureUrl;

    return CustomScrollView(
      controller: _scrollController,
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedNotification01,
                              color: AppColors.textPrimary,
                              size: w * 0.055,
                            ),
                            if (hasUnreadNotifications)
                              Positioned(
                                top: -1,
                                right: -1,
                                child: Container(
                                  width: w * 0.022,
                                  height: w * 0.022,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.025),
                    CircleAvatar(
                      radius: w * 0.05,
                      backgroundColor: AppColors.primary,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              avatarInitials.isNotEmpty ? avatarInitials : 'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.035,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
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
            height: w * 0.088,
            child: ref.watch(categoriesProvider).when(
                  loading: () => _categoryShimmer(w),
                  error: (_, _) => _staticCategories(w, selectedCategory),
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
                        onTap: () => ref
                            .read(selectedCategoryProvider.notifier)
                            .updateCategory(cat.label),
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

        // ── Section header ──
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

        // ── Restaurant list (paginated) ──
        ..._buildRestaurantSliver(context, listAsync, w),

        // ── Load-more indicator ──
        SliverToBoxAdapter(
          child: listAsync.valueOrNull?.isLoadingMore == true
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: w * 0.06),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : SizedBox(height: h * 0.12),
        ),
      ],
    );
  }

  List<Widget> _buildRestaurantSliver(
    BuildContext context,
    AsyncValue<VendorListState> listAsync,
    double w,
  ) {
    // Loading first page
    if (listAsync.isLoading && listAsync.valueOrNull == null) {
      return [
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
        ),
      ];
    }

    // Error (no cached data)
    if (listAsync.hasError && listAsync.valueOrNull == null) {
      return [
        SliverToBoxAdapter(
          child: _ErrorState(
            w: w,
            onRetry: () {
              final category = ref.read(selectedCategoryProvider);
              ref.invalidate(vendorListProvider(category));
            },
          ),
        ),
      ];
    }

    final state = listAsync.valueOrNull;
    final restaurants = state?.restaurants ?? [];

    // Empty state
    if (restaurants.isEmpty) {
      return [
        SliverToBoxAdapter(child: _EmptyState(w: w)),
      ];
    }

    // Data
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        sliver: SliverList.builder(
          itemCount: restaurants.length,
          itemBuilder: (ctx, i) {
            final r = restaurants[i];
            return Padding(
              padding: EdgeInsets.only(bottom: w * 0.04),
              child: RestaurantListCard(
                restaurant: r,
                onTap: () => context.push(AppRoutes.restaurantDetailPath(r.id)),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _categoryShimmer(double w) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        itemCount: FoodCategory.all.length,
        separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
        itemBuilder: (_, i) => ShimmerCard(width: w * 0.22, height: w * 0.088),
      );

  Widget _staticCategories(double w, String selectedCategory) =>
      ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        itemCount: FoodCategory.all.length,
        separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
        itemBuilder: (_, i) {
          final cat = FoodCategory.all[i];
          return FoodCategoryChip(
            category: cat,
            isSelected: selectedCategory == cat.label,
            onTap: () => ref
                .read(selectedCategoryProvider.notifier)
                .updateCategory(cat.label),
          );
        },
      );
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final double w;
  const _EmptyState({required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.12, horizontal: w * 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.06),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedRestaurant01,
              color: AppColors.primary.withValues(alpha: 0.5),
              size: w * 0.12,
            ),
          ),
          SizedBox(height: w * 0.05),
          Text(
            'No restaurants found',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.02),
          Text(
            'We couldn\'t find any restaurants in this category.\nTry a different one.',
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final double w;
  final VoidCallback onRetry;
  const _ErrorState({required this.w, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.1, horizontal: w * 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedWifiError01,
              color: AppColors.error.withValues(alpha: 0.6),
              size: w * 0.1,
            ),
          ),
          SizedBox(height: w * 0.045),
          Text(
            'Could not load restaurants',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Check your internet connection and try again.',
            style: TextStyle(
              fontSize: w * 0.032,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: w * 0.05),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.06,
                vertical: w * 0.032,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Text(
                'Try again',
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
