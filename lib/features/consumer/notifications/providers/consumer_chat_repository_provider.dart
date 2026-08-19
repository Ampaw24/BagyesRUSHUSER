import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/i_consumer_chat_repository.dart';
import '../repositories/consumer_chat_repository_impl.dart';

/// DI for the mocked chat/conversation data source. Real notifications now
/// go through `NotificationViewmodel` (`lib/src/notification/`), not Riverpod.
final consumerChatRepositoryProvider = Provider<IConsumerChatRepository>(
  (_) => ConsumerChatRepositoryImpl(),
);
