This package is an unofficial pure dart implementation of [Pusher Channels](https://pusher.com/channels).

# Help in development

Author of the package currently needs help with testing the package on other OS platforms and some test servers using Pusher protocol to implement encrypted and presence channels.

# Description

***Note: This package needs to be tested and accepting issues. It was tested on a few projects for production.***

This package is built according to the [official documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) of Pusher Channels protocol.

The package has flexibale API containing interfaces for building custom connection and authorization. By default, it supports connection to **Web sockets** over the [web_socket_channel](https://pub.dev/packages/web_socket_channel) out of the box.

# Supported platforms
This package was tested on:
* Anrdoid
* IOS
* Web

Other platforms are in a test queue.

# Usage

## PusherChannelOptions

1. Create `PusherChannelOptions`



```dart
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

```
2. Create the client.

Use `PusherChannelsClient.websocket` constructor to create a client based on web sockets.

```dart
final client = PusherChannelsClient.websocket(
      reconnectTries: 2,
      options: options,
      // Handle the errors based on the web sockets connection
      onConnectionErrorHandle: (error, trace, refresh) {});
```

3. Create channels and listen for events.

```dart
// Ensure you implement your logic
  // after successfull connection to your server
  Channel? channel;
  StreamSubscription? eventSubscription;
  // This stream will recieve events and notify subscribers
  // whenever the client is connected or reconnected after potential error
  client.onConnectionEstablished.listen((_) async {
    channel ??= client.publicChannel('my_public_channel_name');
    await eventSubscription?.cancel();
    // Ensure you bind to the channel before subscribing,
    // otherwise - you will miss some events
    eventSubscription = channel?.bind('my_event').listen((event) {
      //listen for events form the channel here
    });
    channel!.subscribe();
  });
  client.connect();
  // unsubscribe when done with channel
  eventSubscription?.cancel();
  channel?.unsubscribe();
  //close when done with client
  client.close();
```


## Channels and events

**Note: For now, the package supports only reading (recieving) events. Triggering events is in the milestones.**

The package supports 2 types of channels:
* Public
* Private

Presence channels and encrypted channels are in the milestones.

## Authorization
The package comes with the default delegate for authorizing to private channels over http.

```dart
final privateChannel ??= client.privateChannel(
        'my_private_channel',
        // This is a default authorization delegate
        // to authorize to the channels
        // You may implement your own authorization delegate
        // implementing [AuthorizationDelegate] interface
        TokenAuthorizationDelegate(
            authorizationEndpoint: Uri.parse('http://my,auth.com/api/auth'),
            headers: {'Authorization': 'Bearer [YOUR_TOKEN]'}));
```
