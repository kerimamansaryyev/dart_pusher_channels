import 'dart:async';
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

enum PusherChannelsClientLifeCycleState {
  connectionError,
  disconnected,
  disposed,
  gotPusherError,
  establishedConnection,
  pendingConnection,
  reconnecting,
  inactive,
}

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

  @protected
  final PusherChannelsClientLifeCycleConnectionErrorHandler
      connectionErrorHandler;
  @protected
  final PusherChannelsConnectionDelegate connectionDelegate;
  @protected
  final PusherChannelsClientLifeCycleEventHandler externalEventHandler;

  final Duration? activityDurationOverride;
  final Duration defaultActivityDuration;
  final Duration minimumReconnectDuration;
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

  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      _lifeCycleStateController.stream;

  Stream<PusherChannelsEvent> get eventStream => _eventsController.stream;

  String? get socketId => _socketId;

  @internal
  Future<void> getCompleterFuture() => _connectionCompleter.future;

  void sendEvent(PusherChannelsSentEventMixin event) {
    _sendEvent(event);
  }

  void triggerEvent(PusherChannelsTriggerEvent event) {
    _triggerEvent(event);
  }

  Future<void> reconnectSafely() {
    return _reconnect();
  }

  Future<void> connectSafely() {
    return _connect(
      shouldReInitCompleter: true,
    );
  }

  Future<void> disconnectSafely() {
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disconnected);
    return _disconnect();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _currentLifeCycleCount++;
    _completeSafely();
    await _disconnect();
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disposed);
    await _lifeCycleStateController.close();
    await _eventsController.close();
  }

  Future<void> _connect({required bool shouldReInitCompleter}) async {
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
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
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
    _completeSafely();
    _connectionCompleter = Completer();
    final fixatedLifeCycleCount = ++_currentLifeCycleCount;
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.reconnecting);
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    await Future.delayed(minimumReconnectDuration);
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }

    return _connect(
      shouldReInitCompleter: false,
    );
  }

  void _changeLifeCycleState(PusherChannelsClientLifeCycleState newState) {
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

  void _establishConnectionParameters(
    String sockId,
    Duration? serverActivityDuration,
  ) {
    _socketId = sockId;
    _serverActivityDuration = serverActivityDuration;
  }

  void _replyWithPong() {
    _sendEvent(
      const PusherChannelsPongEvent(),
    );
  }

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
