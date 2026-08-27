import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/viewmodels/orders_viewmodel.dart'
    as consumer_orders;
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/states/orders_state.dart'
    as consumer_orders;
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report_reason.dart';
import 'package:bagyesrushappusernew/features/report/presentation/providers/report_provider.dart';
import 'package:bagyesrushappusernew/features/report/presentation/report_flow_args.dart';
import 'package:bagyesrushappusernew/features/report/presentation/states/report_form_state.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/report_target_tile.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/steps/report_details_step.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/steps/report_reason_step.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/steps/report_target_picker_step.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/steps/report_target_type_step.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart'
    as vendor_model;
import 'package:bagyesrushappusernew/src/vendor/viewmodel/orders_viewmodel.dart'
    as vendor_orders;

class ReportFlowView extends ConsumerStatefulWidget {
  final ReportFlowArgs args;

  const ReportFlowView({super.key, required this.args});

  @override
  ConsumerState<ReportFlowView> createState() => _ReportFlowViewState();
}

class _ReportFlowViewState extends ConsumerState<ReportFlowView> {
  bool _isPickingPhotos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(reportFormProvider.notifier)
          .start(
            role: widget.args.role,
            targetType: widget.args.targetType,
            orderId: widget.args.orderId,
            targetId: widget.args.targetId,
            targetName: widget.args.targetName,
            targetImageUrl: widget.args.targetImageUrl,
            targetPhone: widget.args.targetPhone,
          );
      if (widget.args.role == ReportRole.vendor) {
        final vm = context.read<vendor_orders.OrdersViewModel>();
        if (vm.state.orders.isEmpty &&
            vm.state.status != vendor_orders.OrdersStatus.loading) {
          vm.loadOrders();
        }
      }
    });
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<ReportableTarget> _consumerRiderTargets(List<ConsumerOrder> orders) {
    final byRider = <String, ConsumerOrder>{};
    for (final o in orders) {
      final name = o.driverName;
      if (name == null || name.isEmpty) continue;
      final key = '$name|${o.driverPhone ?? ''}';
      final existing = byRider[key];
      if (existing == null || o.placedAt.isAfter(existing.placedAt)) {
        byRider[key] = o;
      }
    }
    final list = byRider.values.toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return list
        .map(
          (o) => ReportableTarget(
            name: o.driverName!,
            phone: o.driverPhone,
            orderId: o.id,
            subtitle: 'Last delivery: ${_formatDate(o.placedAt)}',
          ),
        )
        .toList();
  }

  List<ReportableTarget> _vendorCustomerTargets(
    List<vendor_model.VendorOrder> orders,
  ) {
    final byCustomer = <String, vendor_model.VendorOrder>{};
    for (final o in orders) {
      if (o.customerName.isEmpty) continue;
      final key = '${o.customerName}|${o.customerPhone ?? ''}';
      final existing = byCustomer[key];
      if (existing == null ||
          (o.createdAt != null &&
              (existing.createdAt == null ||
                  o.createdAt!.isAfter(existing.createdAt!)))) {
        byCustomer[key] = o;
      }
    }
    return byCustomer.values
        .map(
          (o) => ReportableTarget(
            name: o.customerName,
            phone: o.customerPhone,
            orderId: o.id,
            subtitle: o.timeAgo,
          ),
        )
        .toList();
  }

  List<ReportableTarget> _vendorRiderTargets(
    List<vendor_model.VendorOrder> orders,
  ) {
    final byRider = <String, vendor_model.VendorOrder>{};
    for (final o in orders) {
      final name = o.driverName;
      if (name == null || name.isEmpty) continue;
      final key = '$name|${o.driverPhone ?? ''}';
      final existing = byRider[key];
      if (existing == null ||
          (o.createdAt != null &&
              (existing.createdAt == null ||
                  o.createdAt!.isAfter(existing.createdAt!)))) {
        byRider[key] = o;
      }
    }
    return byRider.values
        .map(
          (o) => ReportableTarget(
            name: o.driverName!,
            phone: o.driverPhone,
            orderId: o.id,
            subtitle: o.timeAgo,
          ),
        )
        .toList();
  }

  String _targetPickerHeading(ReportTargetType? type) => switch (type) {
    ReportTargetType.vendor => 'Which restaurant?',
    ReportTargetType.rider => 'Which delivery rider?',
    ReportTargetType.customer => 'Which customer?',
    _ => 'Who are you reporting?',
  };

  void _handleSubmitOutcome(ReportFormState state) {
    if (state.submitStatus == ReportSubmitStatus.success &&
        state.submittedReport != null) {
      CustomDialog.showSuccess(
        context: context,
        title: 'Report submitted',
        subtitle:
            'Reference #${state.submittedReport!.id}. Our team will review it shortly.',
        onConfirm: () {
          if (!mounted) return;
          context.pushReplacement(AppRoutes.myReports, extra: widget.args.role);
        },
      );
    } else if (state.submitStatus == ReportSubmitStatus.error) {
      CustomDialog.showError(
        context: context,
        title: 'Submission failed',
        subtitle:
            state.errorMessage ?? 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(reportFormProvider);
    final notifier = ref.read(reportFormProvider.notifier);

    ref.listen<ReportFormState>(reportFormProvider, (previous, next) {
      if (previous?.submitStatus != next.submitStatus) {
        _handleSubmitOutcome(next);
      }
    });

    List<ReportableTarget> targets = const [];
    bool riderAvailable = false;
    bool targetsLoading = false;

    if (widget.args.role == ReportRole.customer) {
      final ordersState = ref.watch(consumer_orders.ordersProvider);
      targetsLoading = ordersState is consumer_orders.OrdersLoading;
      final orders = ordersState is consumer_orders.OrdersLoaded
          ? ordersState.orders
          : const <ConsumerOrder>[];
      riderAvailable = orders.any(
        (o) => o.driverName != null && o.driverName!.isNotEmpty,
      );
      if (state.targetType == ReportTargetType.rider) {
        targets = _consumerRiderTargets(orders);
      }
    } else {
      final vendorOrdersState = context
          .watch<vendor_orders.OrdersViewModel>()
          .state;
      targetsLoading =
          vendorOrdersState.status == vendor_orders.OrdersStatus.loading;
      final orders = vendorOrdersState.orders;
      riderAvailable = orders.any(
        (o) => o.driverName != null && o.driverName!.isNotEmpty,
      );
      if (state.targetType == ReportTargetType.customer) {
        targets = _vendorCustomerTargets(orders);
      } else if (state.targetType == ReportTargetType.rider) {
        targets = _vendorRiderTargets(orders);
      }
    }

    final List<ReportReason> reasons = state.targetType != null
        ? ReportReasons.forTargetType(state.targetType!)
        : const [];

    return PopScope(
      canPop: state.isFirstStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) notifier.goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              _FlowHeader(
                title: 'Report a Problem',
                progress: state.progress,
                onBack: () {
                  if (state.isFirstStep) {
                    Navigator.of(context).maybePop();
                  } else {
                    notifier.goBack();
                  }
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.currentStep),
                    child: switch (state.currentStep) {
                      ReportWizardStep.targetType => ReportTargetTypeStep(
                        role: state.role,
                        riderAvailable: riderAvailable,
                        onSelect: notifier.selectTargetType,
                      ),
                      ReportWizardStep.target =>
                        state.targetType == ReportTargetType.vendor
                            ? _VendorTargetPicker(onSelect: notifier.selectTarget)
                            : ReportTargetPickerStep(
                                heading: _targetPickerHeading(state.targetType),
                                targets: targets,
                                isLoading: targetsLoading,
                                onSelect: (t) => notifier.selectTarget(
                                  orderId: t.orderId,
                                  targetId: t.targetId,
                                  targetName: t.name,
                                  targetImageUrl: t.imageUrl,
                                  targetPhone: t.phone,
                                ),
                              ),
                      ReportWizardStep.reason => ReportReasonStep(
                        reasons: reasons,
                        selectedCode: state.reasonCode,
                        onSelect: (r) => notifier.selectReason(
                          code: r.code,
                          label: r.label,
                          isUrgent: r.isUrgent,
                        ),
                      ),
                      ReportWizardStep.details => ReportDetailsStep(
                        targetName: state.targetName ?? '',
                        targetSubtitle: state.orderId != null
                            ? 'Order #${state.orderId}'
                            : 'General report',
                        targetImageUrl: state.targetImageUrl,
                        description: state.description,
                        onDescriptionChanged: notifier.updateDescription,
                        photos: state.photos,
                        isPickingPhotos: _isPickingPhotos,
                        onAddPhotos: () =>
                            _pickPhotos(notifier, state.photos.length),
                        onRemovePhoto: notifier.removePhoto,
                      ),
                    },
                  ),
                ),
              ),
              if (state.currentStep == ReportWizardStep.reason ||
                  state.currentStep == ReportWizardStep.details)
                _BottomActionBar(
                  w: w,
                  isDetails: state.currentStep == ReportWizardStep.details,
                  enabled: state.currentStep == ReportWizardStep.reason
                      ? state.hasReason
                      : state.canSubmit,
                  isSubmitting:
                      state.submitStatus == ReportSubmitStatus.submitting,
                  onTap: () {
                    if (state.currentStep == ReportWizardStep.reason) {
                      notifier.goNext();
                    } else {
                      notifier.submit();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos(
    ReportFormViewModel notifier,
    int currentPhotoCount,
  ) async {
    final remaining = 5 - currentPhotoCount;
    if (remaining <= 0 || _isPickingPhotos) return;

    setState(() => _isPickingPhotos = true);
    try {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;
      await notifier.addPhotos(picked.map((x) => File(x.path)).toList());
    } finally {
      if (mounted) setState(() => _isPickingPhotos = false);
    }
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _FlowHeader extends StatelessWidget {
  final String title;
  final double progress;
  final VoidCallback onBack;

  const _FlowHeader({
    required this.title,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: EdgeInsets.all(w * 0.022),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft02,
                    color: AppColors.textPrimary,
                    size: w * 0.055,
                  ),
                ),
              ),
              SizedBox(width: w * 0.035),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.048,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.035),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.01),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: w * 0.012,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar ─────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final double w;
  final bool isDetails;
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _BottomActionBar({
    required this.w,
    required this.isDetails,
    required this.enabled,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.03,
        w * 0.05,
        w * 0.03 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: w * 0.13,
        child: ElevatedButton(
          onPressed: enabled && !isSubmitting ? onTap : null,
          child: isSubmitting
              ? SizedBox(
                  width: w * 0.05,
                  height: w * 0.05,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  isDetails ? 'Submit Report' : 'Continue',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Vendor target picker (real "all vendors" endpoint) ────────────────────

typedef _SelectTarget = void Function({
  String? orderId,
  String? targetId,
  required String targetName,
  String? targetImageUrl,
  String? targetPhone,
});

class _VendorTargetPicker extends ConsumerWidget {
  final _SelectTarget onSelect;

  const _VendorTargetPicker({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final vendors = ref.watch(allVendorsForReportProvider);

    return vendors.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load vendors",
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.02),
              ElevatedButton(
                onPressed: () => ref.invalidate(allVendorsForReportProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (restaurants) => ReportTargetPickerStep(
        heading: 'Which restaurant?',
        targets: restaurants
            .map((r) => ReportableTarget(
                  targetId: r.id,
                  name: r.name,
                  imageUrl: r.imageUrl,
                  subtitle: r.cuisineType.isNotEmpty ? r.cuisineType : r.address,
                ))
            .toList(),
        onSelect: (t) => onSelect(
          targetId: t.targetId,
          targetName: t.name,
          targetImageUrl: t.imageUrl,
        ),
      ),
    );
  }
}
