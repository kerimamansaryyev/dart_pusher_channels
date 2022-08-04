import 'package:dart_pusher_channels/base.dart';

import 'channel/channel.dart';
import 'connection.dart';
import 'event.dart';

/// Canonical client structure to connect to a server based
/// on Pusher Channels protocol through [ConnectionDelegate],
/// generating and managing channels internally
class PusherChannelsClient {
  final Map<String, Channel> _channels = {};
  late final ConnectionDelegate _delegate;
  final PusherChannelOptions options;

  PusherChannelsClient({
    required this.options,
    required ConnectionDelegate delegate,
  }) : _delegate = delegate;

  /// Build a client over the Web socket connection
  PusherChannelsClient.websocket({
    required this.options,
    int reconnectTries = 4,
    Duration pingWaitPongDuration =
        PusherChannelsPackageConfigs.defaultPingWaitPongDuration,
    void Function(dynamic error, StackTrace? trace, void Function() refresh)?
        onConnectionErrorHandle,
  }) {
    _delegate = WebSocketChannelConnectionDelegate(
      options: options,
      reconnectTries: reconnectTries,
      onConnectionErrorHandler: (error, trace) {
        onConnectionErrorHandle?.call(error, trace, () async {
          (_delegate as WebSocketChannelConnectionDelegate).resetTries();
          try {
            await reconnect();
            resubscribeToChannels();
          } catch (_) {}
        });
      },
      eventFactory: _eventFactory,
      pingWaitPongDuration: pingWaitPongDuration,
    );
  }

  /// Events received by client's [ConnectionDelegate] and mapped
  /// as [PusherReadEvent]
  Stream<PusherReadEvent> get onEvent => _delegate.onEvent.map(
        (event) => PusherReadEvent(
          data: event.data,
          name: event.name,
          channelName: event.channelName,
        ),
      );

  /// Events with name [PusherEventNames.error] received by client's [ConnectionDelegate] and mapped
  /// as [PusherReadEvent]
  Stream<PusherReadEvent> get onErrorEvent => _delegate.onErrorEvent.map(
        (event) => PusherReadEvent(
          data: event.data,
          name: event.name,
          channelName: event.channelName,
        ),
      );

  /// Emits whenever the connection status of [ConnectionDelegate] is changed
  Stream<ConnectionStatus> get onConnectionStatusChanged =>
      _delegate.onConnectionStatusChanged;

  /// Emits when [ConnectionDelegate] manages to establish connection receiving event
  /// with name [PusherEventNames.connectionEstablished]
  Stream<void> get onConnectionEstablished => _delegate.onConnectionEstablished;

  /// Creating new private channel
  Channel privateChannel(
    String name,
    AuthorizationDelegate authorizationDelegate, {
    void Function(PusherAuthenticationException error)? onAuthFailed,
  }) {
    final channel = PrivateChannel(
      name: name,
      connectionDelegate: _delegate,
      onAuthFailed: onAuthFailed,
      authorizationDelegate: authorizationDelegate,
    );
    _channels[channel.name] = channel;
    return _channels[channel.name]!;
  }

  /// Creating new public channel
  Channel publicChannel(String name) {
    final channel = PublicChannel(name: name, connectionDelegate: _delegate);
    _channels[channel.name] = channel;
    return _channels[channel.name]!;
  }

  void resubscribeToChannels() {
    for (var channel in _channels.values) {
      channel.subscribe();
    }
  }

  /// Connect with current [ConnectionDelegate]
  Future<void> connect() => _delegate.connectSafely();

  /// Permanently close this instance
  Future<void> close() => _delegate.dispose();

  /// Disconnecting with current [ConnectionDelegate]
  Future<void> disconnect() => _delegate.disconnectSafely();

  /// Reconnecting with current [ConnectionDelegate]
  Future<void> reconnect() => _delegate.reconnect();

  ReceiveEvent? _eventFactory(String name, String? channelName, Map data) {
    return _channelEventFactory(name, channelName, data);
  }

  ReceiveEvent? _channelEventFactory(
    String name,
    String? channelName,
    Map data,
  ) {
    if (channelName != null && _channels.containsKey(channelName)) {
      return ReceiveEvent(
        data: data,
        name: name,
        onEventReceived: (name, _, data) {},
        channelName: channelName,
      );
    }

    return null;
  }
}
