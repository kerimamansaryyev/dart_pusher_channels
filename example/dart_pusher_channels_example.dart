import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';

void main() {
  PusherChannelsPackageLogger.enableLogs();
  const testOptions = PusherChannelsOptions.fromCluster(
    scheme: 'wss',
    cluster: 'mt1',
    key: 'a0173cd5499b34d93109',
    port: 443,
  );
  final client = PusherChannelsClient.websocket(
    options: testOptions,
    connectionErrorHandler: (exception, trace, refresh) {
      print('Exception: $exception');
    },
  );
  client.connect();
  Stream.periodic(
    const Duration(seconds: 3),
  ).listen((_) {
    client.trigger(
      PusherChannelsTriggerEvent(
        name: 'client-event',
        data: {'data': 'hello client'},
        channelName: 'presence-channel',
      ),
    );
  });
}
