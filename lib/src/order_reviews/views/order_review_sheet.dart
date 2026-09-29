import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/review_composer_state.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/review_composer_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/review_success_view.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/review_tag_chips.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/star_rating_input.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/models/review.dart';

/// Rate-and-review bottom sheet. Stars first; chips and a comment box slide
/// in once a rating is picked, then a success state auto-closes the sheet
/// and returns the saved [Review] (null if dismissed).
class OrderReviewSheet extends StatefulWidget {
  const OrderReviewSheet._({required this.target, required this.initialRating});

  final ReviewTarget target;
  final int initialRating;

  static const _successHold = Duration(milliseconds: 1600);
  static const _commentCounterThreshold = 800;

  static Future<Review?> show(
    BuildContext context, {
    required ReviewTarget target,
    int initialRating = 0,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      builder: (_) =>
          OrderReviewSheet._(target: target, initialRating: initialRating),
    );
  }

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  late final ReviewComposerViewModel _vm = sl<ReviewComposerViewModel>(
    param1: widget.target,
  );
  final _commentController = TextEditingController();
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialRating > 0) _vm.setRating(widget.initialRating);
    _vm.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _vm
      ..removeListener(_onStateChanged)
      ..dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final state = _vm.state;
    // The VM trims the comment when a new chip eats into the length budget.
    if (_commentController.text != state.comment) {
      _commentController.value = TextEditingValue(
        text: state.comment,
        selection: TextSelection.collapsed(offset: state.comment.length),
      );
    }
    if (state.status == ReviewSubmitStatus.success && _closeTimer == null) {
      FocusManager.instance.primaryFocus?.unfocus();
      _closeTimer = Timer(OrderReviewSheet._successHold, () {
        if (mounted) Navigator.of(context).pop(state.submittedReview);
      });
    }
  }

  /// Closes the sheet first — the report flow is a full page and shouldn't
  /// open underneath a modal.
  void _openReport() {
    final target = widget.target;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      AppRoutes.reportFlow,
      extra: ReportFlowArgs(
        role: ReportRole.customer,
        targetType: target.isRider
            ? ReportTargetType.rider
            : ReportTargetType.vendor,
        orderId: target.orderId,
        targetName: target.name,
        targetImageUrl: target.imageUrl,
        targetPhone: target.phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.03, w * 0.06, w * 0.05),
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            final state = _vm.state;
            return AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == ReviewSubmitStatus.success
                    ? ReviewSuccessView(
                        key: const ValueKey('success'),
                        target: state.target,
                      )
                    : _ReviewForm(
                        key: const ValueKey('form'),
                        state: state,
                        commentController: _commentController,
                        onRating: _vm.setRating,
                        onToggleTag: _vm.toggleTag,
                        onComment: _vm.setComment,
                        onSubmit: _vm.submit,
                        onReport: _openReport,
                        onClose: () => Navigator.of(context).pop(),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    super.key,
    required this.state,
    required this.commentController,
    required this.onRating,
    required this.onToggleTag,
    required this.onComment,
    required this.onSubmit,
    required this.onReport,
    required this.onClose,
  });

  final ReviewComposerState state;
  final TextEditingController commentController;
  final ValueChanged<int> onRating;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<String> onComment;
  final VoidCallback onSubmit;
  final VoidCallback onReport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final target = state.target;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(target: target, onClose: onClose),
        SizedBox(height: w * 0.05),
        StarRatingInput(
          rating: state.rating,
          onChanged: onRating,
          enabled: !state.isSubmitting,
        ),
        if (state.hasRating) ...[
          SizedBox(height: w * 0.06),
          _SectionLabel(
            isPositiveRating(state.rating)
                ? 'What did you love?'
                : 'What could be better?',
          ),
          SizedBox(height: w * 0.03),
          ReviewTagChips(
            tags: state.availableTags,
            selected: state.selectedTags,
            onToggle: onToggleTag,
          ),
          SizedBox(height: w * 0.05),
          _CommentField(
            controller: commentController,
            maxLength: state.maxCommentLength,
            enabled: !state.isSubmitting,
            onChanged: onComment,
          ),
          if (state.rating <= 2) _ReportLink(target: target, onTap: onReport),
        ],
        if (state.errorMessage != null) ...[
          SizedBox(height: w * 0.03),
          _ErrorBanner(message: state.errorMessage!),
        ],
        SizedBox(height: w * 0.05),
        _SubmitButton(
          isSubmitting: state.isSubmitting,
          onPressed: state.canSubmit ? onSubmit : null,
        ),
        if (!target.isRider) ...[
          SizedBox(height: w * 0.025),
          Text(
            'Reviews are shown publicly on ${target.name}\'s page.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: w * 0.029, color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.target, required this.onClose});

  final ReviewTarget target;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Container(
          width: w * 0.12,
          height: w * 0.012,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(w * 0.01),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Not now'),
          ),
        ),
        _ReviewAvatar(target: target),
        SizedBox(height: w * 0.035),
        Text(
          target.isRider ? 'How was your delivery?' : 'How was your order?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.012),
        Text(
          target.hasNamedRider
              ? 'Rate ${target.name}, your rider'
              : 'Rate ${target.name}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.037, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Vendor logo, or the rider's initial, inside a soft brand-tinted ring.
class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({required this.target});

  final ReviewTarget target;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.2;
    final hasRiderName = target.hasNamedRider;

    final fallback = Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: hasRiderName
          ? Text(
              target.name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(
              target.isRider
                  ? Icons.delivery_dining_rounded
                  : Icons.storefront_rounded,
              color: Colors.white,
              size: size * 0.45,
            ),
    );

    return Container(
      padding: EdgeInsets.all(w * 0.012),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: target.imageUrl == null
              ? fallback
              : Image.network(
                  target.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      label,
      style: TextStyle(
        fontSize: w * 0.04,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({
    required this.controller,
    required this.maxLength,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int maxLength;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.035);

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLength: maxLength,
      minLines: 3,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: w * 0.037, color: AppColors.textPrimary),
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) =>
              maxLength != null &&
                  currentLength >= OrderReviewSheet._commentCounterThreshold
              ? Text(
                  '$currentLength / $maxLength',
                  style: TextStyle(
                    fontSize: w * 0.029,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
      decoration: InputDecoration(
        hintText: 'Tell us more (optional)',
        hintStyle: TextStyle(fontSize: w * 0.036, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: EdgeInsets.all(w * 0.04),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ReportLink extends StatelessWidget {
  const _ReportLink({required this.target, required this.onTap});

  final ReviewTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
        ),
        icon: Icon(Icons.support_agent_rounded, size: w * 0.045),
        label: Text(
          'Need help? Report a problem',
          style: TextStyle(fontSize: w * 0.034, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: w * 0.033, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, w * 0.13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.035),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              width: w * 0.05,
              height: w * 0.05,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Submit review'),
    );
  }
}
