import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/models/review.dart';

enum ReviewSubmitStatus { idle, submitting, success, error }

class ReviewComposerState extends Equatable {
  const ReviewComposerState({
    required this.target,
    this.rating = 0,
    this.selectedTags = const [],
    this.comment = '',
    this.status = ReviewSubmitStatus.idle,
    this.errorMessage,
    this.submittedReview,
  });

  final ReviewTarget target;

  /// 0 until the customer taps a star.
  final int rating;
  final List<String> selectedTags;
  final String comment;
  final ReviewSubmitStatus status;
  final String? errorMessage;
  final Review? submittedReview;

  bool get hasRating => rating > 0;
  bool get isSubmitting => status == ReviewSubmitStatus.submitting;
  bool get canSubmit => hasRating && !isSubmitting;

  List<String> get availableTags => reviewTagsFor(target.subject, rating);

  /// Free-text room left after the selected chips are merged in.
  int get maxCommentLength => remainingCommentLength(selectedTags);

  String? get composedComment => composeReviewComment(selectedTags, comment);

  ReviewComposerState copyWith({
    int? rating,
    List<String>? selectedTags,
    String? comment,
    ReviewSubmitStatus? status,
    String? errorMessage,
    bool clearError = false,
    Review? submittedReview,
  }) => ReviewComposerState(
    target: target,
    rating: rating ?? this.rating,
    selectedTags: selectedTags ?? this.selectedTags,
    comment: comment ?? this.comment,
    status: status ?? this.status,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    submittedReview: submittedReview ?? this.submittedReview,
  );

  @override
  List<Object?> get props => [
    target,
    rating,
    selectedTags,
    comment,
    status,
    errorMessage,
    submittedReview,
  ];
}
