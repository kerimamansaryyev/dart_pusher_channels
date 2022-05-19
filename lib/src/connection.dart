import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'event.dart';
import 'event_names.dart';
import 'options.dart';

abstract class ConnectionDelegate {
  Duration get activityDuration;

  final PusherOptions options;

  ConnectionDelegate({required this.options});

  String? _socketId;

  String? get socketId => _socketId;

  @protected
  set socketId(String? newId) {
    _socketId = newId;
  }

  @protected
  StreamController<void> get onConnectedController;
  @protected
  StreamController<ReadEvent> get onEventRecievedController;

  Stream<void> get onConnection => onConnectedController.stream;
  Stream<ReadEvent> get onErrorEvent =>
      onEvent.where((event) => event.name == PusherEventNames.error);
  Stream<ReadEvent> get onEvent => onEventRecievedController.stream;

  void onConnectionError(dynamic error, StackTrace trace);

  Future<void> connect();
  Future<void> disconnect();

  void ping();

  void send(SendEvent event);

  void onErrorHandler(Map data) {}

  void onConnectionHanlder() {}

  @protected
  RecieveEvent? externalEventFactory(
      String name, String? channelName, Map data);

  @protected
  RecieveEvent? internalEventFactory(String name, Map data) {
    switch (name) {
      case PusherEventNames.error:
        var event = RecieveEvent(
            data: data,
            name: name,
            channelName: null,
            onEventRecieved: (_, ___, d) => onErrorHandler(d));
        return event;
      case PusherEventNames.connectionEstablished:
        onPong();
        print(data);
        var sockId = data["socket_id"]?.toString();
        socketId = sockId;
        print(socketId);
        var event = RecieveEvent(
            data: data,
            name: name,
            channelName: null,
            onEventRecieved: (_, ___, __) => onConnectionHanlder());
        onConnectedController.add(null);
        return event;
      case PusherEventNames.pong:
        var event = RecieveEvent(
            channelName: null,
            data: data,
            name: name,
            onEventRecieved: (_, __, ___) => onPong());
        return event;
      default:
        return null;
    }
  }

  @protected
  Map jsonize(raw) {
    Map data;
    if (raw is String) {
      data = jsonDecode(raw);
    } else {
      data = {};
    }
    return data;
  }

  @protected
  void reconnect() async {
    await disconnect();
    connect();
  }

  @mustCallSuper
  @protected
  void onEventRecieved(data) async {
    print(data);
    Map raw = jsonize(data);
    var name = raw['event']?.toString() ?? "";
    var payload = jsonize(raw['data']);
    var channelName = raw['channel']?.toString();
    var event = internalEventFactory(name, payload) ??
        externalEventFactory(name, channelName, payload);

    event?.callHandler();

    if (event != null) {
      onEventRecievedController.add(event);
    }

    await resetTimer();
  }

  bool _pongRecieved = false;

  StreamSubscription? _timerSubs;

  @protected
  void onPong() {
    _pongRecieved = true;
  }

  @protected
  void checkPong() {
    if (_pongRecieved) {
      _pongRecieved = false;
      ping();
    } else {
      reconnect();
    }
  }

  Future<void> resetTimer() async {
    await _timerSubs?.cancel();
    _timerSubs = Stream.periodic(activityDuration).listen((_) {
      checkPong();
    });
  }

  Future<void> cancelTimer() async {
    await _timerSubs?.cancel();
  }
}
