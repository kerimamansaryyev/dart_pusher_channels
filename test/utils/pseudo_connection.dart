import 'dart:async';
import 'dart:convert';
import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';

class PseudoConnectionException implements Exception {
  const PseudoConnectionException();
}

class _PseudoSentEvent extends PusherChannelsEvent
    with PusherChannelsSentEventMixin {
  @override
  final String name;
  final String? channel;
  final Map<String, dynamic>? data;
  final String? userId;

  _PseudoSentEvent({
    required this.channel,
    required this.data,
    required this.name,
    required this.userId,
  });

  factory _PseudoSentEvent.connectionEstablished() => _PseudoSentEvent(
        channel: null,
        data: {
          'socket_id': 123,
        },
        name: PusherChannelsConnectionEstablishedEvent.eventName,
        userId: null,
      );

  @override
  String getEncoded() => jsonEncode(
        {
          PusherChannelsEvent.eventNameKey: name,
          if (channel != null) PusherChannelsEvent.channelKey: channel,
          if (data != null)
            PusherChannelsEvent.dataKey: jsonEncode(
              data,
            ),
          if (userId != null) PusherChannelsEvent.userIdKey: userId,
        },
      );
}

class PseudoConnection extends PusherChannelsConnection {
  bool _isClosed = false;
  final StreamController<String> _controller = StreamController.broadcast();
  StreamSubscription? _subscription;

  void addError() => _controller.addError(
        const PseudoConnectionException(),
      );

  @override
  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    _subscription?.cancel();
    _controller.close();
  }

  @override
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  }) {
    _subscription = _controller.stream.listen(
      (event) => _onEvent(event, onEventCallback),
      onError: (error, trace) => _onError(
        exception: error,
        trace: trace,
        callback: onErrorCallback,
      ),
      onDone: () => _onDone(
        onDoneCallback,
      ),
      cancelOnError: false,
    );

    _controller.add(
      _PseudoSentEvent.connectionEstablished().getEncoded(),
    );
  }

  @override
  void ping() {}

  @override
  void sendEvent(String eventEncoded) {}

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
    callback(
      exception,
      trace,
    );
  }
}
