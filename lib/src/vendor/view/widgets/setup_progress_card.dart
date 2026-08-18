import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../model/vendor_profile.dart';

class SetupStep {
  final String label;
  final String activeTitle;
  final bool completed;
  final String? etaLabel;
  final VoidCallback? onStart;

  const SetupStep({
    required this.label,
    required this.activeTitle,
    required this.completed,
    this.etaLabel,
    this.onStart,
  });
}

const _hoursFields = {
  'opening_time',
  'closing_time',
  'operating_days',
  'estimated_prep_time_minutes',
};

const _deliveryFields = {'delivery_radius_km', 'min_order', 'delivery_fee'};

const _documentsField = 'documents';
const _payoutField = 'payout_details';

/// Builds the Finish Setup checklist directly off the backend's
/// `missing_profile_fields` — the same list it uses to compute
/// `is_profile_complete` — instead of re-deriving completeness from
/// several separate signals (`documents.*.uploaded`, `payout.is_configured`,
/// etc.) that can drift out of sync with what the backend actually
/// considers outstanding.
List<SetupStep> buildVendorSetupSteps(
  VendorProfile profile, {
  required VoidCallback onBusinessProfile,
  required VoidCallback onDocuments,
  required VoidCallback onPayouts,
}) {
  final missing = profile.missingProfileFields.toSet();
  bool anyMissing(Set<String> fields) => fields.any(missing.contains);

  final knownFields = {
    ..._hoursFields,
    ..._deliveryFields,
    _documentsField,
    _payoutField,
  };
  final otherMissing = missing.difference(knownFields);

  return [
    SetupStep(
      label: 'Store hours & prep time',
      activeTitle: 'Set your store hours to start receiving orders',
      completed: !anyMissing(_hoursFields),
      onStart: onBusinessProfile,
    ),
    SetupStep(
      label: 'Delivery settings',
      activeTitle: 'Set your delivery radius and fees to start receiving orders',
      completed: !anyMissing(_deliveryFields),
      onStart: onBusinessProfile,
    ),
    SetupStep(
      label: 'Verify identity documents',
      activeTitle: 'Verify your identity to start receiving orders',
      completed: !missing.contains(_documentsField),
      onStart: onDocuments,
    ),
    SetupStep(
      label: 'Set up payouts',
      activeTitle: 'Set up payouts to start receiving orders',
      completed: !missing.contains(_payoutField),
      etaLabel: '2 min',
      onStart: onPayouts,
    ),
    if (otherMissing.isNotEmpty)
      SetupStep(
        label: _humanize(otherMissing.first),
        activeTitle: 'Complete your business profile to start receiving orders',
        completed: false,
        onStart: onBusinessProfile,
      ),
  ];
}

String _humanize(String field) {
  return field
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Dark onboarding checklist shown while a vendor has outstanding setup
/// steps before they can start receiving orders.
class SetupProgressCard extends StatelessWidget {
  final List<SetupStep> steps;

  const SetupProgressCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((s) => !s.completed);
    if (currentIndex == -1) return const SizedBox.shrink();

    final completedCount = steps.where((s) => s.completed).length;
    final current = steps[currentIndex];
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FINISH SETUP',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: w * 0.027,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontFamily: 'Mukta',
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount/${steps.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: w * 0.029,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mukta',
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.018),
          Text(
            current.activeTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.042,
              fontWeight: FontWeight.w800,
              height: 1.15,
              fontFamily: 'Mukta',
            ),
          ),
          SizedBox(height: w * 0.03),
          Row(
            children: List.generate(steps.length, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i == steps.length - 1 ? 0 : w * 0.012,
                  ),
                  height: w * 0.008,
                  decoration: BoxDecoration(
                    color: i < completedCount
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(w * 0.008),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: w * 0.015),
          ...List.generate(steps.length, (i) {
            return _StepRow(
              step: steps[i],
              isDone: i < completedCount,
              isCurrent: i == currentIndex,
              isLast: i == steps.length - 1,
              w: w,
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final SetupStep step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final double w;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: w * 0.021),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
      ),
      child: Row(
        children: [
          _StatusCircle(isDone: isDone, isCurrent: isCurrent, w: w),
          SizedBox(width: w * 0.028),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                color: isDone
                    ? Colors.white.withValues(alpha: 0.4)
                    : (isCurrent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4)),
                fontSize: w * 0.031,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                decoration: isDone ? TextDecoration.lineThrough : null,
                fontFamily: 'Mukta',
              ),
            ),
          ),
          if (isCurrent && step.onStart != null)
            GestureDetector(
              onTap: step.onStart,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.035,
                  vertical: w * 0.014,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(w * 0.05),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.027,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mukta',
                  ),
                ),
              ),
            )
          else if (!isDone && !isCurrent && step.etaLabel != null)
            Text(
              step.etaLabel!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: w * 0.026,
                fontWeight: FontWeight.w600,
                fontFamily: 'Mukta',
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final double w;

  const _StatusCircle({
    required this.isDone,
    required this.isCurrent,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final size = w * 0.05;
    if (isDone) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: Colors.white, size: size * 0.6),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppColors.primary : Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    );
  }
}
