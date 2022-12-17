import 'dart:async';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/http_token_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/extensions/channel_extension.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
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
