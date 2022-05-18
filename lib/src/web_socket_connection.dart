import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'connection.dart';
import 'event.dart';
import 'event_names.dart';
import 'options.dart';

class WebSocketChannelConnectionDelegate extends ConnectionDelegate {
  WebSocketChannelConnectionDelegate(
      {required PusherOptions options,
      this.eventFactory,
      this.reconnectTries = 4,
      this.onConnectionErrorHandler})
      : super(options: options);

  int _reconnectTries = 0;

  final RecieveEvent? Function(String name, String? channelName, Map data)?
      eventFactory;

  final void Function(dynamic error, StackTrace trace)?
      onConnectionErrorHandler;

  final int reconnectTries;

  WebSocketChannel? _socketChannel;

  Completer<void> _connectionCompleter = Completer();

  Duration _activityDuration = const Duration(seconds: 60);

  void _preEventHandler(data) {
    var root = jsonize(data);
    var d = jsonize(root['data']);
    var timeout = d['activity_timeout'];
    if (timeout is int) {
      _activityDuration = Duration(seconds: timeout);
    }
  }

  @override
  void reconnect() async {
    if (_reconnectTries >= reconnectTries) {
      await disconnect();
      await cancelTimer();
    } else {
      super.reconnect();
    }
  }

  @override
  void onEventRecieved(data) {
    _preEventHandler(data);
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.complete();
    }
    super.onEventRecieved(data);
  }

  @override
  Duration get activityDuration => _activityDuration;

  @override
  Future<void> connect() async {
    _connectionCompleter = Completer();
    runZonedGuarded(() {
      _socketChannel = WebSocketChannel.connect(options.uri);
      _socketChannel?.stream.listen(onEventRecieved);
    }, onConnectionError);
    resetTimer();
    return _connectionCompleter.future;
  }

  @override
  Future<void> disconnect() async {
    await _socketChannel?.sink.close();
  }

  @override
  RecieveEvent? externalEventFactory(
          String name, String? channelName, Map data) =>
      eventFactory?.call(name, channelName, data);

  @override
  final PublishSubject<void> onConnectedController = PublishSubject<void>();

  @override
  final PublishSubject<RecieveEvent> onEventRecievedController =
      PublishSubject<RecieveEvent>();

  @override
  void ping() {
    send(SendEvent(data: {}, name: PusherEventNames.ping, channelName: null));
  }

  @override
  void send(SendEvent event) {
    _socketChannel?.sink.add(jsonEncode({
      'event': event.name,
      if (event.channelName != null) 'channel': event.channelName,
      'data': {...event.data}
    }));
  }

  @override
  void onConnectionError(error, trace) {
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.completeError(error, trace);
      onConnectionErrorHandler?.call(error, trace);
      _reconnectTries++;
    }
  }
}
