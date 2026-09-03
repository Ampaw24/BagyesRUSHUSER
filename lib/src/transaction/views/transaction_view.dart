import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../viewmodels/transaction_state.dart';
import '../viewmodels/transaction_viewmodel.dart';
import 'widgets/transaction_tile.dart';

class TransactionView extends StatefulWidget {
  const TransactionView({super.key});

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  final _scrollController = ScrollController();
  TransactionViewmodel? _vm;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<TransactionViewmodel>();
      _vm!.fetchTransactions();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _vm?.fetchTransactions(loadMore: true);
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

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Transactions')),
      body: Consumer<TransactionViewmodel>(
        builder: (context, vm, _) {
          final state = vm.state;

          if (state is TransactionLoading || state is TransactionInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is TransactionError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => vm.fetchTransactions(),
            );
          }

          final loaded = state as TransactionsLoaded;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => vm.fetchTransactions(),
            child: loaded.transactions.isEmpty
                ? _EmptyState(scrollController: _scrollController)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      w * 0.05,
                      w * 0.04,
                      w * 0.05,
                      w * 0.05,
                    ),
                    itemCount:
                        loaded.transactions.length + (loaded.isLoadingMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= loaded.transactions.length) {
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
                      return TransactionTile(transaction: loaded.transactions[i]);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: w * 0.18,
                  color: AppColors.textHint,
                ),
                SizedBox(height: w * 0.04),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: w * 0.044,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.015),
                Text(
                  'Your transaction history will appear here',
                  style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: w * 0.18, color: AppColors.error),
            SizedBox(height: w * 0.04),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.036, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
