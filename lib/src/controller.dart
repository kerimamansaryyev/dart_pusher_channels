import 'dart:async';

import 'package:dart_pusher_channels/src/connection/connection.dart';
import 'package:dart_pusher_channels/src/events/connection_established_event.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/pong_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

typedef PusherChannelsConnectionDelegate = PusherChannelsConnection Function();

enum PusherChannelsClientLifeCycleState {
  pendingConnection,
  connectionError,
  none,
}

typedef PusherChannelsClientConnectionLifeCycleControllerConnectionErrorHandler
    = void Function(
  dynamic exception,
  StackTrace trace,
);

class PusherChannelsClientConnectionLifeCycleController {
  int _currentLifeCycleCount = 0;
  bool _isDisposed = false;
  PusherChannelsClientLifeCycleState _currentLifeCycleState =
      PusherChannelsClientLifeCycleState.none;
  Completer<void> _connectionCompleter = Completer();
  late PusherChannelsConnection? _connection = connectionDelegate();
  final StreamController<PusherChannelsClientLifeCycleState>
      _lifeCycleStateController = StreamController.broadcast();

  @protected
  final PusherChannelsClientConnectionLifeCycleControllerConnectionErrorHandler
      connectionErrorHandler;
  @protected
  final PusherChannelsConnectionDelegate connectionDelegate;

  PusherChannelsClientConnectionLifeCycleController({
    required this.connectionDelegate,
    required this.connectionErrorHandler,
  });

  Future<void> connect() async {
    _completeSafely();
    final fixatedLifeCycleCount = ++_currentLifeCycleCount;
    _connectionCompleter = Completer();
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
  }

  void _reconnect() async {
    final fixatedLifeCycleCount = _currentLifeCycleCount;
    await _disconnect();
    if (fixatedLifeCycleCount < _currentLifeCycleCount) {
      return;
    }
    unawaited(
      connect(),
    );
  }

  void _changeLifeCycleState(PusherChannelsClientLifeCycleState newState) {
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
      );
    }
  }

  PusherChannelsPredefinedEventMixin? _internalEventFactory(String event) {
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
  }
}
