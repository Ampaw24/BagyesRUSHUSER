import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/model/conversation.dart';
import 'package:bagyesrushappusernew/src/chat/model/messages_page.dart';

/// Thrown by [ChatRepository.getConversationForOrder] for a 422 — per the
/// API contract this means no conversation exists yet for this order
/// (documented as: no rider assigned). Distinguished from a generic
/// [Exception] so the caller can render "not available yet" instead of a
/// retry/error UI. [message] is the backend's own response text when it
/// supplied one — not assumed to always be the rider-assignment reason,
/// since a 422 here could in principle be returned for a different cause.
class ConversationNotAvailableException implements Exception {
  const ConversationNotAvailableException([
    this.message = 'Chat opens once your rider is assigned.',
  ]);
  final String message;

  @override
  String toString() => message;
}

/// Backed by the live `v1/chat` API (see `chat-apis.md`). Shared by
/// customer, vendor and rider apps alike — every endpoint is role-agnostic,
/// the server resolves the caller from the bearer token.
class ChatRepository {
  ChatRepository({required Dio client}) : _client = client;

  final Dio _client;

  Future<List<Conversation>> getConversations() async {
    appLogger.d('ChatRepository.getConversations → initiated');
    try {
      final response = await _client.get(ApiEndpoints.conversations);
      if (response.statusCode == 200) {
        final conversations = _dataList(
          response.data,
        ).map((e) => Conversation.fromJson(e as DataMap)).toList();
        appLogger.i(
          'ChatRepository.getConversations → loaded ${conversations.length}',
        );
        return conversations;
      }
      throw Exception(_errorMessage(response.data) ?? 'Failed to load conversations (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ChatRepository.getConversations → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  Future<Conversation> getConversation(String conversationId) async {
    appLogger.d('ChatRepository.getConversation → id=$conversationId');
    try {
      final response = await _client.get(
        ApiEndpoints.conversationById(conversationId),
      );
      if (response.statusCode == 200) {
        return Conversation.fromJson(_dataMap(response.data));
      }
      throw Exception(_errorMessage(response.data) ?? 'Failed to load conversation (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ChatRepository.getConversation → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Resolves the thread attached to an order — the entry point from an
  /// order-tracking screen's "Chat" button. [orderId] is the **order** id.
  Future<Conversation> getConversationForOrder(String orderId) async {
    appLogger.d('ChatRepository.getConversationForOrder → orderId=$orderId');
    try {
      final response = await _client.get(
        ApiEndpoints.orderConversation(orderId),
      );
      if (response.statusCode == 200) {
        return Conversation.fromJson(_dataMap(response.data));
      }
      throw Exception(_errorMessage(response.data) ?? 'Failed to load conversation (${response.statusCode}).');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final backendMessage = _errorMessage(e.response?.data);
        // .w(), not .i() — appLogger suppresses .i()/.d() outside debug
        // mode, and this is exactly the line worth checking when chat
        // unexpectedly shows as "not available" in a release build.
        appLogger.w(
          'ChatRepository.getConversationForOrder → 422, backend message: '
          '${backendMessage ?? '(none supplied)'}',
        );
        throw backendMessage != null
            ? ConversationNotAvailableException(backendMessage)
            : const ConversationNotAvailableException();
      }
      appLogger.e(
        'ChatRepository.getConversationForOrder → DioException',
        error: e,
      );
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Cursor-paginated — pass [cursor] back from a previous page's
  /// `MessagesPage.nextCursor` to page older messages. No `page`/`total`.
  Future<MessagesPage> getMessages(
    String conversationId, {
    String? cursor,
    int perPage = 30,
  }) async {
    appLogger.d(
      'ChatRepository.getMessages → conversationId=$conversationId, cursor=$cursor',
    );
    try {
      final response = await _client.get(
        ApiEndpoints.conversationMessages(conversationId),
        queryParameters: {
          'per_page': perPage,
          if (cursor != null) 'cursor': cursor,
        },
      );
      if (response.statusCode == 200) {
        return MessagesPage.fromJson(_dataMap(response.data));
      }
      throw Exception(_errorMessage(response.data) ?? 'Failed to load messages (${response.statusCode}).');
    } on DioException catch (e) {
      appLogger.e('ChatRepository.getMessages → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  /// [clientUuid] is the optimistic-send/dedupe key — generate a UUID v4
  /// client-side and omit the key entirely if not sending one (never send
  /// an empty string, it fails the backend's `uuid` rule).
  Future<ChatMessage> sendMessage(
    String conversationId, {
    required String body,
    String? clientUuid,
  }) async {
    appLogger.d('ChatRepository.sendMessage → conversationId=$conversationId');
    try {
      final response = await _client.post(
        ApiEndpoints.conversationMessages(conversationId),
        data: {'body': body, if (clientUuid != null) 'client_uuid': clientUuid},
      );
      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('ChatRepository.sendMessage → success');
        return ChatMessage.fromJson(_dataMap(response.data));
      }
      throw Exception(_errorMessage(response.data) ?? 'Failed to send message.');
    } on DioException catch (e) {
      appLogger.e('ChatRepository.sendMessage → DioException', error: e);
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Clears the caller's `unread_count` for this conversation. Best-effort —
  /// callers should debounce and never block the UI on this; failures are
  /// logged, not thrown.
  Future<void> markRead(String conversationId) async {
    try {
      await _client.post(ApiEndpoints.conversationRead(conversationId));
    } catch (e) {
      appLogger.w('ChatRepository.markRead → failed (non-fatal): $e');
    }
  }

  /// Signals typing. Fire-and-forget by design — the API has no stop-typing
  /// endpoint and failures must never surface to the composer.
  Future<void> sendTyping(String conversationId) async {
    try {
      await _client.post(ApiEndpoints.conversationTyping(conversationId));
    } catch (e) {
      appLogger.w('ChatRepository.sendTyping → failed (ignored): $e');
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────

  String _friendlyMessage(DioException e) {
    final message = _errorMessage(e.response?.data);
    if (message != null) return message;
    return e.message ?? 'Something went wrong. Please try again.';
  }

  /// Surfaces `errors.<field>[0]` verbatim when present (the backend ships
  /// user-facing copy, e.g. "Type a message first"), else falls back to the
  /// envelope's top-level `message`.
  String? _errorMessage(dynamic data) {
    if (data is! DataMap) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      return first is List && first.isNotEmpty
          ? first.first.toString()
          : first.toString();
    }
    return data['message']?.toString();
  }

  DataMap _dataMap(dynamic raw) {
    if (raw is DataMap) {
      final data = raw['data'];
      if (data is DataMap) return data;
    }
    return const {};
  }

  List<dynamic> _dataList(dynamic raw) {
    if (raw is DataMap) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }
}
