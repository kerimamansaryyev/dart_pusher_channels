import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/configs.dart';
import 'package:meta/meta.dart';

import 'event.dart';
import 'event_names.dart';
import 'options.dart';

/// Used to describe connection status to a server by [ConnectionStatus]
enum ConnectionStatus {
  /// When [ConnectionDelegate] is disconnected from a server
  disconnected,

  /// When connection is set, but not established
  /// For example: in case if a server sends [PusherEventNames.error] when your api key is not valid
  connected,

  /// Failed to connect to a server
  connectionError,

  /// While waiting for connection
  pending,

  /// When a server sends [PusherEventNames.connectionEstablished]
  established
}

/// Special interface to describe connection, recieveing and sending events
abstract class ConnectionDelegate {
  /// Value that used as a time-out to let know the delegate to call [checkPong]
  @protected
  Duration get activityDuration;

  /// If [PusherEventNames.pong] was recieved then this duration is set to timer
  /// while waiting for pong next time
  @protected
  Duration get pingWaitPongDuration;

  /// Constraints of the delegate
  final PusherChannelOptions options;

  ConnectionDelegate({required this.options});

  String? _socketId;
  bool _pongRecieved = false;
  bool _isDisconnectedManually = false;
  Timer? _timer;

  /// Socket id sent from the server after connection is established
  String? get socketId => _socketId;

  @mustCallSuper
  @protected
  set socketId(String? newId) {
    _socketId = newId;
  }

  /// Controller to notify subscribers about connection status.
  @protected
  StreamController<ConnectionStatus> get connectionStatusController;

  /// Controller to notify subscribers when event recieved from a server
  @protected
  StreamController<RecieveEvent> get onEventRecievedController;

  /// Notifies subscribers whenever the delegate recieves [PusherEventNames.connectionEstablished]
  Stream<void> get onConnectionEstablished => connectionStatusController.stream
      .where((event) => event == ConnectionStatus.established);

  /// Notifies subscribers whenever the delegate recieves [PusherEventNames.error]
  Stream<RecieveEvent> get onErrorEvent =>
      onEvent.where((event) => event.name == PusherEventNames.error);
  Stream<RecieveEvent> get onEvent => onEventRecievedController.stream;

  /// Notifies subscribers when connection status is changed
  Stream<ConnectionStatus> get onConnectionStatusChanged =>
      connectionStatusController.stream;

  /// Connect to a server
  @mustCallSuper
  Future<void> connect() async {
    _isDisconnectedManually = false;
    await cancelTimer();
    PusherChannelsPackageLogger.log(ConnectionStatus.pending);
    passConnectionStatus(ConnectionStatus.pending);
  }

  /// Disconnect from server
  @mustCallSuper
  Future<void> disconnect() async {
    _isDisconnectedManually = true;
    await cancelTimer();
    PusherChannelsPackageLogger.log(ConnectionStatus.disconnected);
    passConnectionStatus(ConnectionStatus.disconnected);
  }

  /// Ping a server when [activityDuration] exceeds
  @mustCallSuper
  @protected
  void ping() {
    PusherChannelsPackageLogger.log('pinging');
  }

  /// Send events
  void send(SendEvent event);

  /// Called when event with name [PusherEventNames.error] is identified by [internalEventFactory]
  @protected
  void onErrorHandler(Map data) {}

  /// Called when connection is established
  @protected
  void onConnectionHanlder() {}

  /// Internal API to pass [ConnectionStatus] to sink of [connectionStatusController]
  @mustCallSuper
  @protected
  void passConnectionStatus(ConnectionStatus status) {
    if (!connectionStatusController.isClosed) {
      connectionStatusController.add(status);
    }
  }

  /// External event factory to return events if [internalEventFactory] returns null
  @protected
  RecieveEvent? externalEventFactory(
      String name, String? channelName, Map data);

  /// Identifies Pusher's internal events
  @mustCallSuper
  @protected
  RecieveEvent? internalEventFactory(String name, Map data) {
    switch (name) {
      case PusherEventNames.error:
        var event = RecieveEvent(
            data: data,
            name: name,
            channelName: null,
            onEventRecieved: (_, ___, d) => onErrorHandler(d));
        if (!connectionStatusController.isClosed) {
          connectionStatusController.add(ConnectionStatus.connected);
        }
        return event;
      case PusherEventNames.connectionEstablished:
        var sockId = data["socket_id"]?.toString();
        socketId = sockId;
        var event = RecieveEvent(
            data: data,
            name: name,
            channelName: null,
            onEventRecieved: (_, ___, __) => onConnectionHanlder());
        if (!connectionStatusController.isClosed) {
          connectionStatusController.add(ConnectionStatus.established);
        }
        return event;
      case PusherEventNames.pong:
        var event = RecieveEvent(
            channelName: null,
            data: data,
            name: name,
            onEventRecieved: (_, __, ___) {});
        return event;
      default:
        return null;
    }
  }

  /// Internal api for deserialization of event's data
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

  /// Reconnect to server
  @mustCallSuper
  void reconnect() async {
    await disconnect();
    connect();
  }

  /// Deserializes string from a server to [RecieveEvent] with factories and calls its `callHandler` method
  @mustCallSuper
  @protected
  void onEventRecieved(data) async {
    if (_isDisconnectedManually) return;
    await onPong();
    PusherChannelsPackageLogger.log(data);
    Map raw = jsonize(data);
    var name = raw['event']?.toString() ?? "";
    var payload = jsonize(raw['data']);
    var channelName = raw['channel']?.toString();
    var event = internalEventFactory(name, payload) ??
        externalEventFactory(name, channelName, payload);

    event?.callHandler();

    if (event != null && !onEventRecievedController.isClosed) {
      onEventRecievedController.add(event);
    }
  }

  /// When event with name [PusherEventNames.pong] is recieved
  @mustCallSuper
  @protected
  Future<void> onPong() {
    PusherChannelsPackageLogger.log('Got pong');
    _pongRecieved = true;
    return resetTimer();
  }

  /// Pings connection when [activityDuration] exceeds.
  @mustCallSuper
  @protected
  void checkPong() {
    PusherChannelsPackageLogger.log('checking for pong');
    if (_pongRecieved) {
      _pongRecieved = false;
      ping();
      resetTimer(pingWaitPongDuration);
    } else {
      reconnect();
    }
  }

  /// Closing all sinks and disconnecting from a server
  @mustCallSuper
  Future<void> dispose() async {
    try {
      await disconnect();
      // ignore: empty_catches
    } catch (e) {}
    isDisposed = true;
    await cancelTimer();
  }

  /// Called when [pings] or [reconnect] succeed to connect or ping to a server
  @mustCallSuper
  @protected
  Future<void> resetTimer([Duration? timeoutDuration]) async {
    _timer?.cancel();
    _timer = null;
    final duration = timeoutDuration ?? activityDuration;
    PusherChannelsPackageLogger.log(
        'Timer is reset. Activity duration: $duration');
    _timer = Timer(duration, checkPong);
  }

  /// Cancelling a timer
  @mustCallSuper
  @protected
  Future<void> cancelTimer() async {
    PusherChannelsPackageLogger.log('Timer is canceled');
    _timer?.cancel();
    _timer = null;
  }

  @protected
  bool isDisposed = false;
}
