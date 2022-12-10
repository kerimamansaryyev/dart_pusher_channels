import 'dart:async';

import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:dart_pusher_channels/src/utils/logger.dart';

void main() async {
  Stream.periodic(const Duration(seconds: 5)).listen((event) {});
  PusherChannelsPackageLogger.enableLogs();
  const testOptions = PusherChannelsOptions.fromCluster(
    scheme: 'wss',
    cluster: 'mt1',
    key: 'a0173cd5499b34d93109',
    port: 443,
  );
  final client = PusherChannelsClient.websocket(
    activityDurationOverride: const Duration(seconds: 10),
    options: testOptions,
    connectionErrorHandler: (exception, trace, refresh) async {
      print('Exception: $exception');
      refresh();
    },
  );

  PublicChannel? channel;

  client.onConnectionEstablished.listen((_) {
    channel = client.publicChannel(
      'hello',
      whenChannelStateChanged: (state) {
        print(state.status);
      },
    );
    channel!.subscribeIfNotUnsubscribed();
  });

  unawaited(client.connect());

  await Future.delayed(
    const Duration(seconds: 3),
  );
  await Future.delayed(
    const Duration(seconds: 3),
  );
  client.reconnect();
}
