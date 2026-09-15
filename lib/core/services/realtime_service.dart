import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/services/realtime_config.dart';
import 'package:bagyesrushappusernew/core/services/realtime_events.dart';
import 'package:bagyesrushappusernew/core/services/realtime_repository.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_realtime_events.dart';

/// How a private-channel authorization attempt failed, surfaced via
/// [RealtimeService.channelErrors] so callers can tell a real
/// "not authorized for this data" case (403) apart from a stale session.
enum RealtimeChannelErrorType { forbidden, sessionExpired, unknown }

class RealtimeChannelError {
  const RealtimeChannelError({
    required this.channelName,
    required this.type,
    this.message,
  });

  final String channelName;
  final RealtimeChannelErrorType type;
  final String? message;
}

/// Thrown by [_DioChannelAuthorizationDelegate] when `/broadcasting/auth`
/// returns 403 — the caller has no stake in this channel's subject (e.g. a
/// customer trying to join another customer's order channel).
class RealtimeForbiddenException implements Exception {
  const RealtimeForbiddenException(this.channelName);
  final String channelName;
}

/// Thrown for any other channel-authorization failure — most commonly a
/// 401 that survived `DioInterceptor`'s own refresh-and-retry, meaning the
/// session is genuinely over.
class RealtimeAuthException implements Exception {
  const RealtimeAuthException(this.channelName, this.message);
  final String channelName;
  final String message;
}

/// Authorizes private channels through the app's existing authenticated
/// [Dio] instance rather than a fresh HTTP client. `DioInterceptor` doesn't
/// exclude `/broadcasting/auth` from its bearer-token attachment, so the
/// token is attached automatically, and a 401 here is already covered by
/// the interceptor's existing single-flight refresh-and-retry — this
/// delegate only needs to react when that refresh also fails.
class _DioChannelAuthorizationDelegate
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData> {
  _DioChannelAuthorizationDelegate({
    required Dio dio,
    required String authEndpoint,
    this.onAuthFailed,
  })  : _dio = dio,
        _authEndpoint = authEndpoint;

  final Dio _dio;
  final String _authEndpoint;

  @override
  final EndpointAuthFailedCallback? onAuthFailed;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    try {
      final response = await _dio.post(
        _authEndpoint,
        data: {'socket_id': socketId, 'channel_name': channelName},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final auth = (response.data as Map)['auth'] as String;
      return PrivateChannelAuthorizationData(authKey: auth);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw RealtimeForbiddenException(channelName);
      }
      throw RealtimeAuthException(
        channelName,
        e.message ?? 'Realtime channel authorization failed.',
      );
    }
  }
}

class _TrackedChannel {
  _TrackedChannel(this.channel);
  final PrivateChannel channel;
  final List<StreamSubscription<ChannelReadEvent>> subscriptions = [];
}

/// Owns the single realtime (Reverb/Pusher-protocol) connection for the
/// app session: fetches config, connects once, exposes subscribe/unsubscribe
/// per channel family, and exposes typed streams rather than leaking raw
/// Pusher event objects into the UI layer.
///
/// Registered as a `registerLazySingleton` — like every other cross-screen
/// singleton in this app, it lives for the process lifetime; `connect()`/
/// `disconnect()` are called explicitly at the right session-lifecycle
/// points (see `AuthViewmodel.login`/`logout`, `AppInitializer`).
class RealtimeService {
  RealtimeService({required RealtimeRepository repository, required Dio authDio})
      : _repository = repository,
        _authDio = authDio;

  final RealtimeRepository _repository;
  final Dio _authDio;

  PusherChannelsClient? _client;
  RealtimeConfig? _config;
  _DioChannelAuthorizationDelegate? _authDelegate;
  StreamSubscription<void>? _establishedSub;
  Completer<void>? _connecting;

  final _activeChannels = <String, _TrackedChannel>{};

  final _orderStatusController = StreamController<OrderStatusEvent>.broadcast();
  final _riderLocationController = StreamController<RiderLocationEvent>.broadcast();
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<ConversationTypingEvent>.broadcast();
  final _readController = StreamController<ConversationReadEvent>.broadcast();
  final _channelErrorController = StreamController<RealtimeChannelError>.broadcast();

  Stream<OrderStatusEvent> get orderStatusEvents => _orderStatusController.stream;
  Stream<RiderLocationEvent> get riderLocationEvents => _riderLocationController.stream;
  Stream<ChatMessage> get messageEvents => _messageController.stream;
  Stream<ConversationTypingEvent> get typingEvents => _typingController.stream;
  Stream<ConversationReadEvent> get readEvents => _readController.stream;
  Stream<RealtimeChannelError> get channelErrors => _channelErrorController.stream;

