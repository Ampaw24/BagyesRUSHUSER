import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../models/review.dart';
import '../viewmodels/reviews_viewmodel.dart';

/// Bottom sheet for composing a vendor's public reply to a review — built
/// the same way as [DeleteActionSheet] (drag handle, rounded top, `Mukta`
/// text), with a public-reply notice and a live 1000-char counter since the
/// backend enforces `reply: min:2,max:1000`.
///
/// Only used for a review's *first* reply — the API doc explicitly flags
/// that a second `POST .../reply` is undocumented (overwrite/append/error
/// unknown), so this app doesn't offer an "edit reply" entry point.
class ReplyComposerSheet extends StatefulWidget {
  const ReplyComposerSheet({super.key, required this.review});

  final Review review;

  static Future<void> show(BuildContext context, Review review) {
    final w = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (_) => ReplyComposerSheet(review: review),
    );
  }

  @override
  State<ReplyComposerSheet> createState() => _ReplyComposerSheetState();
}

class _ReplyComposerSheetState extends State<ReplyComposerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(ReviewsViewModel vm) async {
    final success = await vm.submitReply(
      review: widget.review,
      reply: _controller.text,
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final vm = context.watch<ReviewsViewModel>();
    final isSubmitting = vm.state.replyingReviewId == widget.review.id;
    final canSubmit = vm.canSubmitReply(_controller.text) && !isSubmitting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: w * 0.12,
                  height: 4,
                  margin: EdgeInsets.only(bottom: w * 0.045),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Reply to review',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Mukta',
                ),
              ),
              SizedBox(height: w * 0.03),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: w * 0.022,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: w * 0.04,
                      color: AppColors.info,
                    ),
                    SizedBox(width: w * 0.02),
                    Expanded(
                      child: Text(
                        'Your reply will be public — customers will see it on your storefront.',
                        style: TextStyle(
                          fontSize: w * 0.029,
                          color: AppColors.info,
                          fontFamily: 'Mukta',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.035),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 1000,
                enabled: !isSubmitting,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: w * 0.036, fontFamily: 'Mukta'),
                decoration: const InputDecoration(
                  hintText: 'Write a reply…',
                ),
              ),
              if (vm.state.replyError != null) ...[
                SizedBox(height: w * 0.008),
                Text(
                  vm.state.replyError!,
                  style: TextStyle(
                    fontSize: w * 0.03,
                    color: AppColors.error,
                    fontFamily: 'Mukta',
                  ),
                ),
                SizedBox(height: w * 0.012),
              ],
              SizedBox(height: w * 0.015),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? () => _submit(vm) : null,
                  child: isSubmitting
                      ? SizedBox(
                          width: w * 0.045,
                          height: w * 0.045,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Reply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
