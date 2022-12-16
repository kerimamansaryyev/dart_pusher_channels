import 'dart:async';

import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:test/test.dart';

import 'utils/pseudo_connection.dart';

class _ConnectionMetrics {
  int connectionsCount = 0;
  int connectionErrorsCount = 0;
  int disconnectsCount = 0;
  int connectionDisposionsCount = 0;
  int pushErrorsCount = 0;
  int connectionPendingsCount = 0;
  int reconnectsCount = 0;
  int connectionInactivesCount = 0;

  void expectMetricsAreDefault() {
    for (final parameter in [
      connectionsCount = 0,
      connectionErrorsCount = 0,
      disconnectsCount = 0,
      connectionDisposionsCount = 0,
      pushErrorsCount = 0,
      connectionPendingsCount = 0,
      reconnectsCount = 0,
      connectionInactivesCount = 0,
    ]) {
      expect(
        parameter,
        0,
      );
    }
  }
}

void main() {
  group(
    'dart_pusher_channels integration test',
    () {
      test(
        'Lifecycle states execution order',
        () async {
          final connectionMetrics = _ConnectionMetrics();
          connectionMetrics.expectMetricsAreDefault();
          PseudoConnection pseudoConnection = PseudoConnection();
          final client = PusherChannelsClient.custom(
            connectionDelegate: () => pseudoConnection = PseudoConnection(),
            connectionErrorHandler: (exception, trace, refresh) {
              refresh();
            },
          );
          client.lifecycleStream.listen((event) {
            switch (event) {
              case PusherChannelsClientLifeCycleState.connectionError:
                connectionMetrics.connectionErrorsCount++;
                break;
              case PusherChannelsClientLifeCycleState.disconnected:
                connectionMetrics.disconnectsCount++;
                break;
              case PusherChannelsClientLifeCycleState.disposed:
                connectionMetrics.connectionDisposionsCount++;
                break;
              case PusherChannelsClientLifeCycleState.gotPusherError:
                connectionMetrics.pushErrorsCount++;
                break;
              case PusherChannelsClientLifeCycleState.establishedConnection:
                connectionMetrics.connectionsCount++;
                break;
              case PusherChannelsClientLifeCycleState.pendingConnection:
                connectionMetrics.connectionPendingsCount++;
                break;
              case PusherChannelsClientLifeCycleState.reconnecting:
                connectionMetrics.reconnectsCount++;
                break;
              case PusherChannelsClientLifeCycleState.inactive:
                connectionMetrics.connectionInactivesCount++;
                break;
            }
          });
          unawaited(
            client.connect(),
          );
          // waiting for PusherChannelsClientLifeCycleState.pendingConnection status to be registered
          await _passEventInEventLoop();
          await client.getConnectionCompleterFuture();
          // waiting for PusherChannelsClientLifeCycleState.establishedConnection to be registered
          await _passEventInEventLoop();
          expect(
            connectionMetrics.connectionsCount,
            1,
          );
          unawaited(client.reconnect());
          // waiting for PusherChannelsClientLifeCycleState.reconnecting to be registered
          await _passEventInEventLoop();
          expect(
            connectionMetrics.reconnectsCount,
            1,
          );
          await client.getConnectionCompleterFuture();
          // waiting for PusherChannelsClientLifeCycleState.pendingConnection to be registered
          await _passEventInEventLoop();
          expect(
            connectionMetrics.connectionPendingsCount,
            2,
          );
          // waiting for PusherChannelsClientLifeCycleState.establishedConnection to be registered
          await _passEventInEventLoop();
          expect(
            connectionMetrics.connectionsCount,
            2,
          );
        },
      );
    },
  );
}

Future<void> _passEventInEventLoop() async {}
