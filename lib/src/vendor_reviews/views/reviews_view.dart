import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../viewmodels/reviews_state.dart';
import '../viewmodels/reviews_viewmodel.dart';
import '../widgets/review_card.dart';
import '../widgets/review_filter_chips.dart';
import '../widgets/review_summary_header.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<ReviewsViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = context.watch<ReviewsViewModel>().state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Reviews')),
      body: Column(
        children: [
          ReviewSummaryHeader(summary: state.summary),
          ReviewFilterChips(
            ratingFilter: state.ratingFilter,
            unansweredOnly: state.unansweredOnly,
            onSelect: (rating, unanswered) {
              final vm = context.read<ReviewsViewModel>();
              vm.setRatingFilter(rating);
              vm.setUnansweredOnly(unanswered);
            },
          ),
          SizedBox(height: w * 0.02),
          Expanded(child: _buildBody(context, state, w)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewsState state, double w) {
    if (state.status == ReviewsStatus.loading) {
      return _SkeletonList(w: w);
    }

    if (state.status == ReviewsStatus.error && state.reviews.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? 'Something went wrong.',
        onRetry: () => context.read<ReviewsViewModel>().refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ReviewsViewModel>().refresh(),
      color: AppColors.primary,
      child: state.reviews.isEmpty
          ? _EmptyState(unansweredOnly: state.unansweredOnly)
          : ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, w * 0.06),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
              itemBuilder: (context, index) {
                if (index >= state.reviews.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: w * 0.04),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final review = state.reviews[index];
                return ReviewCard(
                  review: review,
                  isReplying: state.replyingReviewId == review.id,
                );
              },
            ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.unansweredOnly});

  final bool unansweredOnly;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Wrapped in a scrollable list (not a bare Center) so the enclosing
    // RefreshIndicator's pull gesture still works with zero items —
    // matches consumer_orders_view.dart's empty-state pattern.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: w * 0.1, vertical: w * 0.2),
      children: [
        Icon(
          unansweredOnly
              ? Icons.check_circle_outline_rounded
              : Icons.star_border_rounded,
          size: w * 0.16,
          color: AppColors.textHint,
        ),
        SizedBox(height: w * 0.04),
        Text(
          unansweredOnly ? "You're all caught up" : 'No reviews yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Mukta',
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          unansweredOnly
              ? 'Nothing waiting on a reply right now.'
              : 'Reviews from your customers will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.033,
            color: AppColors.textSecondary,
            fontFamily: 'Mukta',
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: w * 0.14,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.03),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Mukta',
              ),
            ),
            SizedBox(height: w * 0.012),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.032,
                color: AppColors.textSecondary,
                fontFamily: 'Mukta',
              ),
            ),
            SizedBox(height: w * 0.04),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton loading placeholders ───────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.w});

  final double w;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(w * 0.04),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
      itemBuilder: (_, _) => _SkeletonCard(w: w),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.w});

  final double w;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          _controller.value,
        )!;
        Widget box(double width, double height) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(w * 0.015),
              ),
            );

        return Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(child: box(w * 0.11, w * 0.11)),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(w * 0.3, w * 0.03),
                        SizedBox(height: w * 0.02),
                        box(w * 0.2, w * 0.025),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.03),
              box(double.infinity, w * 0.025),
              SizedBox(height: w * 0.015),
              box(w * 0.6, w * 0.025),
            ],
          ),
        );
      },
    );
  }
}
