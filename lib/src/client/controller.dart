import 'dart:async';
import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/ping_event.dart';
import 'package:dart_pusher_channels/src/events/pong_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';
import 'package:meta/meta.dart';

typedef PusherChannelsConnectionDelegate = PusherChannelsConnection Function();
typedef PusherChannelsClientLifeCycleConnectionErrorHandler = void Function(
  dynamic exception,
  StackTrace trace,
  void Function() refresh,
);
typedef PusherChannelsClientLifeCycleEventHandler = void Function(
  PusherChannelsEvent event,
);

typedef _TimeoutHandler = void Function();

/// Represents a state of a lifecycle of [PusherChannelsClientLifeCycleController]'s instances.
enum PusherChannelsClientLifeCycleState {
  /// Indicates that an error was thrown during a connection.
  connectionError,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] is disconnected.
  disconnected,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] is disposed and
  /// can't be reused.
  disposed,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] has received
  /// an event with name `pusher:error`
  gotPusherError,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] has managed to
  /// successfully establish connection receiving an event with name `pusher:connection_established`.
  ///
  /// Also the controller may set an activity duration accordingly with the received event's properties.
  ///
  /// See docs: [Recommendations for client libraries](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#recommendations-for-client-libraries)
  establishedConnection,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] is trying to
  /// establish connection.
  pendingConnection,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] is reconnecting.
  reconnecting,

  /// Indicates that an instance of [PusherChannelsClientLifeCycleController] is inactive and
  /// has not started the connection lifecycle yet.
  inactive,
}

/// Controls a lifecycle of [PusherChannelsClient] and delegates connection proccess.
///
/// Designed to handle connection and transport in a concurrent, safe way to avoid
/// unexpected connection duplications.
class PusherChannelsClientLifeCycleController {
  int _currentLifeCycleCount = 0;
  bool _isDisposed = false;
  PusherChannelsClientLifeCycleState _currentLifeCycleState =
      PusherChannelsClientLifeCycleState.inactive;
  Completer<void> _connectionCompleter = Completer();
  String? _socketId;
  Duration? _serverActivityDuration;
  Timer? _activityTimer;
  late PusherChannelsConnection? _connection = connectionDelegate();
  final StreamController<PusherChannelsEvent> _eventsController =
      StreamController.broadcast();
  final StreamController<PusherChannelsClientLifeCycleState>
      _lifeCycleStateController = StreamController.broadcast();

  /// Called when a connection error is thrown.
  @protected
  final PusherChannelsClientLifeCycleConnectionErrorHandler
      connectionErrorHandler;

  /// Called to inject an instance of [PusherChannelsConnection] into a controller while
  /// performing connection.
  @protected
  final PusherChannelsConnectionDelegate connectionDelegate;

  /// Called to expose handling received events after the internal ones.
  @protected
  final PusherChannelsClientLifeCycleEventHandler externalEventHandler;

  /// If not null - used as priority above the activity timeout duration sent from a server.
  final Duration? activityDurationOverride;

  /// If [activityDurationOverride] was not provided and a server didn't send an activity timoeout
  /// duration - this value will be used as the activity timeout duration.
  final Duration defaultActivityDuration;

  /// Used to delay an interval between reconnections.
  final Duration minimumReconnectDuration;

  /// Indicates a timeout duration of waiting for the pong message.
  final Duration waitForPongDuration;

  PusherChannelsClientLifeCycleController({
    required this.minimumReconnectDuration,
    required this.externalEventHandler,
    required this.connectionDelegate,
    required this.connectionErrorHandler,
    required this.defaultActivityDuration,
    required this.activityDurationOverride,
    required this.waitForPongDuration,
  });

  /// Fires an instance of [PusherChannelsClientLifeCycleState] when
  /// the lifecycle state will have been changed.
  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      _lifeCycleStateController.stream;

  /// Fires events received from a server.
  Stream<PusherChannelsEvent> get eventStream => _eventsController.stream;

  String? get socketId => _socketId;

  @internal
  Future<void> getCompleterFuture() => _connectionCompleter.future;

  /// Sends the [event] to a server.
  void sendEvent(PusherChannelsSentEventMixin event) {
    _sendEvent(event);
  }

  /// Sends the [event] to a server.
  void triggerEvent(PusherChannelsTriggerEvent event) {
    _triggerEvent(event);
  }

