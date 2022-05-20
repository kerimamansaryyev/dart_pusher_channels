import 'dart:html';

import 'channel/channel.dart';
import 'connection.dart';
import 'event.dart';
import 'options.dart';
import 'web_socket_connection.dart';

class PusherChannels {
  final PusherOptions options;
  late final ConnectionDelegate _delegate;
  final Map<String, Channel> _channels = {};
  final bool resubscribeOnError;

  Stream<PusherReadEvent> get onEvent =>
      _delegate.onEvent.map((event) => PusherReadEvent(
          data: event.data, name: event.name, channelName: event.channelName));

  Stream<PusherReadEvent> get onErrorEvent =>
      _delegate.onErrorEvent.map((event) => PusherReadEvent(
          data: event.data, name: event.name, channelName: event.channelName));

  RecieveEvent? _channelEventFactory(
      String name, String? channelName, Map data) {
    if (channelName != null && _channels.containsKey(channelName)) {
      return RecieveEvent(
          data: data,
          name: name,
          onEventRecieved: (name, _, data) {},
          channelName: channelName);
    }

    return null;
  }

  Channel privateChannel(
      String name, AuthorizationDelegate authorizationDelegate,
      {void Function(PusherAuthenticationException error)? onAuthFailed}) {
    var channel = PrivateChannel(
        name: name,
        connectionDelegate: _delegate,
        onAuthFailed: onAuthFailed,
        authorizationDelegate: authorizationDelegate);
    _channels[channel.name] = channel;
    return _channels[channel.name]!;
  }

  Channel publicChannel(String name) {
    var channel = PublicChannel(name: name, connectionDelegate: _delegate);
    _channels[channel.name] = channel;
    return _channels[channel.name]!;
  }

  RecieveEvent? _eventFactory(String name, String? channelName, Map data) {
    return _channelEventFactory(name, channelName, data);
  }

  PusherChannels(
      {required this.options,
      required ConnectionDelegate delegate,
      this.resubscribeOnError = true})
      : _delegate = delegate;

  PusherChannels.websocket(
      {required this.options,
      this.resubscribeOnError = true,
      int reconnectTries = 4,
      void Function(dynamic error, StackTrace trace, VoidCallback? refresh)?
          onConnectionErrorHandle}) {
    _delegate = WebSocketChannelConnectionDelegate(
      options: options,
      reconnectTries: reconnectTries,
      onConnectionErrorHandler: (error, trace) {
        onConnectionErrorHandle?.call(
            error,
            trace,
            (_delegate as WebSocketChannelConnectionDelegate)
                .resetAndReconnect);
        if (resubscribeOnError) {
          resubscribeToChannels();
        }
      },
      eventFactory: _eventFactory,
    );
  }

  void resubscribeToChannels() {
    for (var channel in _channels.values) {
      channel.subscribe();
    }
  }

  Future<void> connect() => _delegate.connect();

  Future<void> close() => _delegate.dispose();
}
