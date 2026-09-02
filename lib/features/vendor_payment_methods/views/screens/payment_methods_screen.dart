import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../constant/app_theme.dart';
import '../../../../core/common/app/current_user_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import '../../../../src/payment/model/payment_method.dart';
import '../../../../src/payment/viewmodel/payment_state.dart';
import '../../../../src/payment/viewmodel/payment_viewmodel.dart';
import '../../../../src/vendor/model/vendor_profile.dart';
import '../widgets/payment_method_card.dart';
import 'add_mobile_money_screen.dart';

/// Main vendor payment methods management screen.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentViewModel>(
      create: (_) {
        final vm = sl<PaymentViewModel>(param1: true);
        vm.loadPaymentMethods();
        return vm;
      },
      child: const _PaymentMethodsView(),
    );
  }
}

class _PaymentMethodsView extends StatefulWidget {
  const _PaymentMethodsView();

  @override
  State<_PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<_PaymentMethodsView> {
  String? _processingId;

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final completer = Completer<bool>();
    CustomDialog.showConfirmation(
      context: context,
      title: 'Remove Payment Method',
      subtitle: 'Remove "$title"? This action cannot be undone.',
      confirmText: 'Remove',
      onConfirm: () => completer.complete(true),
      onCancel: () => completer.complete(false),
    );
    return completer.future;
  }

  void _showAddScreen(BuildContext context) {
    final vm = context.read<PaymentViewModel>();
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => ChangeNotifierProvider<PaymentViewModel>.value(
          value: vm,
          child: const AddMobileMoneyScreen(),
        ),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    )
        .then((_) => vm.loadPaymentMethods());
  }

  Future<void> _delete(PaymentMethod method) async {
    final vm = context.read<PaymentViewModel>();
    setState(() => _processingId = method.id);
    final ok = await vm.deletePaymentMethod(method.id);
    if (!mounted) return;
    setState(() => _processingId = null);
    if (ok) vm.loadPaymentMethods();
  }

  Future<void> _setDefault(PaymentMethod method) async {
    final vm = context.read<PaymentViewModel>();
    setState(() => _processingId = method.id);
    final ok = await vm.setDefault(method.id);
    if (!mounted) return;
    setState(() => _processingId = null);
    if (ok) vm.loadPaymentMethods();
  }

  /// Bottom sheet with the real actions available for a method — "Set as
  /// Default" (hidden for the method that already is) and "Remove".
  Future<void> _showManageSheet(BuildContext context, PaymentMethod method) async {
    final w = MediaQuery.sizeOf(context).width;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.02),
                child: Text(
                  method.displayTitle,
                  style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w700),
                ),
              ),
              if (!method.isDefault)
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: const Text('Set as Default'),
                  onTap: () => Navigator.of(ctx).pop('default'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Remove', style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    if (action == 'default') {
      await _setDefault(method);
    } else if (action == 'delete') {
      final confirmed = await _confirmDelete(context, method.displayTitle);
      if (confirmed) await _delete(method);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentViewModel>().state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, PaymentState state) {
    final w = MediaQuery.sizeOf(context).width;
    final methods = state is PaymentMethodsLoaded ? state.methods : <PaymentMethod>[];
    final showAddAction = state is PaymentMethodsLoaded && methods.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<PaymentViewModel>().loadPaymentMethods(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.08),
        children: [
          _HeaderRow(showAdd: showAddAction, onAdd: () => _showAddScreen(context)),
          SizedBox(height: w * 0.05),
          Text(
            'Payment methods',
            style: TextStyle(
              fontSize: w * 0.075,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Payouts and refunds go to your default method.',
            style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
          ),
          SizedBox(height: w * 0.06),
          _buildContent(context, state, methods),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PaymentState state,
    List<PaymentMethod> methods,
  ) {
    final w = MediaQuery.sizeOf(context).width;

    if (state is PaymentInitial || state is PaymentLoading) {
      return const _SkeletonLoader();
    }

    if (state is PaymentError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<PaymentViewModel>().loadPaymentMethods(),
      );
    }

    if (methods.isEmpty) {
      return _EmptyState(onAdd: () => _showAddScreen(context));
    }

    final defaultMethod =
        methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
    final others = methods.where((m) => m.id != defaultMethod.id).toList();

    final user = context.watch<CurrentUserProvider>().user;
    final vendorProfile = user?.profile as VendorProfile?;
    final holderName = shortHolderName(
      vendorProfile?.contactPersonName.trim().isNotEmpty == true
          ? vendorProfile!.contactPersonName
          : 'Account holder',
    );
    final holderVerified = user?.phoneVerified ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaymentMethodHeroCard(
          method: defaultMethod,
          holderName: holderName,
          holderVerified: holderVerified,
          isProcessing: _processingId == defaultMethod.id,
          onManage: () => _showManageSheet(context, defaultMethod),
        ),
        if (others.isNotEmpty) ...[
          SizedBox(height: w * 0.07),
          _SectionLabel(text: 'OTHER METHODS', w: w),
          SizedBox(height: w * 0.03),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.04),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < others.length; i++)
                  PaymentMethodRow(
                    method: others[i],
                    isProcessing: _processingId == others[i].id,
                    onTap: () => _showManageSheet(context, others[i]),
                    showDivider: i < others.length - 1,
                  ),
              ],
            ),
          ),
        ],
        SizedBox(height: w * 0.04),
        _AddMethodTile(onTap: () => _showAddScreen(context), w: w),
        SizedBox(height: w * 0.06),
        Text(
          'Payouts arrive in 1–2 business days. You can change your default '
          'any time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Header (back + add) ─────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showAdd, required this.onAdd});

  final bool showAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => context.pop()),
        if (showAdd)
          _CircleIconButton(icon: Icons.add_rounded, onTap: onAdd)
        else
          SizedBox(width: w * 0.11),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.06),
      child: Container(
        width: w * 0.11,
        height: w * 0.11,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: w * 0.045, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.w});
  final String text;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: w * 0.03,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ── Add method tile ──────────────────────────────────────────────────────────

class _AddMethodTile extends StatelessWidget {
  const _AddMethodTile({required this.onTap, required this.w});
  final VoidCallback onTap;
  final double w;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: DottedBorderContainer(
        w: w,
        child: Padding(
          padding: EdgeInsets.all(w * 0.035),
          child: Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(w * 0.025),
                ),
                child: Icon(Icons.add_rounded, color: AppColors.primary, size: w * 0.055),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a payment method',
                      style: TextStyle(
                        fontSize: w * 0.037,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Mobile money account',
                      style: TextStyle(fontSize: w * 0.031, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed-outline container drawn with [CustomPaint] — no extra package
/// needed for a simple rectangular dash border.
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key, required this.child, required this.w});
  final Widget child;
  final double w;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: w * 0.04, color: AppColors.border),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 6.0;
    const gapWidth = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: h * 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: w * 0.24,
              height: w * 0.24,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: w * 0.1,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: w * 0.06),
            Text(
              'No Payment Methods Yet',
              style: TextStyle(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.025),
            Text(
              'Add a payment method to start receiving payouts from your orders.',
              style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.08),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, _) {
        final shimmerColor = Color.lerp(
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          _shimmerAnim.value,
        )!;
        return Column(
          children: [
            Container(
              height: w * 0.5,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(w * 0.055),
              ),
            ),
            SizedBox(height: w * 0.05),
            Container(
              height: w * 0.3,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(w * 0.04),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: h * 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: w * 0.12, color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary, fontSize: w * 0.035),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.05),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
