import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:test/test.dart';

import 'utils/pseudo_connection.dart';

class _Metrics {
  int connections = 0;
  int connectionErrorsCount = 0;
  int disconnectsCount = 0;
  int connectionDisposionsCount = 0;
  int pushErrorsCount = 0;
  int connectionPendingsCount = 0;
  int recconnectsCount = 0;
  int connectionInactivesCount = 0;

  void expectMetricsAreDefault() {
    for (final parameter in [
      connections = 0,
      connectionErrorsCount = 0,
      disconnectsCount = 0,
      connectionDisposionsCount = 0,
      pushErrorsCount = 0,
      connectionPendingsCount = 0,
      recconnectsCount = 0,
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
        'All results will be logged by metrics',
        () async {
          final metrics = _Metrics();
          metrics.expectMetricsAreDefault();
          PseudoConnection pseudoConnection = PseudoConnection();
          final client = PusherChannelsClient.custom(
            connectionDelegate: () => pseudoConnection = PseudoConnection(),
            connectionErrorHandler: (exception, trace, refresh) {
              refresh();
            },
          );
          client.lifecycleStream.listen((event) {
            print(event);
            switch (event) {
              case PusherChannelsClientLifeCycleState.connectionError:
                metrics.connectionErrorsCount++;
                break;
              case PusherChannelsClientLifeCycleState.disconnected:
                metrics.disconnectsCount++;
                break;
              case PusherChannelsClientLifeCycleState.disposed:
                metrics.connectionDisposionsCount++;
                break;
              case PusherChannelsClientLifeCycleState.gotPusherError:
                metrics.pushErrorsCount++;
                break;
              case PusherChannelsClientLifeCycleState.establishedConnection:
                print('asd');
                metrics.connections++;
                break;
              case PusherChannelsClientLifeCycleState.pendingConnection:
                metrics.connectionPendingsCount++;
                break;
              case PusherChannelsClientLifeCycleState.reconnecting:
                metrics.recconnectsCount++;
                break;
              case PusherChannelsClientLifeCycleState.inactive:
                metrics.connectionInactivesCount++;
                break;
            }
          });
          await client.connect();
          expect(
            metrics.connections,
            1,
          );
          expect(
            metrics.connectionPendingsCount,
            1,
          );
          client.reconnect();
        },
      );
    },
  );
}