  /// Continues the lifecycle of this controller.
  /// 1. Completes the [_connectionCompleter].
  /// 2. Increases and records [_currentLifeCycleCount].
  /// 3. Sets the lifecycle state to [PusherChannelsClientLifeCycleState.reconnecting].
  /// 4. Closes current connection.
  /// 5. Re-establishes connection calling [_connect].
  ///
  /// See also: [connectSafely]
  Future<void> reconnectSafely() {
    return _reconnect();
  }

  /// Continues the lifecycle of this controller.
  /// 1. (If shouldReInitCompleter is `true`) Completes the [_connectionCompleter].
  /// 2. Increases (if shouldReInitCompleter is `true`) and records [_currentLifeCycleCount].
  /// 3. Sets the lifecycle state to [PusherChannelsClientLifeCycleState.pendingConnection].
  /// 4. Closes current connection.
  /// 5. Re-establishes connection.
  Future<void> connectSafely() {
    return _connect(
      shouldReInitCompleter: true,
    );
  }

  /// Disconnects from the current connection.
  Future<void> disconnectSafely() {
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disconnected);
    return _disconnect();
  }

  /// Closes connection and makes the current instance of this class
  /// unusable.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _disconnect();
    _lifeCycleStateController.close();
    _eventsController.close();
    _currentLifeCycleCount++;
    _completeSafely();
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disposed);
    _isDisposed = true;
  }

  Future<void> _connect({required bool shouldReInitCompleter}) async {
    if (_isDisposed) {
      _isDisposed = true;
    }
    final int fixatedLifeCycleCount;
    if (shouldReInitCompleter) {
      _completeSafely();
      _connectionCompleter = Completer();
      fixatedLifeCycleCount = ++_currentLifeCycleCount;
    } else {
      fixatedLifeCycleCount = _currentLifeCycleCount;
    }

    _changeLifeCycleState(PusherChannelsClientLifeCycleState.pendingConnection);
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    }
    runZonedGuarded(
      () {
        _connection = connectionDelegate();
        _connection!.connect(
          onDoneCallback: () => _shouldReconnectOnDone(
            fixatedLifeCycleCount: fixatedLifeCycleCount,
          ),
          onErrorCallback: (error, trace) => _onConnectionError(
            fixatedLifeCycleCount: fixatedLifeCycleCount,
            exception: error,
            trace: trace,
          ),
          onEventCallback: (event) => _handleEvent(
            event: event,
            fixatedLifeCycleCount: fixatedLifeCycleCount,
          ),
        );
      },
      (error, trace) => _onConnectionError(
        fixatedLifeCycleCount: fixatedLifeCycleCount,
        exception: error,
        trace: trace,
      ),
    );

    return _connectionCompleter.future;
  }

  Future<void> _disconnect() async {
    if (_isDisposed) {
      return;
    }
    final fixatedLifeCycleCount = _currentLifeCycleCount;
    try {
      await _connection?.close();
    } catch (_) {}
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    _connection = null;
    _cancelTimer();
  }

  void _triggerEvent(PusherChannelsTriggerEvent event) {
    final messageEncoded = event.getEncoded();
    PusherChannelsPackageLogger.log('Attempt to trigger: $messageEncoded');
    _sendEvent(event);
  }

  void _sendEvent(PusherChannelsSentEventMixin event) {
    if (_isDisposed) {
      return;
    }
    try {
      _connection?.sendEvent(
        event.getEncoded(),
      );
    } catch (exception, trace) {
      PusherChannelsPackageLogger.log(
        'Failed to send an event "${event.name}" because "$exception" was thrown. Stacktrace:\n $trace',
      );
    }
  }

  Future<void> _reconnect() async {
    if (_isDisposed) {
      return;
    }
    _completeSafely();
    _connectionCompleter = Completer();
    final fixatedLifeCycleCount = ++_currentLifeCycleCount;
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.reconnecting);
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    await Future.delayed(minimumReconnectDuration);
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    }

    return _connect(
      shouldReInitCompleter: false,
    );
  }

  void _changeLifeCycleState(PusherChannelsClientLifeCycleState newState) {
    if (_isDisposed) {
      return;
    }
    if (newState == _currentLifeCycleState) {
      return;
    }

    _currentLifeCycleState = newState;
    _lifeCycleStateController.add(
      _currentLifeCycleState,
    );
    PusherChannelsPackageLogger.log(
      'Current lifecycle state: $_currentLifeCycleState',
    );
  }

  void _completeSafely() {
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.complete();
    }
  }

  void _shouldReconnectOnDone({
    required int fixatedLifeCycleCount,
  }) {
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    }
    if (_currentLifeCycleState ==
        PusherChannelsClientLifeCycleState.disconnected) {
      return;
    }
    _completeSafely();
    _reconnect();
  }

  void _onConnectionError({
    required int fixatedLifeCycleCount,
    required dynamic exception,
    required StackTrace trace,
  }) {
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    } else {
      _changeLifeCycleState(
        PusherChannelsClientLifeCycleState.connectionError,
      );
      connectionErrorHandler(
        exception,
        trace,
        () => unawaited(
          reconnectSafely(),
        ),
      );
      _completeSafely();
    }
  }

  /// Called after successful connection establishment.
  void _establishConnectionParameters(
    String sockId,
    Duration? serverActivityDuration,
  ) {
    _socketId = sockId;
    _serverActivityDuration = serverActivityDuration;
  }

  /// Replies with the pong message if received the
  /// ping message from a server
  void _replyWithPong() {
    _sendEvent(
      const PusherChannelsPongEvent(),
    );
  }

  /// Sends the ping messages and resets the timeout duration
  /// accordingly with [waitForPongDuration].
  void _performPing() {
    PusherChannelsPackageLogger.log(
      'Performing ping, waiting for pong for $waitForPongDuration',
    );
    _connection?.ping();
    _setTimer(
      duration: waitForPongDuration,
      timeoutHandler: _reconnect,
    );
  }

  void _setTimer({
    required Duration duration,
    required _TimeoutHandler timeoutHandler,
  }) {
    _cancelTimer();
    _activityTimer = Timer(duration, timeoutHandler);
    PusherChannelsPackageLogger.log('Timer is set to: $duration');
  }

  void _cancelTimer() {
    _activityTimer?.cancel();
    _activityTimer = null;
    PusherChannelsPackageLogger.log('Timer was canceled');
  }

  /// Handles messages received from a server.
  void _handleEvent({
    required String event,
    required int fixatedLifeCycleCount,
  }) {
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    }
    PusherChannelsPackageLogger.log(
      'Received an event: $event',
    );
    final pusherEvent = _internalEventFactory(event) ??
        PusherChannelsReadEvent.tryParseFromDynamic(event);
    if (pusherEvent is PusherChannelsConnectionEstablishedEvent) {
      _establishConnectionParameters(
        pusherEvent.socketId,
        pusherEvent.activityTimeoutDuration,
      );
      _setTimer(
        duration: _getActivityDuration(),
        timeoutHandler: _performPing,
      );
      _changeLifeCycleState(
        PusherChannelsClientLifeCycleState.establishedConnection,
      );
    } else if (pusherEvent is PusherChannelsErrorEvent) {
      _changeLifeCycleState(PusherChannelsClientLifeCycleState.gotPusherError);
    } else if (pusherEvent is PusherChannelsPongEvent || pusherEvent != null) {
      PusherChannelsPackageLogger.log('Got an event, continuing activity');
      _setTimer(
        duration: _getActivityDuration(),
        timeoutHandler: _performPing,
      );
    }

    if (pusherEvent is PusherChannelsPingEvent) {
      _replyWithPong();
    }

    if (pusherEvent != null) {
      _eventsController.add(pusherEvent);
      Future.microtask(() => externalEventHandler(pusherEvent));
    }

    _completeSafely();
  }

  PusherChannelsEvent? _internalEventFactory(String event) {
    return PusherChannelsConnectionEstablishedEvent.tryParseFromDynamic(
          event,
        ) ??
        PusherChannelsErrorEvent.tryParseFromDynamic(
          event,
        ) ??
        PusherChannelsPongEvent.tryParseFromDynamic(
          event,
        ) ??
        PusherChannelsPingEvent.tryParseFromDynamic(event);
  }

  Duration _getActivityDuration() =>
      activityDurationOverride ??
      _serverActivityDuration ??
      defaultActivityDuration;
}
