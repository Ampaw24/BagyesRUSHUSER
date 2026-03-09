import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../providers/payment_providers.dart';
import '../../viewmodels/payment_methods_viewmodel.dart';
import '../../models/payment_method_model.dart';
import '../widgets/payment_method_card.dart';
import 'add_payment_method_screen.dart';

/// Main vendor payment methods management screen.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState
    extends ConsumerState<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentMethodsProvider.notifier).load();
    });
  }

  // ── Delete confirmation ───────────────────────────────────────────────────

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Payment Method'),
        content: Text(
          'Remove "$title"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showAddScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => const AddPaymentMethodScreen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentMethodsProvider);
    final notifier = ref.read(paymentMethodsProvider.notifier);

    // Show error snackbar reactively
    ref.listen<PaymentMethodsState>(paymentMethodsProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          if (state.paymentMethods.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showAddScreen,
              tooltip: 'Add payment method',
            ),
        ],
      ),
      floatingActionButton: state.paymentMethods.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddScreen,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Method'),
            ),
      body: SafeArea(
        child: _buildBody(state, notifier, context),
      ),
    );
  }

  Widget _buildBody(
    PaymentMethodsState state,
    PaymentMethodsNotifier notifier,
    BuildContext context,
  ) {
    switch (state.status) {
      case PaymentMethodsStatus.initial:
      case PaymentMethodsStatus.loading:
        return const _SkeletonLoader();

      case PaymentMethodsStatus.error:
        return _ErrorView(
          message: state.errorMessage ?? 'Failed to load payment methods',
          onRetry: notifier.load,
        );

      case PaymentMethodsStatus.loaded:
        if (state.isEmpty) {
          return _EmptyState(onAdd: _showAddScreen);
        }
        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: notifier.load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: state.paymentMethods.length,
            itemBuilder: (_, index) {
              final method = state.paymentMethods[index];
              return _DismissibleCard(
                method: method,
                isProcessing: state.processingId == method.id,
                onConfirmDelete: () =>
                    _confirmDelete(context, method.displayTitle),
                onDelete: () => notifier.delete(method.id),
                onSetDefault: () => notifier.setDefault(method.id),
                onToggleEnabled: () => notifier.toggleEnabled(method.id),
              );
            },
          ),
        );
    }
  }
}

// ── Dismissible wrapper ───────────────────────────────────────────────────────

class _DismissibleCard extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isProcessing;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onToggleEnabled;

  const _DismissibleCard({
    required this.method,
    required this.isProcessing,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onSetDefault,
    required this.onToggleEnabled,
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
        onToggleEnabled: onToggleEnabled,
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
              'Add a payment method to start receiving payouts from your orders.',
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
