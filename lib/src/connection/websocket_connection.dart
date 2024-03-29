import 'dart:async';

import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/events/ping_event.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PusherChannelsWebSocketConnectionWasClosedException
    implements PusherChannelsException {
  @override
  final String message =
      'The instance of PusherChannelsWebSocketConnection is closed and can not be reused';

  const PusherChannelsWebSocketConnectionWasClosedException();
}

/// An implementation of [PusherChannelsConnection] through [WebSocketChannel].
class PusherChannelsWebSocketConnection implements PusherChannelsConnection {
  bool _isClosed = false;
  WebSocketChannel? _webSocketChannel;

  StreamSubscription? _webSocketEventsSubscription;
  final Uri uri;

  PusherChannelsWebSocketConnection({
    required this.uri,
  });

  @override
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  }) {
    if (_isClosed) {
      throw const PusherChannelsWebSocketConnectionWasClosedException();
    }
    _webSocketChannel ??= WebSocketChannel.connect(uri);
    _webSocketEventsSubscription ??= _webSocketChannel?.stream.listen(
      (event) => _onEvent(event.toString(), onEventCallback),
      cancelOnError: true,
      onDone: () => _onDone(onDoneCallback),
      onError: (exception, trace) => _onError(
        exception: exception,
        trace: trace,
        callback: onErrorCallback,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      throw const PusherChannelsWebSocketConnectionWasClosedException();
    }
    _isClosed = true;
    await _webSocketEventsSubscription?.cancel();
    await _webSocketChannel?.sink.close();
  }

  @override
  void sendEvent(String eventEncoded) {
    if (_isClosed) {
      throw const PusherChannelsWebSocketConnectionWasClosedException();
    }
    _webSocketChannel?.sink.add(eventEncoded);
  }

  @override
  void ping() {
    sendEvent(const PusherChannelsPingEvent().getEncoded());
  }

  void _onEvent(
    String event,
    PusherChannelsConnectionOnEventCallback callback,
  ) {
    if (_isClosed) {
      return;
    }
    callback(event);
  }

  void _onDone(PusherChannelsConnectionOnDoneCallback callback) {
    if (_isClosed) {
      return;
    }
    callback();
  }

  void _onError({
    required dynamic exception,
    required StackTrace trace,
    required PusherChannelsConnectionOnErrorCallback callback,
  }) {
    if (_isClosed) {
      return;
    }
    _webSocketChannel = null;
    callback(
      exception,
      trace,
    );
  }
}
