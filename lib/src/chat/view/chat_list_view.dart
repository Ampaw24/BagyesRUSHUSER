import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/router/app_router.dart' show appRouteObserver;
import 'package:bagyesrushappusernew/src/chat/viewmodel/chat_list_viewmodel.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/conversation_tile.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';

/// The chat inbox — `GET conversations`, filtered to threads whose order is
/// still in progress. Unlike a general messaging app this is not a
/// permanent archive: once an order is delivered/cancelled its thread drops
/// out of this list (see `ChatListViewModel`), matching how Uber
/// Eats/Bolt Food scope chat to active orders rather than a standing inbox.
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> with RouteAware {
  late final ChatListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<ChatListViewModel>();
    _vm.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// A thread just opened (and possibly replied to) should show its updated
  /// unread/last-message state the instant the user comes back, not after a
  /// manual pull-to-refresh.
  @override
  void didPopNext() => _vm.refresh();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = _vm.state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Order chats'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          ChatListLoading() =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ChatListError(:final message) =>
            _ErrorState(w: w, message: message, onRetry: _vm.refresh),
          ChatListLoaded(:final conversations) => conversations.isEmpty
              ? _EmptyState(w: w)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _vm.refresh,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ConversationTile(
                        conversation: conversation,
                        onTap: () {
                          // The chat API never returns a phone number —
                          // borrow it from the already-cached order (if the
                          // order list has fetched it) so the sheet's Call
                          // button can still work from the inbox, not just
                          // from order tracking.
                          final orderId = conversation.order?.id;
                          final peerPhone = orderId != null
                              ? context.read<OrdersViewModel>().orderById(orderId)?.driverPhone
                              : null;
                          AppNavigator.showChatThread(
                            context,
                            conversationId: conversation.id,
                            peerName: conversation.counterpart?.name,
                            peerPhone: peerPhone,
                          );
                        },
                      );
                    },
                  ),
                ),
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChat,
              size: w * 0.16,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'No active order chats',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'Chats with your vendor or rider show up here while an order is in progress, and clear once it\'s delivered.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.w, required this.message, required this.onRetry});

  final double w;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: w * 0.14,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load your messages",
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
