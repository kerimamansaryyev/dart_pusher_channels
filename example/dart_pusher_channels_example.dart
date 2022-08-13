import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

void main() {
  // You may enable logs to see what's going on
  PusherChannelsPackageConfigs.enableLogs();

  // Creating the options.
  // Need help with the options? Checkout the informative API reference of [PusherChannelOptions](https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels_base/PusherChannelOptions-class.html)
  const options = PusherChannelOptions.wss(
      host: 'my.domain.com', port: 443, key: 'API_KEY', protocol: 7);

  final client = PusherChannelsClient.websocket(
      reconnectTries: 2,
      options: options,
      // Handle the errors based on the web sockets connection
      onConnectionErrorHandle: (error, trace, refresh) {});

  // Ensure you implement your logic
  // after successfull connection to your server
  Channel? channel;
  Channel? privateChannel;
  StreamSubscription? eventSubscription;
  StreamSubscription? privateChannelEventSubscription;
  // This stream will recieve events and notify subscribers
  // whenever the client is connected or reconnected after potential error
  client.onConnectionEstablished.listen((_) async {
    channel ??= client.publicChannel('my_public_channel_name');
    privateChannel ??= client.privateChannel(
        'my_private_channel',
        // This is a default authorization delegate
        // to authorize to the channels
        // You may implement your own authorization delegate
        // implementing [AuthorizationDelegate] interface
        TokenAuthorizationDelegate(
            // User `http` or `https` scheme
            authorizationEndpoint: Uri.parse('http://my.auth.com/api/auth'),
            headers: {'Authorization': 'Bearer [YOUR_TOKEN]'}));
    await eventSubscription?.cancel();
    await privateChannelEventSubscription?.cancel();
    // Ensure you bind to the channel before subscribing,
    // otherwise - you will miss some events
    eventSubscription = channel!.bind('my_event').listen((event) {
      //listen for the event from the channel here
    });
    privateChannelEventSubscription =
        privateChannel!.bind('my_event_from_private_channel').listen((event) {
      //listen for the event from the private channel here
    });
    channel!.subscribe();
  });
  client.connect();
  // unsubscribe when done with channels
  privateChannelEventSubscription?.cancel();
  eventSubscription?.cancel();
  channel?.unsubscribe();
  privateChannel?.unsubscribe();
  //close when done with client
  client.close();
}
