import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

void main() {
  //Creating options to use the client over wss:// scheme
  const options = PusherChannelOptions.wss(
      host: 'my.domain.com',
      //By default the servers using pusher over wss://
      // work on 443 port. Specify the port according to your server.
      port: 443,
      //Paste your API key that you get after registering and creating a project on Pusher
      key: 'API_KEY',
      //The package was tested on the newer versions of Pusher protocol
      // It is recommended to keep the version of the protocol on your server up-to-data
      protocol: 7,
      version: '7.0.3');

  final client = PusherChannels.websocket(
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
  // This stream will recieve events and call the callback
  // below whenever the client is connected and reconnected after potential error
  client.onConnectionEstablished.listen((_) async {
    channel ??= client.publicChannel('my_public_channel_name');
    privateChannel ??= client.privateChannel(
        'my_private_channel',
        // This is a default authorization delegate
        // to authorize to the channels
        // You may implement your own authorization delegate
        // implementing [AuthorizationDelegate] interface
        TokenAuthorizationDelegate(
            authorizationEndpoint: Uri.parse('http://my,auth.com/api/auth'),
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
}
