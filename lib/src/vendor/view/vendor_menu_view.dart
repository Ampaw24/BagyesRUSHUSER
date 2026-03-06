import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../model/menu_item.dart';
import '../viewmodel/menu_viewmodel.dart';
import 'widgets/menu_item_card.dart';
import 'widgets/add_edit_menu_sheet.dart';

// ── Main view ─────────────────────────────────────────────────────────────────

class VendorMenuView extends StatefulWidget {
  const VendorMenuView({super.key});

  @override
  State<VendorMenuView> createState() => _VendorMenuViewState();
}

class _VendorMenuViewState extends State<VendorMenuView> {
  bool _initialized = false;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MenuViewModel>().loadMenu();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MenuViewModel vm,
    MenuItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        return AlertDialog(
          title: Text(
            'Delete Item',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Remove "${item.name}" from your menu? This cannot be undone.',
            style: TextStyle(
              fontSize: w * 0.035,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      vm.deleteItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final horizontalPad = w * 0.05;

    return Consumer<MenuViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        final items = state.filteredItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                w * 0.03,
                horizontalPad,
                0,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.totalCount} items',
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Grid/List toggle
                  GestureDetector(
                    onTap: vm.toggleView,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(w * 0.025),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(w * 0.025),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        state.isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        size: w * 0.05,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  // Sort dropdown
                  _SortButton(vm: vm, w: w),
                  SizedBox(width: w * 0.025),
                  // Add item button
                  GestureDetector(
                    onTap: () => AddEditMenuSheet.show(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.04,
                        vertical: w * 0.025,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(w * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: w * 0.02,
                            offset: Offset(0, w * 0.008),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: w * 0.045,
                            color: Colors.white,
                          ),
                          SizedBox(width: w * 0.015),
                          Text(
                            'Add Item',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: w * 0.04),

            // ── Stats bar ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: _StatsBar(
                total: state.totalCount,
                available: state.availableCount,
                outOfStock: state.outOfStockCount,
                w: w,
              ),
            ),
            SizedBox(height: w * 0.035),

            // ── Search bar ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: TextField(
                controller: _searchController,
                onChanged: vm.search,
                style: TextStyle(fontSize: w * 0.035),
                decoration: InputDecoration(
                  hintText: 'Search menu items…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: w * 0.055,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            vm.search('');
                          },
                          child: Icon(
                            Icons.clear_rounded,
                            size: w * 0.045,
                            color: AppColors.textHint,
                          ),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: w * 0.03,
                  ),
                ),
              ),
            ),
            SizedBox(height: w * 0.03),

            // ── Category tabs ────────────────────────────────────────
            SizedBox(
              height: w * 0.09,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                itemCount: menuCategories.length,
                separatorBuilder: (_, _) =>
                    SizedBox(width: w * 0.02),
                itemBuilder: (_, i) {
                  final cat = menuCategories[i];
                  final isSelected = state.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => vm.setCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.04,
                        vertical: w * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(w * 0.025),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: w * 0.03),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: _buildContent(
                context: context,
                vm: vm,
                state: state,
                items: items,
                w: w,
                h: h,
                horizontalPad: horizontalPad,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required MenuViewModel vm,
    required MenuState state,
    required List<MenuItem> items,
    required double w,
    required double h,
    required double horizontalPad,
  }) {
    if (state.status == MenuStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == MenuStatus.error) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: w * 0.14,
                color: AppColors.error,
              ),
              SizedBox(height: w * 0.04),
              Text(
                state.errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.038,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.05),
              ElevatedButton.icon(
                onPressed: vm.loadMenu,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _EmptyState(
        isFiltered: state.searchQuery.isNotEmpty ||
            state.selectedCategory != 'All',
        onAdd: () => AddEditMenuSheet.show(context),
        w: w,
      );
    }

    // ── Featured section (only on All + no search) ─────────────
    final featured = state.featuredItems;
    final showFeatured = featured.isNotEmpty &&
        state.selectedCategory == 'All' &&
        state.searchQuery.isEmpty;

    if (state.isGridView) {
      return CustomScrollView(
        slivers: [
          if (showFeatured) ...[
            SliverToBoxAdapter(
              child: _FeaturedSection(
                items: featured,
                vm: vm,
                onEdit: (item) =>
                    AddEditMenuSheet.show(context, item: item),
                onDelete: (item) =>
                    _confirmDelete(context, vm, item),
                w: w,
                horizontalPad: horizontalPad,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  0,
                  horizontalPad,
                  w * 0.02,
                ),
                child: _SectionDividerLabel(
                  label: 'All Items',
                  w: w,
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              0,
              horizontalPad,
              w * 0.28,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final item = items[index];
                  return MenuItemGridCard(
                    item: item,
                    onEdit: () =>
                        AddEditMenuSheet.show(context, item: item),
                    onDelete: () =>
                        _confirmDelete(context, vm, item),
                    onAvailabilityChanged: (v) =>
                        vm.toggleAvailability(item.id, v),
                    onFeaturedChanged: (v) =>
                        vm.toggleFeatured(item.id, v),
                  );
                },
                childCount: items.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: w * 0.03,
                mainAxisSpacing: w * 0.03,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      );
    }

    // ── List view ──────────────────────────────────────────────
    return CustomScrollView(
      slivers: [
        if (showFeatured) ...[
          SliverToBoxAdapter(
            child: _FeaturedSection(
              items: featured,
              vm: vm,
              onEdit: (item) =>
                  AddEditMenuSheet.show(context, item: item),
              onDelete: (item) =>
                  _confirmDelete(context, vm, item),
              w: w,
              horizontalPad: horizontalPad,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                0,
                horizontalPad,
                w * 0.02,
              ),
              child: _SectionDividerLabel(
                label: 'All Items',
                w: w,
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            0,
            horizontalPad,
            w * 0.28,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: w * 0.03),
                  child: MenuItemCard(
                    item: item,
                    onEdit: () =>
                        AddEditMenuSheet.show(context, item: item),
                    onDelete: () =>
                        _confirmDelete(context, vm, item),
                    onAvailabilityChanged: (v) =>
                        vm.toggleAvailability(item.id, v),
                    onFeaturedChanged: (v) =>
                        vm.toggleFeatured(item.id, v),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int available;
  final int outOfStock;
  final double w;

  const _StatsBar({
    required this.total,
    required this.available,
    required this.outOfStock,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'Total',
          value: total,
          color: AppColors.secondary,
          w: w,
        ),
        SizedBox(width: w * 0.025),
        _StatChip(
          label: 'Available',
          value: available,
          color: AppColors.success,
          w: w,
        ),
        SizedBox(width: w * 0.025),
        _StatChip(
          label: 'Unavailable',
          value: outOfStock,
          color: AppColors.error,
          w: w,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final double w;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: w * 0.025,
          horizontal: w * 0.03,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.026,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured section ──────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  final List<MenuItem> items;
  final MenuViewModel vm;
  final void Function(MenuItem) onEdit;
  final void Function(MenuItem) onDelete;
  final double w;
  final double horizontalPad;

  const _FeaturedSection({
    required this.items,
    required this.vm,
    required this.onEdit,
    required this.onDelete,
    required this.w,
    required this.horizontalPad,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            0,
            horizontalPad,
            w * 0.025,
          ),
          child: Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: w * 0.045,
                color: AppColors.accent,
              ),
              SizedBox(width: w * 0.015),
              Text(
                'Featured',
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: w * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.02,
                  vertical: w * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: w * 0.028,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: w * 0.52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: w * 0.03),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return SizedBox(
                width: w * 0.52,
                child: MenuItemGridCard(
                  item: item,
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                  onAvailabilityChanged: (v) =>
                      vm.toggleAvailability(item.id, v),
                  onFeaturedChanged: (v) =>
                      vm.toggleFeatured(item.id, v),
                ),
              );
            },
          ),
        ),
        SizedBox(height: w * 0.035),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAdd;
  final double w;

  const _EmptyState({
    required this.isFiltered,
    required this.onAdd,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.restaurant_menu_rounded,
              size: w * 0.18,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              isFiltered ? 'No items match' : 'Your menu is empty',
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              isFiltered
                  ? 'Try a different search or category.'
                  : 'Start building your menu by adding\nyour first food item.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.034,
                color: AppColors.textHint,
                height: 1.5,
              ),
            ),
            if (!isFiltered) ...[
              SizedBox(height: w * 0.06),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Item'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sort button ───────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final MenuViewModel vm;
  final double w;

  const _SortButton({required this.vm, required this.w});

  static const _options = [
    ('Default', 'default'),
    ('Name A–Z', 'name_asc'),
    ('Price: Low–High', 'price_asc'),
    ('Price: High–Low', 'price_desc'),
    ('Featured First', 'featured'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context, w),
      child: Container(
        padding: EdgeInsets.all(w * 0.025),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          Icons.sort_rounded,
          size: w * 0.05,
          color: vm.state.sortBy != 'default'
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, double w) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      elevation: 4,
      items: _options.map((opt) {
        final isSelected = vm.state.sortBy == opt.$2;
        return PopupMenuItem<String>(
          value: opt.$2,
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: w * 0.04,
                  color: AppColors.primary,
                )
              else
                SizedBox(width: w * 0.04),
              SizedBox(width: w * 0.02),
              Text(
                opt.$1,
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) vm.setSortBy(value);
    });
  }
}

// ── Section divider label ─────────────────────────────────────────────────────

class _SectionDividerLabel extends StatelessWidget {
  final String label;
  final double w;

  const _SectionDividerLabel({
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Container(height: w * 0.003, color: AppColors.divider),
        ),
      ],
    );
  }
}
