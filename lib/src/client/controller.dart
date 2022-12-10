import 'dart:async';

import 'package:dart_pusher_channels/src/client/controller_interaction_interface.dart';
import 'package:dart_pusher_channels/src/client/observer.dart';
import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/pong_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

typedef PusherChannelsConnectionDelegate = PusherChannelsConnection Function();
typedef PusherChannelsClientLifeCycleConnectionErrorHandler = void Function(
  dynamic exception,
  StackTrace trace,
  void Function() refresh,
);
typedef PusherChannelsClientLifeCycleObserversDelegate
    = List<PusherChannelsClientLifeCycleObserver> Function(
  PusherChannelsClientLifeCycleInteractionInterface interactionInterface,
);

enum PusherChannelsClientLifeCycleState {
  connectionError,
  disconnected,
  disposed,
  gotPusherError,
  establishedConnection,
  pendingConnection,
  inactive,
}

class PusherChannelsClientLifeCycleController {
  int _currentLifeCycleCount = 0;
  bool _isDisposed = false;
  PusherChannelsClientLifeCycleState _currentLifeCycleState =
      PusherChannelsClientLifeCycleState.inactive;
  Completer<void> _connectionCompleter = Completer();
  late PusherChannelsConnection? _connection = connectionDelegate();
  final StreamController<PusherChannelsClientLifeCycleState>
      _lifeCycleStateController = StreamController.broadcast();

  @protected
  final PusherChannelsClientLifeCycleConnectionErrorHandler
      connectionErrorHandler;
  @protected
  final PusherChannelsConnectionDelegate connectionDelegate;
  @protected
  final PusherChannelsClientLifeCycleObserversDelegate observersDelegate;

  late final PusherChannelsClientLifeCycleInteractionInterface
      interactionInterface = PusherChannelsClientLifeCycleInteractionInterface(
    reconnectDelegate: reconnectSafely,
    sendEventDelegate: _sendEvent,
  );

  late final List<PusherChannelsClientLifeCycleObserver> _observers = [
    ...observersDelegate(
      interactionInterface,
    ),
  ];

  PusherChannelsClientLifeCycleController({
    required this.connectionDelegate,
    required this.connectionErrorHandler,
    required this.observersDelegate,
  });

  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      _lifeCycleStateController.stream;

  Future<void> connectSafely() {
    return _connect();
  }

  Future<void> disconnectSafely() {
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disconnected);
    return _disconnect();
  }

  void reconnectSafely() {
    _reconnect();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _currentLifeCycleCount++;
    _completeSafely();
    await _disconnect();
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.disposed);
    await _lifeCycleStateController.close();
  }

  Future<void> _connect() async {
    _completeSafely();
    final fixatedLifeCycleCount = ++_currentLifeCycleCount;
    _changeLifeCycleState(PusherChannelsClientLifeCycleState.pendingConnection);
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    _connectionCompleter = Completer();
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
  }

  void _sendEvent(PusherChannelsSentEventMixin event) {
    try {
      _connection?.sendEvent(
        event.getEncoded(),
      );
    } catch (_) {}
  }

  void _reconnect() async {
    final fixatedLifeCycleCount = _currentLifeCycleCount;
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    unawaited(
      _connect(),
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
        interactionInterface.reconnect,
      );
      _completeSafely();
    }
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
        );
  }

  void _handleEvent({
    required String event,
    required int fixatedLifeCycleCount,
  }) {
    if (fixatedLifeCycleCount < _currentLifeCycleCount || _isDisposed) {
      return;
    }
    final pusherEvent = _internalEventFactory(event) ??
        PusherChannelsReadEvent.tryParseFromDynamic(event);
    if (pusherEvent is PusherChannelsConnectionEstablishedEvent) {
      _changeLifeCycleState(
        PusherChannelsClientLifeCycleState.establishedConnection,
      );
    } else if (pusherEvent is PusherChannelsErrorEvent) {
      _changeLifeCycleState(PusherChannelsClientLifeCycleState.gotPusherError);
    }
    _completeSafely();
  }
}
