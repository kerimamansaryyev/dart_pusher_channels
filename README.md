This package is an unofficial pure dart implementation of [Pusher Channels](https://pusher.com/channels).

# Help in development

Author of the package currently needs help with testing the package on other OS platforms:
- Linux
- MacOS

Development and testing of:
- Presence channels
- Encrypted channels

# Contributors
### Maintainer: 

[Kerim Amansaryyev](https://github.com/mcfugger)


### Contributors:

[Nicolas Britos](https://github.com/nicobritos) - Pull requests [#5](https://github.com/mcfugger/dart_pusher_channels/pull/5),
[#6](https://github.com/mcfugger/dart_pusher_channels/pull/6),
[#8](https://github.com/mcfugger/dart_pusher_channels/pull/8)

# Migration from 0.2.X to 0.3.X
`PusherChannelOptions` was deprecated and renamed to `PusherChannelsOptions` for conveniency.

# Description

***Note: This package needs to be tested and accepting issues. It was tested on a few projects for production.***

This package is built according to the [official documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/) of Pusher Channels protocol.

The package has flexibale API containing interfaces for building custom connection and authorization. By default, it supports connection to **Web sockets** over the [web_socket_channel](https://pub.dev/packages/web_socket_channel) out of the box.

# Supported platforms
This package was tested on:
* Anrdoid
* IOS
* Web
* Windows

Other platforms are in a test queue.

# Usage

## PusherChannelsOptions

In order to get known to  the parameters provided to `PusherChannelsOptions`, it's highly recommended to read the informative API reference of [PusherChannelsOptions](https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels_base/PusherChannelsOptions-class.html).

Also, see API references of the constructors to learn more about their parameters:
- [`PusherChannelsOptions.new`](https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels_base/PusherChannelsOptions/PusherChannelsOptions.html)
- [`PusherChannelsOptions.ws`](https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels_base/PusherChannelsOptions/PusherChannelsOptions.ws.html)
- [`PusherChannelsOptions.wss`](https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels_base/PusherChannelsOptions/PusherChannelsOptions.wss.html)

## PusherChannelsClient
Create an instance of `PusherChannelsClient` and use it to establish connection.

1. Create `PusherChannelsOptions`



```dart
const options = PusherChannelsOptions.wss(
      host: 'my.domain.com',
      port: 443,
      key: 'API_KEY',
      protocol: 7);

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

## Milestones
* Triggering events (for now plugin supprts only reading events from channels)
* Presence channels
* Encrypted channels

## Authorization
The package comes with the default delegate for authorizing to private channels over http.

```dart
final privateChannel ??= client.privateChannel(
        'my_private_channel',
        // This is a default authorization delegate
        // to authorize to the channels
        // You may implement your own authorization delegate
        // implementing [AuthorizationDelegate] interface
        // Use `http` or `https` scheme
        TokenAuthorizationDelegate(
            authorizationEndpoint: Uri.parse('http://my.auth.com/api/auth'),
            headers: {'Authorization': 'Bearer [YOUR_TOKEN]'}));
```

## Enabling/disabling logs
By default, logs are disabled.
```dart
PusherChannelsPackageConfigs.enableLogs();
//or
PusherChannelsPackageConfigs.disableLogs();
```
