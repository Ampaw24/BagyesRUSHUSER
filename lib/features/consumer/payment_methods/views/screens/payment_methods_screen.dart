import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../constant/app_theme.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/widgets/custom_dialogs.dart';
import '../../../../../src/payment/model/payment_method.dart';
import '../../../../../src/payment/viewmodel/payment_state.dart';
import '../../../../../src/payment/viewmodel/payment_viewmodel.dart';
import '../widgets/payment_method_card.dart';
import 'add_payment_method_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentViewModel>().state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          if (state is PaymentMethodsLoaded && state.methods.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddScreen(context),
              tooltip: 'Add payment method',
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, PaymentState state) {
    if (state is PaymentInitial || state is PaymentLoading) {
      return const _SkeletonLoader();
    }

    if (state is PaymentError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<PaymentViewModel>().loadPaymentMethods(),
      );
    }

    final methods = state is PaymentMethodsLoaded ? state.methods : <PaymentMethod>[];

    if (methods.isEmpty) {
      return _EmptyState(onAdd: () => _showAddScreen(context));
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => context.read<PaymentViewModel>().loadPaymentMethods(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: methods.length,
        itemBuilder: (_, index) {
          final method = methods[index];
          return _DismissibleCard(
            method: method,
            isProcessing: _processingId == method.id,
            onConfirmDelete: () => _confirmDelete(context, method.displayTitle),
            onDelete: () => _delete(method),
            onSetDefault: () => _setDefault(method),
          );
        },
      ),
    );
  }
}

// ── Dismissible wrapper ───────────────────────────────────────────────────────

class _DismissibleCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isProcessing;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _DismissibleCard({
    required this.method,
    required this.isProcessing,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(method.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: PaymentMethodCard(
        method: method,
        isProcessing: isProcessing,
        onSetDefault: method.isDefault ? null : onSetDefault,
        onDelete: onDelete,
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
    final primary = Theme.of(context).colorScheme.primary;
    final w = MediaQuery.sizeOf(context).width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Payment Methods Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Add a mobile money account to pay for orders faster.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, _) {
        final shimmerColor = Color.lerp(
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          _shimmerAnim.value,
        )!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: 3,
          itemBuilder: (_, _) => _SkeletonCard(color: shimmerColor),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color color;
  const _SkeletonCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
