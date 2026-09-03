import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../constant/app_theme.dart';
import '../../../../../core/common/app/current_user_provider.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../src/auth/models/user.dart' show CustomerProfile;
import '../../../../../src/payment/model/payment_method.dart';
import '../../../../../src/payment/viewmodel/payment_state.dart';
import '../../../../../src/payment/viewmodel/payment_viewmodel.dart';
import '../../../../../src/payment/views/screens/add_payment_method_screen.dart';
import '../../../../../src/payment/views/widgets/manage_payment_method_sheet.dart';
import '../../../../../src/payment/views/widgets/payment_method_hero_card.dart';

/// Customer-facing payment methods management screen.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentViewModel>(
      create: (_) {
        final vm = sl<PaymentViewModel>(param1: false);
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

  void _showAddScreen(BuildContext context) {
    final vm = context.read<PaymentViewModel>();
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => ChangeNotifierProvider<PaymentViewModel>.value(
          value: vm,
          child: const AddPaymentMethodScreen(),
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

  Future<void> _showManageSheet(BuildContext context, PaymentMethod method) async {
    final action = await showManagePaymentMethodSheet(context, method);
    if (!context.mounted || action == null) return;
    if (action == 'default') {
      await _setDefault(method);
    } else if (action == 'delete') {
      final confirmed = await confirmDeletePaymentMethod(context, method.displayTitle);
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
            'Add a mobile money account to pay for orders faster.',
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
    final customerProfile = user?.profile as CustomerProfile?;
    final fullName = '${customerProfile?.firstName ?? ''} ${customerProfile?.lastName ?? ''}'.trim();
    final holderName = shortHolderName(fullName.isNotEmpty ? fullName : 'Account holder');
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
        AddPaymentMethodTile(onTap: () => _showAddScreen(context)),
        SizedBox(height: w * 0.06),
        Text(
          'Your default method is used for all order payments. You can '
          'change it any time.',
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
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
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
              'Add a mobile money account to pay for orders faster.',
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