  /// Lets a screen/viewmodel filter [channelErrors] down to the one channel
  /// it owns — null before `connect()` has resolved (nothing to compare
  /// against yet, so no error for this order could have arrived either).
  String? orderChannelName(String orderId) => _config?.orderChannel(orderId);

  String? conversationChannelName(String conversationId) =>
      _config?.conversationChannel(conversationId);

  /// Fetches config and connects, once per session. Safe to call repeatedly
  /// — a no-op once connected, and concurrent callers await the same
  /// in-flight attempt (mirrors `DioInterceptor`'s single-flight refresh).
  Future<void> connect() async {
    if (_client != null) return;
    final inFlight = _connecting;
    if (inFlight != null) return inFlight.future;
    final completer = Completer<void>();
    _connecting = completer;
    try {
      await _doConnect();
      completer.complete();
    } catch (e, s) {
      completer.completeError(e, s);
      rethrow;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _doConnect() async {
    final config = await _repository.getConfig();
    _config = config;
    _authDelegate = _DioChannelAuthorizationDelegate(
      dio: _authDio,
      authEndpoint: config.authEndpoint,
      onAuthFailed: _handleAuthFailed,
    );

    final client = PusherChannelsClient.websocket(
      options: PusherChannelsOptions.fromHost(
        // The websocket scheme is derived from use_tls, not the REST
        // scheme the config response also carries (`https`) — those are
        // two different URLs (this app's API vs. the Reverb socket).
        scheme: config.useTls ? 'wss' : 'ws',
        host: config.host,
        port: config.port,
        key: config.key,
      ),
      connectionErrorHandler: (exception, trace, refresh) {
        appLogger.e('[RealtimeService] connection error', error: exception, stackTrace: trace);
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 3),
    );

    // Channel subscriptions don't survive a reconnect on their own — the
    // client itself auto-reconnects, but each channel must be explicitly
    // re-subscribed once the connection is back, or a dropped-then-restored
    // socket would silently stop delivering events for every open screen.
    _establishedSub = client.onConnectionEstablished.listen((_) {
      for (final tracked in _activeChannels.values) {
        tracked.channel.subscribeIfNotUnsubscribed();
      }
    });

    _client = client;
    await client.connect();
  }

  /// Unsubscribes every channel, disconnects, and drops the cached config —
  /// a subsequent `connect()` fetches fresh config and reconnects from
  /// scratch, so no socket survives into the next login on a stale token.
  Future<void> disconnect() async {
    for (final tracked in _activeChannels.values) {
      for (final sub in tracked.subscriptions) {
        sub.cancel();
      }
      tracked.channel.unsubscribe();
    }
    _activeChannels.clear();

    await _establishedSub?.cancel();
    _establishedSub = null;

    final client = _client;
    _client = null;
    _config = null;
    _authDelegate = null;

    if (client != null) {
      try {
        await client.disconnect();
        client.dispose();
      } catch (e, s) {
        appLogger.w('[RealtimeService] disconnect cleanup failed', error: e, stackTrace: s);
      }
    }
  }

  Future<void> subscribeToOrder(String orderId) async {
    try {
      await connect();
      final config = _config;
      final client = _client;
      if (config == null || client == null) return;
      final channelName = config.orderChannel(orderId);
      if (_resubscribeIfTracked(channelName)) return;

      final channel = client.privateChannel(channelName, authorizationDelegate: _authDelegate!);
      final tracked = _TrackedChannel(channel)
        ..subscriptions.add(
          channel.bind('order.status').listen((event) {
            final data = event.tryGetDataAsMap();
            if (data == null) return;
            _orderStatusController.add(OrderStatusEvent.fromJson(data));
          }),
        )
        ..subscriptions.add(
          channel.bind('rider.location').listen((event) {
            final data = event.tryGetDataAsMap();
            if (data == null) return;
            _riderLocationController.add(
              RiderLocationEvent.fromJson(data).copyWith(sourceOrderId: orderId),
            );
          }),
        );
      _activeChannels[channelName] = tracked;
      channel.subscribe();
    } catch (e, s) {
      appLogger.e('[RealtimeService] subscribeToOrder failed', error: e, stackTrace: s);
    }
  }

  Future<void> unsubscribeFromOrder(String orderId) async {
    final config = _config;
    if (config == null) return;
    _unsubscribeChannel(config.orderChannel(orderId));
  }

  Future<void> subscribeToConversation(String conversationId) async {
    try {
      await connect();
      final config = _config;
      final client = _client;
      if (config == null || client == null) return;
      final channelName = config.conversationChannel(conversationId);
      if (_resubscribeIfTracked(channelName)) return;

      final channel = client.privateChannel(channelName, authorizationDelegate: _authDelegate!);
      final tracked = _TrackedChannel(channel)
        ..subscriptions.add(
          channel.bind('message.sent').listen((event) {
            final message = event.tryGetDataAsMap()?['message'];
            if (message is! Map) return;
            _messageController.add(ChatMessage.fromJson(Map<String, dynamic>.from(message)));
          }),
        )
        ..subscriptions.add(
          channel.bind('conversation.read').listen((event) {
            final data = event.tryGetDataAsMap();
            if (data == null) return;
            _readController.add(ConversationReadEvent.fromJson(data));
          }),
        )
        ..subscriptions.add(
          channel.bind('conversation.typing').listen((event) {
            final data = event.tryGetDataAsMap();
            if (data == null) return;
            _typingController.add(ConversationTypingEvent.fromJson(data));
          }),
        );
      _activeChannels[channelName] = tracked;
      channel.subscribe();
    } catch (e, s) {
      appLogger.e('[RealtimeService] subscribeToConversation failed', error: e, stackTrace: s);
    }
  }

  Future<void> unsubscribeFromConversation(String conversationId) async {
    final config = _config;
    if (config == null) return;
    _unsubscribeChannel(config.conversationChannel(conversationId));
  }

  /// No UI consumes this today (no admin/dispatch screen exists in this
  /// app) — implemented for completeness per the API's channel set.
  Future<void> subscribeToAdminRiders() async {
    try {
      await connect();
      final client = _client;
      if (client == null) return;
      const channelName = RealtimeConfig.adminRidersChannel;
      if (_resubscribeIfTracked(channelName)) return;

      final channel = client.privateChannel(channelName, authorizationDelegate: _authDelegate!);
      final tracked = _TrackedChannel(channel)
        ..subscriptions.add(
          channel.bind('rider.location').listen((event) {
            final data = event.tryGetDataAsMap();
            if (data == null) return;
            _riderLocationController.add(RiderLocationEvent.fromJson(data));
          }),
        );
      _activeChannels[channelName] = tracked;
      channel.subscribe();
    } catch (e, s) {
      appLogger.e('[RealtimeService] subscribeToAdminRiders failed', error: e, stackTrace: s);
    }
  }

  Future<void> unsubscribeFromAdminRiders() async {
    _unsubscribeChannel(RealtimeConfig.adminRidersChannel);
  }

  /// Forward-compat only, per the API's own guidance: this channel's
  /// payload isn't documented, so every event is logged rather than parsed
  /// into a typed model. No UI consumes this today (no rider-facing app
  /// exists in this codebase).
  Future<void> subscribeToRider(String userId) async {
    try {
      await connect();
      final config = _config;
      final client = _client;
      if (config == null || client == null) return;
      final channelName = config.riderChannel(userId);
      if (_resubscribeIfTracked(channelName)) return;

      final channel = client.privateChannel(channelName, authorizationDelegate: _authDelegate!);
      final tracked = _TrackedChannel(channel)
        ..subscriptions.add(
          channel.bindToAll().listen((event) {
            appLogger.d('[RealtimeService] unhandled private-rider event: ${event.name} → ${event.data}');
          }),
        );
      _activeChannels[channelName] = tracked;
      channel.subscribe();
    } catch (e, s) {
      appLogger.e('[RealtimeService] subscribeToRider failed', error: e, stackTrace: s);
    }
  }

  Future<void> unsubscribeFromRider(String userId) async {
    final config = _config;
    if (config == null) return;
    _unsubscribeChannel(config.riderChannel(userId));
  }

  /// Returns true (and re-triggers subscribe) if [channelName] is already
  /// tracked, so callers don't re-bind listeners on a channel that's still
  /// active (e.g. a screen re-subscribing on app resume).
  bool _resubscribeIfTracked(String channelName) {
    final existing = _activeChannels[channelName];
    if (existing == null) return false;
    existing.channel.subscribeIfNotUnsubscribed();
    return true;
  }

  void _unsubscribeChannel(String channelName) {
    final tracked = _activeChannels.remove(channelName);
    if (tracked == null) return;
    for (final sub in tracked.subscriptions) {
      sub.cancel();
    }
    tracked.channel.unsubscribe();
  }

  void _handleAuthFailed(dynamic exception, StackTrace trace) {
    appLogger.w('[RealtimeService] channel auth failed', error: exception);
    if (exception is RealtimeForbiddenException) {
      _channelErrorController.add(
        RealtimeChannelError(
          channelName: exception.channelName,
          type: RealtimeChannelErrorType.forbidden,
          message: 'Not authorized for this channel.',
        ),
      );
    } else if (exception is RealtimeAuthException) {
      _channelErrorController.add(
        RealtimeChannelError(
          channelName: exception.channelName,
          type: RealtimeChannelErrorType.sessionExpired,
          message: exception.message,
        ),
      );
    } else {
      _channelErrorController.add(
        RealtimeChannelError(
          channelName: 'unknown',
          type: RealtimeChannelErrorType.unknown,
          message: exception.toString(),
        ),
      );
    }
  }
}
