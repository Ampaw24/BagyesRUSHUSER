import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';

enum ReviewSubmitStatus { idle, submitting, success, error }

/// One party's in-progress rating on the review sheet.
class SubjectDraft extends Equatable {
  const SubjectDraft({
    this.rating = 0,
    this.selectedTags = const [],
    this.comment = '',
  });

  /// 0 until the customer taps a star.
  final int rating;
  final List<String> selectedTags;
  final String comment;

  bool get hasRating => rating > 0;

  /// Free-text room left after the selected chips are merged in.
  int get maxCommentLength => remainingCommentLength(selectedTags);

  String? get composedComment => composeReviewComment(selectedTags, comment);

  SubjectDraft copyWith({
    int? rating,
    List<String>? selectedTags,
    String? comment,
  }) => SubjectDraft(
    rating: rating ?? this.rating,
    selectedTags: selectedTags ?? this.selectedTags,
    comment: comment ?? this.comment,
  );

  @override
  List<Object?> get props => [rating, selectedTags, comment];
}

class ReviewComposerState extends Equatable {
  const ReviewComposerState({
    required this.target,
    this.drafts = const {},
    this.status = ReviewSubmitStatus.idle,
    this.errorMessage,
    this.submittedReview,
  });

  final ReviewTarget target;
  final Map<ReviewSubject, SubjectDraft> drafts;
  final ReviewSubmitStatus status;
  final String? errorMessage;
  final OrderReview? submittedReview;

  SubjectDraft draftFor(ReviewSubject subject) =>
      drafts[subject] ?? const SubjectDraft();

  List<String> tagsFor(ReviewSubject subject) =>
      reviewTagsFor(subject, draftFor(subject).rating);

  bool get hasAnyRating => drafts.values.any((d) => d.hasRating);
  bool get isSubmitting => status == ReviewSubmitStatus.submitting;

  /// Either party alone is enough — the backend takes each as optional.
  bool get canSubmit => hasAnyRating && !isSubmitting;

  /// Only the parties the customer actually rated.
  Map<ReviewSubject, SubjectRating> get submission => {
    for (final party in target.parties)
      if (draftFor(party.subject) case final draft when draft.hasRating)
        party.subject: SubjectRating(
          rating: draft.rating,
          comment: draft.composedComment,
        ),
  };

  ReviewComposerState copyWith({
    Map<ReviewSubject, SubjectDraft>? drafts,
    ReviewSubmitStatus? status,
    String? errorMessage,
    bool clearError = false,
    OrderReview? submittedReview,
  }) => ReviewComposerState(
    target: target,
    drafts: drafts ?? this.drafts,
    status: status ?? this.status,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    submittedReview: submittedReview ?? this.submittedReview,
  );

  @override
  List<Object?> get props => [
    target,
    drafts,
    status,
    errorMessage,
    submittedReview,
  ];
}
