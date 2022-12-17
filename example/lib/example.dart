import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

void connectToPusher() async {
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

  PresenceChannel? channel;

  client.onConnectionEstablished.listen((_) {
    channel = client.presenceChannel(
      'presence-channel',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
        headers: const {},
      ),
    );
    client.eventStream.listen((event) {
      print('General event hub: ${event.data.runtimeType}');
    });
    channel!.subscribeIfNotUnsubscribed();
    channel!.whenMemberAdded().listen((event) {
      print(event.data);
      // print(event.tryGetDataAsMap());
      // print(channel?.state?.members?.membersCount);
      // print(channel?.state?.members?.getMap());
    });
    channel!.whenMemberRemoved().listen((event) {
      print(channel?.state?.members?.membersCount);
    });
  });

  unawaited(client.connect());
}
