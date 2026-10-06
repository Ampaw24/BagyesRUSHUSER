import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../models/customer_withdrawal_model.dart';
import '../../viewmodels/customer_withdrawals_state.dart';
import '../../viewmodels/customer_withdrawals_viewmodel.dart';
import 'customer_withdrawal_tile.dart';

/// The customer's withdrawal requests, newest first as the server returns
/// them: loading, error with retry, empty, and the paginated list with
/// pull-to-refresh. Cancelling is delegated to [onCancel] (the screen asks
/// for confirmation and reports the outcome).
class WithdrawalsList extends StatefulWidget {
  const WithdrawalsList({super.key, required this.onCancel});

  final ValueChanged<CustomerWithdrawalModel> onCancel;

  @override
  State<WithdrawalsList> createState() => _WithdrawalsListState();
}

class _WithdrawalsListState extends State<WithdrawalsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CustomerWithdrawalsViewModel>();
      // Fresh data each time the tab is opened; the list already shown stays
      // on screen while it reloads.
      vm.fetch(silent: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<CustomerWithdrawalsViewModel>().fetch(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final vm = context.watch<CustomerWithdrawalsViewModel>();
    final state = vm.state;

    if (state.status == WithdrawalsStatus.initial ||
        state.status == WithdrawalsStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.status == WithdrawalsStatus.error) {
      return _Message(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: state.errorMessage ?? 'Couldn\'t load your withdrawals.',
        action: ElevatedButton(onPressed: vm.fetch, child: const Text('Retry')),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.fetch(silent: true),
      child: state.withdrawals.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.45,
                  child: const _Message(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.textHint,
                    title: 'No withdrawals yet',
                    subtitle: 'Money you withdraw from your wallet will show up here.',
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.05),
              itemCount: state.withdrawals.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.withdrawals.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: w * 0.06),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                }
                final withdrawal = state.withdrawals[i];
                return CustomerWithdrawalTile(
                  withdrawal: withdrawal,
                  isCancelling: state.cancellingId == withdrawal.id,
                  // One cancellation at a time.
                  onCancel: state.cancellingId == null
                      ? () => widget.onCancel(withdrawal)
                      : null,
                );
              },
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: w * 0.16, color: iconColor),
            SizedBox(height: w * 0.04),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: w * 0.015),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
              ),
            ],
            if (action != null) ...[SizedBox(height: w * 0.05), action!],
          ],
        ),
      ),
    );
  }
}
