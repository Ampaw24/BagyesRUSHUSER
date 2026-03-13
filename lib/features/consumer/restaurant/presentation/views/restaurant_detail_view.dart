import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/providers/cart_provider.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/providers/restaurant_providers.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/widgets/menu_item_card.dart';

class RestaurantDetailView extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailView> createState() =>
      _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends ConsumerState<RestaurantDetailView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> _menuCategories = [];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabs(List<String> categories) {
    if (_menuCategories == categories) return;
    _menuCategories = categories;
    _tabController?.dispose();
    _tabController = TabController(length: categories.length, vsync: this);
    setState(() {});
  }

  void _onAddItem(Restaurant restaurant, MenuItem item) {
    final cart = ref.read(cartProvider);
    if (cart.restaurantId != null && cart.restaurantId != restaurant.id) {
      _showReplaceCartDialog(restaurant, item);
      return;
    }
    ref.read(cartProvider.notifier).addItem(restaurant, item);
  }

  void _showReplaceCartDialog(Restaurant restaurant, MenuItem item) {
    final w = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.05),
        ),
        title: const Text('Replace cart?'),
        content: Text(
          'Your cart has items from ${ref.read(cartProvider).restaurantName}. '
          'Starting a new cart will remove those items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep current'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(cartProvider.notifier)
                  .clearAndAdd(restaurant, item);
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final restaurantAsync =
        ref.watch(restaurantDetailProvider(widget.restaurantId));
    final menuAsync = ref.watch(restaurantMenuProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: restaurantAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (restaurant) {
            return menuAsync.when(
              loading: () => _buildBody(
                context, restaurant, const {}, cart, w,
              ),
              error: (e, _) =>
                  _buildBody(context, restaurant, const {}, cart, w),
              data: (menu) {
                final categories = menu.keys.toList();
                if (categories.isNotEmpty) _initTabs(categories);
                return _buildBody(context, restaurant, menu, cart, w);
              },
            );
          },
        ),
        // ── Cart FAB ──
        floatingActionButton: cart.isEmpty
            ? null
            : _CartFab(cart: cart, onTap: () => context.push(AppRoutes.cart)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Restaurant restaurant,
    Map<String, List<MenuItem>> menu,
    CartState cart,
    double w,
  ) {
    final categories = menu.keys.toList();

    return NestedScrollView(
      headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: w * 0.55,
          pinned: true,
          backgroundColor: AppColors.scaffold,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: EdgeInsets.all(w * 0.02),
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  restaurant.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.shimmerBase,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Restaurant info header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(w * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: TextStyle(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  restaurant.cuisineType,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.03),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.star_rounded,
                      color: AppColors.accent,
                      label:
                          '${restaurant.rating} (${restaurant.reviewCount})',
                    ),
                    SizedBox(width: w * 0.03),
                    _StatChip(
                      icon: Icons.access_time_rounded,
                      label: restaurant.deliveryTimeLabel,
                    ),
                    SizedBox(width: w * 0.03),
                    _StatChip(
                      icon: Icons.delivery_dining_rounded,
                      label: 'GHS ${restaurant.deliveryFee.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                if (restaurant.promoText != null) ...[
                  SizedBox(height: w * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(w * 0.03),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: w * 0.02),
                        Text(
                          restaurant.promoText!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: w * 0.033,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Tab bar
        if (categories.isNotEmpty && _tabController != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mukta',
                ),
                tabs: categories
                    .map((c) => Tab(text: c))
                    .toList(),
              ),
            ),
          ),
      ],
      body: categories.isEmpty || _tabController == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: categories.map((category) {
                final items = menu[category] ?? [];
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.05, w * 0.04, w * 0.05, w * 0.25,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final qty = cart.items
                        .where((ci) => ci.item.id == item.id)
                        .fold(0, (sum, ci) => sum + ci.quantity);
                    return MenuItemCard(
                      item: item,
                      cartQuantity: qty,
                      onAdd: () => _onAddItem(restaurant, item),
                      onRemove: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.id, qty - 1),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: w * 0.035, color: color ?? AppColors.textSecondary),
        SizedBox(width: w * 0.012),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.032,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CartFab extends StatelessWidget {
  final CartState cart;
  final VoidCallback onTap;

  const _CartFab({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.05,
            vertical: w * 0.04,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(w * 0.04),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.008,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${cart.totalItems}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.032,
                  ),
                ),
              ),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.038,
                  ),
                ),
              ),
              Text(
                'GHS ${cart.total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: w * 0.038,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.scaffold,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => old.tabBar != tabBar;
}
