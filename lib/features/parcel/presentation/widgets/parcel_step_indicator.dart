import 'package:flutter/material.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'package:gopady/src/parcel/model/parcel_direction.dart';
import 'package:gopady/src/parcel/viewmodel/send_parcel_viewmodel.dart';

/// Slim segmented progress bar with a "Step x of y · Label" caption.
class ParcelStepIndicator extends StatelessWidget {
  final ParcelStep currentStep;
  final ParcelDirection direction;

  static const _sendLabels = [
    'Package type',
    'Package details',
    'Pickup',
    'Delivery',
    'Rider',
    'Confirm',
  ];

  static const _receiveLabels = [
    'Package type',
    'Package details',
    'Sender',
    'Drop-off',
    'Rider',
    'Confirm',
  ];

  const ParcelStepIndicator({
    super.key,
    required this.currentStep,
    this.direction = ParcelDirection.send,
  });

  List<String> get _labels =>
      direction.isReceive ? _receiveLabels : _sendLabels;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final total = ParcelStep.values.length;
    final current = currentStep.index;
    final next = current + 1 < total ? _labels[current + 1] : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.01, w * 0.05, w * 0.035),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) SizedBox(width: w * 0.012),
                Expanded(
                  child: _Segment(filled: i <= current, w: w),
                ),
              ],
            ],
          ),
          SizedBox(height: w * 0.025),
          Row(
            children: [
              Text(
                'Step ${current + 1} of $total',
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '  ·  ${_labels[current]}',
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (next != null)
                Flexible(
                  child: Text(
                    'Next: $next',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.029,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool filled;
  final double w;

  const _Segment({required this.filled, required this.w});

  @override
  Widget build(BuildContext context) {
    final height = w * 0.011;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.surfaceVariant),
          AnimatedFractionallySizedBox(
            duration: AppMotion.standard,
            curve: AppMotion.outExpo,
            widthFactor: filled ? 1 : 0,
            child: Container(height: height, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
