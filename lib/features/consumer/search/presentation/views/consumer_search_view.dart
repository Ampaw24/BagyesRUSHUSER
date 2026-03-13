import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/providers/restaurant_providers.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/widgets/restaurant_card.dart';

class ConsumerSearchView extends ConsumerStatefulWidget {
  const ConsumerSearchView({super.key});

  @override
  ConsumerState<ConsumerSearchView> createState() => _ConsumerSearchViewState();
}

class _ConsumerSearchViewState extends ConsumerState<ConsumerSearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search restaurants, cuisines...',
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint),
            suffixIcon: query.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textHint),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.025,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.03),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptySearch()
          : results.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (restaurants) => restaurants.isEmpty
                  ? _NoResults(query: query)
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          w * 0.05, w * 0.04, w * 0.05, w * 0.05),
                      itemCount: restaurants.length,
                      itemBuilder: (ctx, i) => RestaurantListCard(
                        restaurant: restaurants[i],
                        onTap: () => context.push(
                          AppRoutes.restaurantDetailPath(restaurants[i].id),
                        ),
                      ),
                    ),
            ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final suggestions = [
      'Jollof Rice', 'Burgers', 'Pizza',
      'Chinese', 'Healthy', 'Chicken',
    ];

    return Padding(
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.03),
          Wrap(
            spacing: w * 0.025,
            runSpacing: w * 0.025,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  // No ref here; just a static widget pattern
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.025,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(w * 0.06),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: w * 0.04,
                          color: AppColors.textSecondary),
                      SizedBox(width: w * 0.015),
                      Text(
                        s,
                        style: TextStyle(
                          fontSize: w * 0.032,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: w * 0.18, color: AppColors.textHint),
          SizedBox(height: w * 0.04),
          Text(
            'No results for "$query"',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
