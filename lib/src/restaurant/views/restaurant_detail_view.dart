import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/menu_item.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/restaurant/viewmodels/restaurant_detail_viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/widgets/item_addon_sheet.dart';
import 'package:bagyesrushappusernew/src/restaurant/widgets/menu_item_card.dart';

class RestaurantDetailView extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _lastCategoryCount = 0;

  /// Key for the cart FAB — used to trigger bounce animations.
  final GlobalKey<_CartFabState> _cartFabKey = GlobalKey<_CartFabState>();

  /// Saved reference so dispose() doesn't call context.read on an unmounted
  /// widget, and so the listener can be detached.
  CartViewModel? _cartVm;

  /// Screen-scoped — one instance per push, owned/disposed directly by this
  /// State (see the class doc on [RestaurantDetailViewModel]).
  late final RestaurantDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<RestaurantDetailViewModel>(param1: widget.restaurantId);
    _vm.addListener(_onVmChanged);
    // Listen for cart changes outside of build() to avoid
    // setState-during-build lifecycle violations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cartVm = context.read<CartViewModel>();
      _cartVm!.addListener(_onCartChanged);
    });
  }

  /// A mutation (add/update/remove) failed — the cart already rolled back
  /// to its last known-good state, this just surfaces why.
  void _onCartChanged() {
    final message = _cartVm?.errorMessage;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _cartVm!.clearError();
  }

  /// Reacts to restaurant/menu state changes: rebuilds the TabController
  /// when the menu's category count changes, and loads this vendor's cart
  /// once the restaurant (and its numeric id) is available.
  void _onVmChanged() {
    if (!mounted) return;

    final categories = _vm.state.menu.keys.toList();
    if (categories.length != _lastCategoryCount && categories.isNotEmpty) {
      _rebuildTabController(categories.length);
    }

    final restaurant = _vm.state.restaurant;
    if (restaurant != null) {
      final vendorId = _vendorId(restaurant);
      if (vendorId != null) {
        final cartVm = _cartVm ?? context.read<CartViewModel>();
        if (cartVm.cart?.vendorId != vendorId) {
          cartVm.loadCart(vendorId);
        }
      }
    }

    setState(() {});
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
    _cartVm?.removeListener(_onCartChanged);
    _vm.dispose();
    super.dispose();
  }

  /// The vendor's cart-API id (an integer, distinct from [Restaurant.id]'s
  /// ULID). Menu items likewise use their numeric-id string as
  /// [MenuItem.id] — both are required as `int`s by the cart endpoints.
  String? _vendorId(Restaurant restaurant) => restaurant.numericId?.toString();

  Future<void> _onAddItem(Restaurant restaurant, MenuItem item) async {
    if (!restaurant.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vendor is currently closed and not accepting orders.'),
        ),
      );
      return;
    }
    final vendorId = _vendorId(restaurant);
    if (vendorId == null) return;
    final cartVm = context.read<CartViewModel>();

    final bool succeeded;
    if (item.hasAddons) {
      final result = await ItemAddonSheet.show(context, item);
      if (result == null || !mounted) return;
      // CartViewModel.addItem updates local state (and the FAB) instantly,
      // before its network call resolves, so the badge/quantity bump feels
      // instant even though we still await the outcome below to report a
      // rejected mutation (e.g. server-side validation) back to the user.
      succeeded = await _addToCart(
        cartVm,
        vendorId,
        item,
        quantity: result.quantity,
        selectedAddons: result.selectedAddons,
      );
    } else {
      succeeded = await _addToCart(cartVm, vendorId, item);
    }

    if (!mounted) return;
    HapticFeedback.lightImpact();
    _cartFabKey.currentState?.bounce();

    if (!succeeded) {
      final message = cartVm.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        cartVm.clearError();
      }
    }
  }

  Future<bool> _addToCart(
    CartViewModel cartVm,
    String vendorId,
    MenuItem item, {
    int quantity = 1,
    List<SelectedAddon> selectedAddons = const [],
  }) {
    return cartVm.addItem(
      vendorId: vendorId,
      menuItemId: int.tryParse(item.id) ?? 0,
      quantity: quantity,
      addonOptionIds: _flattenAddonOptionIds(selectedAddons),
      name: item.name,
      imageUrl: item.imageUrl,
      price: item.price,
      addonOptions: selectedAddons,
    );
  }

  /// The cart API takes a flat `addon_option_ids` array with no per-option
  /// quantity field — an option picked N times (e.g. "2× extra cheese") is
  /// represented by repeating its id N times.
  List<int> _flattenAddonOptionIds(List<SelectedAddon> addons) => addons
      .expand((a) => List.filled(a.quantity, int.tryParse(a.optionId) ?? 0))
      .toList();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = _vm.state;
    final cartVm = context.watch<CartViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: switch (state.status) {
          RestaurantLoadStatus.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          RestaurantLoadStatus.error => Center(
              child: Text('Error: ${state.errorMessage}'),
            ),
          RestaurantLoadStatus.loaded => _buildBody(
              context,
              state.restaurant!,
              state.menu,
              cartVm,
              w,
              isMenuLoading: state.menuStatus == MenuLoadStatus.loading,
              hasMenuError: state.menuStatus == MenuLoadStatus.error,
            ),
        },
        // ── Cart FAB ──
        floatingActionButton: cartVm.isEmpty
            ? null
            : _CartFab(
                key: _cartFabKey,
                totalItems: cartVm.totalItems,
                total: cartVm.total,
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
    CartViewModel cartVm,
    double w, {
    required bool isMenuLoading,
    bool hasMenuError = false,
  }) {
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
                  child: restaurant.imageUrl.isEmpty
                      ? Container(color: AppColors.shimmerBase)
                      : Image.network(
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
                if (!restaurant.isOpen) ...[
                  SizedBox(height: w * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(w * 0.03),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: w * 0.02),
                        Expanded(
                          child: Text(
                            'This vendor is currently closed and not accepting orders.',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.033,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
          ? (isMenuLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : hasMenuError
                  ? _MenuErrorView(onRetry: _vm.refreshMenu)
                  : const _NoMenuItemsView())
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
                    final cartItems = cartVm.cart?.items ?? const [];
                    final matching =
                        cartItems.where((ci) => ci.menuItemId == item.id);
                    final qty =
                        matching.fold(0, (sum, ci) => sum + ci.quantity);
                    return MenuItemCard(
                      item: item,
                      cartQuantity: qty,
                      onAdd: () => _onAddItem(restaurant, item),
                      onRemove: () {
                        HapticFeedback.lightImpact();
                        final cartItemId = matching.isEmpty
                            ? null
                            : matching.first.id;
                        if (cartItemId != null) {
                          cartVm.updateItemQuantity(cartItemId, qty - 1);
                        }
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

class _NoMenuItemsView extends StatelessWidget {
  const _NoMenuItemsView();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: w * 0.14,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'No menu items found',
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              'This restaurant hasn\'t added any menu items yet. '
              'Please check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.035,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _MenuErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: w * 0.14,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'Couldn\'t load menu',
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              'Something went wrong while fetching the menu. '
              'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.035,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: w * 0.04),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  final int totalItems;
  final double total;
  final VoidCallback onTap;

  const _CartFab({
    super.key,
    required this.totalItems,
    required this.total,
    required this.onTap,
  });

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
                      '${widget.totalItems}',
                      key: ValueKey(widget.totalItems),
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
                  'GHS ${widget.total.toStringAsFixed(2)}',
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
