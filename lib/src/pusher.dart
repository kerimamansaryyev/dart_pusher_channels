import 'channel/channel.dart';
import 'connection.dart';
import 'event.dart';
import 'options.dart';
import 'web_socket_connection.dart';

class PusherChannels {
  final PusherOptions options;
  late final ConnectionDelegate _delegate;
  final Map<String, Channel> _channels = {};

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

  Channel privateChannel(String name) {
    var channel = PrivateChannel(
        name: name,
        connectionDelegate: _delegate,
        authorizationDelegate: TokenAuthorizationDelegate(
            authorizationEndpoint: Uri.parse('uri'), headers: {}));
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

  PusherChannels({required this.options, required ConnectionDelegate delegate})
      : _delegate = delegate;

  PusherChannels.websocket(
      {required this.options,
      int reconnectTries = 4,
      void Function(dynamic error, StackTrace trace)?
          onConnectionErrorHandle}) {
    _delegate = WebSocketChannelConnectionDelegate(
      options: options,
      reconnectTries: reconnectTries,
      eventFactory: _eventFactory,
    );
  }

  Future<void> connect() => _delegate.connect();

  Future<void> close() => _delegate.disconnect();
}
