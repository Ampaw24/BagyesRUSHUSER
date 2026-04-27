import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/addon.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/widgets/item_addon_sheet.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/widgets/menu_item_card.dart';

class RestaurantDetailView extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailView> createState() =>
      _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends ConsumerState<RestaurantDetailView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _lastCategoryCount = 0;

  /// Key for the cart FAB — used to trigger bounce animations.
  final GlobalKey<_CartFabState> _cartFabKey = GlobalKey<_CartFabState>();

  @override
  void initState() {
    super.initState();
    // Listen for menu data changes outside of build() to avoid
    // setState-during-build lifecycle violations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForMenuChanges();
    });
  }

  /// Attach a listener to the menu provider so tab init happens outside
  /// of the render pipeline.
  void _listenForMenuChanges() {
    ref.listenManual(
      restaurantMenuProvider(widget.restaurantId),
      (prev, next) {
        next.whenData((menu) {
          final categories = menu.keys.toList();
          if (categories.length != _lastCategoryCount && categories.isNotEmpty) {
            _rebuildTabController(categories.length);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _rebuildTabController(int count) {
    _tabController?.dispose();
    _lastCategoryCount = count;
    _tabController = TabController(length: count, vsync: this);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _onAddItem(Restaurant restaurant, MenuItem item) async {
    final cart = ref.read(cartProvider);
    final hasConflict =
        cart.restaurantId != null && cart.restaurantId != restaurant.id;

    if (item.hasAddons) {
      final result = await ItemAddonSheet.show(context, item);
      if (result == null || !mounted) return;
      if (hasConflict) {
        _showReplaceCartDialog(
          restaurant,
          item,
          quantity: result.quantity,
          selectedAddons: result.selectedAddons,
        );
        return;
      }
      ref.read(cartProvider.notifier).addItem(
            restaurant,
            item,
            quantity: result.quantity,
            selectedAddons: result.selectedAddons,
          );
    } else {
      if (hasConflict) {
        _showReplaceCartDialog(restaurant, item);
        return;
      }
      ref.read(cartProvider.notifier).addItem(restaurant, item);
    }

    // Haptic feedback + bounce animation on the cart FAB
    HapticFeedback.lightImpact();
    _cartFabKey.currentState?.bounce();
  }

  void _showReplaceCartDialog(
    Restaurant restaurant,
    MenuItem item, {
    int quantity = 1,
    List<SelectedAddon> selectedAddons = const [],
  }) {
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
              ref.read(cartProvider.notifier).clearAndAdd(
                    restaurant,
                    item,
                    quantity: quantity,
                    selectedAddons: selectedAddons,
                  );
              HapticFeedback.lightImpact();
              _cartFabKey.currentState?.bounce();
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
                // Tab controller is now managed via ref.listenManual
                // in initState — no setState inside build.
                return _buildBody(context, restaurant, menu, cart, w);
              },
            );
          },
        ),
        // ── Cart FAB ──
        floatingActionButton: cart.isEmpty
            ? null
            : _CartFab(
                key: _cartFabKey,
                cart: cart,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.cart);
                },
              ),
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
          forceElevated: innerBoxIsScrolled,
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
                // Hero-wrap the restaurant image for smooth transition
                Hero(
                  tag: 'restaurant_image_${restaurant.id}',
                  child: Image.network(
                    restaurant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.shimmerBase,
                    ),
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
          bottom: (categories.isNotEmpty && _tabController != null)
              ? TabBar(
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
                  tabs: categories.map((c) => Tab(text: c)).toList(),
                )
              : null,
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
                      onRemove: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.id, qty - 1);
                      },
                      onTapCard: item.hasAddons
                          ? () => _onAddItem(restaurant, item)
                          : null,
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

/// Cart floating action button with bounce animation on item add.
class _CartFab extends StatefulWidget {
  final CartState cart;
  final VoidCallback onTap;

  const _CartFab({super.key, required this.cart, required this.onTap});

  @override
  State<_CartFab> createState() => _CartFabState();
}

class _CartFabState extends State<_CartFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  /// Trigger a bounce animation — called from parent via GlobalKey.
  void bounce() {
    _bounceCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Text(
                      '${widget.cart.totalItems}',
                      key: ValueKey(widget.cart.totalItems),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.032,
                      ),
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
                  'GHS ${widget.cart.total.toStringAsFixed(2)}',
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
      ),
    );
  }
}
