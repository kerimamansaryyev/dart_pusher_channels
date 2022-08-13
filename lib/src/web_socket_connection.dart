import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/configs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection.dart';
import 'event.dart';
import 'event_names.dart';
import 'options.dart';

class WebSocketChannelConnectionDelegate extends ConnectionDelegate {
  WebSocketChannelConnectionDelegate(
      {required PusherChannelsOptions options,
      required this.pingWaitPongDuration,
      this.eventFactory,
      this.onConnectionErrorHandler,
      this.reconnectTries = 4})
      : super(options: options);

  final RecieveEvent? Function(String name, String? channelName, Map data)?
      eventFactory;

  /// The delegate makes a new try when connection fail is occured
  final int reconnectTries;

  @override
  bool get canConnectSafely => _socketChannel == null;

  @override
  final Duration pingWaitPongDuration;

  @override
  final PublishSubject<ConnectionStatus> connectionStatusController =
      PublishSubject();

  @override
  final PublishSubject<RecieveEvent> onEventRecievedController =
      PublishSubject<RecieveEvent>();

  final void Function(dynamic, StackTrace?)? onConnectionErrorHandler;

  WebSocketChannel? _socketChannel;
  StreamSubscription? _socketChannelSubs;

  Completer<void> _connectionCompleter = Completer();

  int _reconnectTries = 0;

  Duration _activityDuration = const Duration(seconds: 60);

  void _preEventHandler(data) {
    var root = jsonize(data);
    var d = jsonize(root['data']);
    var timeout = d['activity_timeout'];
    if (timeout is int) {
      _activityDuration = Duration(seconds: timeout);
    }
  }

  void _shouldReconnectOnDone() {
    final shouldReconnect = !isDisposed && !isManuallyDisconnected;
    if (shouldReconnect) {
      reconnect();
    } else {
      disconnect();
    }
  }

  @override
  void onEventRecieved(data) {
    _reconnectTries = 0;
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
    await super.connect();
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.complete();
    }
    _connectionCompleter = Completer();
    runZonedGuarded(() {
      _socketChannel = WebSocketChannel.connect(options.uri);
      _socketChannelSubs = _socketChannel?.stream.listen(onEventRecieved,
          cancelOnError: true,
          onError: _onConnectionError,
          onDone: _shouldReconnectOnDone);
    }, _onConnectionError);
    return _connectionCompleter.future;
  }

  @override
  Future<void> disconnect() async {
    await super.disconnect();
    try {
      await _socketChannelSubs?.cancel();
      await _socketChannel?.sink.close().timeout(const Duration(seconds: 10));
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  RecieveEvent? externalEventFactory(
          String name, String? channelName, Map data) =>
      eventFactory?.call(name, channelName, data);

  @override
  void ping() {
    super.ping();
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

  void _onConnectionError(error, trace) {
    PusherChannelsPackageLogger.log('connectionError');
    if (isDisposed) {
      return;
    }
    if (_reconnectTries < reconnectTries) {
      _reconnectTries++;
      reconnect();
    } else {
      passConnectionStatus(ConnectionStatus.connectionError);
      if (!_connectionCompleter.isCompleted) {
        _connectionCompleter.complete();
      }
      onConnectionErrorHandler?.call(error, trace);
      cancelTimer();
    }
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await onEventRecievedController.close();
    await connectionStatusController.close();
  }

  void resetTries() {
    _reconnectTries = 0;
  }
}
