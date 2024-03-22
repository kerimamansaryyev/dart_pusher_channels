  [![Pub Version](https://img.shields.io/pub/v/dart_pusher_channels?logo=dart&logoColor=white)](https://pub.dev/packages/dart_pusher_channels/)[![Dart SDK Version](https://badgen.net/pub/sdk-version/dart_pusher_channels)](https://pub.dev/packages/dart_pusher_channels/)[![License](https://img.shields.io/github/license/kerimamansaryyev/dart_pusher_channels)](https://github.com/kerimamansaryyev/dart_pusher_channels/blob/master/LICENSE)[![Pub popularity](https://badgen.net/pub/popularity/dart_pusher_channels)](https://pub.dev/packages/dart_pusher_channels/score)[![GitHub popularity](https://img.shields.io/github/stars/kerimamansaryyev/dart_pusher_channels?logo=github&logoColor=white)](https://github.com/kerimamansaryyev/dart_pusher_channels/stargazers)   

Introducing `dart_pusher_channels` - a client library of [Pusher Channels](https://pusher.com/channels) implemented in pure Dart. Structure of the package is built according to the [official documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#recommendations-for-client-libraries) of the protocol.

Starting from version `1.0.0` the package has become more canonical, enhanced and extendable for further updates and features. 

The project will continue to grow and will be maintained. Your support is appreciated and will highly motivate the author to improve the package. If you've found this library helpful and want to support the author, please, consider the donation by clicking the button below or following the link to [buymeacoffee.com](https://www.buymeacoffee.com/kerimdeveloper). 

<a href="https://www.buymeacoffee.com/kerimdeveloper" target="_blank"><img align="center" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="55px" width= "200px"></a>


# Using the legacy version
Starting from the version `1.0.0` the package offers more canonical client API of Pusher Channels. If you have projects powered by the old versions - consider setting the dependency in `pubspec.yaml` as following:

```yaml
dart_pusher_channels: 0.3.1+1
```

# Milestones
Starting from the version `1.1.0` the main milestones were implemented:
- Presence channels ✓
- Private encrypted channels ✓
- Triggering the client events ✓
- Tested on all the 6 platforms. ✓

Issues on this package are monitored and processed.

# Contributions

Maintainer: [Kerim Amansaryyev](https://github.com/kerimamansaryyev)

Contributors: [](https://pub.dev/packages/dart_pusher_channels#contributors)

[Sameh Doush](https://github.com/samehdoush) - Developed a test environment that boosted a release of the [Private encrypted channels feature](https://github.com/kerimamansaryyev/dart_pusher_channels/issues/22).

[Nicolas Britos](https://github.com/nicobritos) - Contributed the pull requests [#5](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/5), [#6](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/6), [#8](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/8).


# Usage

- [Options](#options)
- [Client](#client)
- [Public channels](#public-channels)
- [Private channels](#private-channels)
- [Private encrypted channels](#private-encrypted-channels)
- [Presence channels](#presence-channels)
- [Subscribing, unsubscribing and connecting](#subscribing-unsubscribing-and-connecting)
- [Binding to events](#binding-to-events)
- [Triggering events ](#triggering-events)

# Options
In order to connect to a server with Pusher Channels protocol, a client must provide some metadata as a url. Use one of the constructors of  **PusherChannelsOptions** according to your use-case.
## PusherChannelsOptions.fromCluster
Use this constructor if your url has a pattern like:`{scheme}://ws-{cluster_name}.{host}:{port}/app/{key}`. Example:

```dart
const clusterOptions = PusherChannelsOptions.fromCluster(
// usually: ws or wss
scheme: 'wss',
// your app's cluster
cluster: 'mt1',
// your app's key
key: 'a0173cd5499b34d93109',
// provide custom host if needed
host: 'pusher.com',
// decide if to send additional metadata in query parameters of the url
shouldSupplyMetadataQueries: true,
// apply custom metadata if needed
metadata: PusherChannelsOptionsMetadata.byDefault(),
port: 443,

);
// prints wss://ws-mt1.pusher.com:443/app/a0173cd5499b34d93109?client=dart&version=0.8.0&protocol=7
print(clusterOptions.uri.toString());
```

## PusherChannelsOptions.fromHost
Use this constructor if you have the Pusher Channels installed to your server under your own domain host and the url pattern looks like:`{scheme}://{host}:{port}/app/{key}`. Example:

```dart
const hostOptions = PusherChannelsOptions.fromHost(
// usually: ws or wss
scheme: 'wss',
host: 'my.domain.com',
key: 'my_key',
// decide if to send additional metadata in query parameters of the url
shouldSupplyMetadataQueries: true,
// apply custom metadata if needed
metadata: PusherChannelsOptionsMetadata.byDefault(),
port: 443,
);
// prints wss://my.domain.com:443/app/my_key?client=dart&version=0.8.0&protocol=7

print(hostOptions.uri.toString());
```

## PusherChannelsOptions.custom
Use this constructor if the others above don't fit your use-case. Example:
```dart
final customOptions = PusherChannelsOptions.custom(
// You may also apply the given metadata in your custom uri
uriResolver: (metadata) =>
Uri.parse('wss://my.custom.domain/my/custom/path'),

);
// prints wss://my.custom.domain/my/custom/path

print(customOptions.uri.toString());
```

# Client
When you've decided with the options that fit your use-case, it's time to apply them to an instance of  `PusherChannelsClient`.
## PusherChannelsClient.websocket
Using this constructor you can build a client supporting connection through the web sockets. This package depends on [web_socket_channel](https://pub.dev/packages/web_socket_channel) to support the feature. Example:
```dart
const testOptions = PusherChannelsOptions.fromCluster(
	scheme: 'wss',
	cluster: 'mt1',
	key: 'a0173cd5499b34d93109',
	host: 'pusher.com',
	shouldSupplyMetadataQueries: true,
	metadata: PusherChannelsOptionsMetadata.byDefault(),
	port: 443,
);
final client = PusherChannelsClient.websocket(
options: testOptions,
connectionErrorHandler: (exception, trace, refresh) {
// here you can handle connection errors.
// refresh callback enables to reconnect the client
refresh();
},
// [OPTIONAL]
// A delay applied when using method .reconnect between
// of these lifecycles PusherChannelsClientLifeCycleState.reconnecting,
// PusherChannelsClientLifeCycleState.pendingConnection
// Basically, the client puts delay between attempts to reconnect
minimumReconnectDelayDuration: const Duration(
seconds: 1,
),
// [OPTIONAL]
// Default timeout of the activity after which the client will ping the server.
// It is needed in case if the server does not provide one.
defaultActivityDuration: const Duration(
seconds: 120,
),
// [OPTIONAL]
// Overrides both defaultActivityDuration and the one that the server provides.
activityDurationOverride: const Duration(
seconds: 120,
),
// [OPTIONAL]
// Timeout duration that is applied while the client is waiting for the pong
// message from the server after pinging it.
waitForPongDuration: const Duration(
seconds: 30,
));
```
## Custom connection implementation
As it was mentioned above, the package supports connection through the web sockets using `## PusherChannelsClient.websocket`. You may implemet your custom `PusherChannelsConnection`. See the implementation of [`PusherChannelsWebSocketConnection`][PusherChannelsWebSocketConnection] as an example.

[PusherChannelsWebSocketConnection]: https://pub.dev/documentation/dart_pusher_channels/latest/dart_pusher_channels/PusherChannelsWebSocketConnection-class.html

And use it with `PusherChannelsClient.custom`:
```dart
final myClient = PusherChannelsClient.custom(
    // It's important to return a new instance in 
    // the delegate function because the client
    // closes (disposes) its internal instance each time
    // it connects/reconnects/disconnects.
	connectionDelegate: () => MyConnection(),
	connectionErrorHandler: ((exception, trace, refresh) {
	refresh();
 }),
);
```
# Public channels
Public channels should be used for publicly accessible data as they do not require any form of authorization in order to be subscribed to. This is how you create a public channel:
```dart
// Use an instance of PusherChannelsClient as was mentioned in the previous sections
client.publicChannel('public-MyChannel');
```
# Private channels
Private channels should be used when access to the channel needs to be restricted in some way. In order for a user to subscribe to a private channel permission must be authorized.
The authorization occurs via a HTTP Request to a configurable authorization url when the subscribe method is called with a private- channel name.

Unlike public channels, this kind of channel requires users to be authorized. So you need to provide an instance of `EndpointAuthorizableChannelAuthorizationDelegate` within creating the channel. You may consider either creating your own implementation of the delegate or using the implementation provided by this package through [http](https://pub.dev/packages/http) library - `EndpointAuthorizableChannelTokenAuthorizationDelegate`. Here is an example:
```dart
final myPrivateChannel = client.privateChannel(
'private-channel',
authorizationDelegate:
	EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
		authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
		headers: const {},
	),
);
```
# Private encrypted channels
End-to-end encrypted channels provide the same subscription restrictions as private channels.
In addition, the data field of events published to end-to-end encrypted channels is encrypted using an implementation of the Secretbox encryption standard defined in NaCl before it leaves your server.
Only authorized subscribers have access to the channel specific decryption key.
**Note**: These channels do not support triggering the client events. Ensure that a server library that you use in the back end supports the encrypted channels.
Usage example:
```dart
PrivateEncryptedChannel myEncryptedChannel = client.privateEncryptedChannel(
'private-encrypted-channel',
		// [OPTIONAL] you may want to provide your own way to
		// encode the decrypted bytes of the event's data into the plain text type of `String`
		eventDataEncodeDelegate: (bytes) => utf8.decode(bytes),
		authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate
	.forPrivateEncryptedChannel(
		authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
		headers: const {},
	),

);
```

# Presence channels
Presence channels build on the security of Private channels and expose the additional feature of an awareness of who is subscribed to that channel.This makes it extremely easy to build chat room and “who’s online” type functionality to your application.Think chat rooms, collaborators on a document, people viewing the same web page, competitors in a game, that kind of thing.

It also required an instance of `EndpointAuthorizableChannelAuthorizationDelegate` to perform the authorization process before subscribing. The example is similiar to the one in the previous section:
```dart
final myPresenceChannel = client.presenceChannel(
'presence-channel',
authorizationDelegate: 
    EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
		authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
		headers: const {},
	),
);
```
# Subscribing, unsubscribing and connecting
Here is an example of how to connect the client and to subscribe to channels.
```dart
// Organizing all channels for readibility
final allChannels = <Channel>[
	myPresenceChannel,
	myPrivateChannel,
	myPublicChannel,
];
// Highly recommended to subscribe to the channels when the clients'
// .onConnectionEstablished Stream fires an event because it enables
// to resubscribe, for example, when the client reconnects due to
// a connection error
final StreamSubscription connectionSubs =client.onConnectionEstablished.listen((_) {
	for (final channel in allChannels) {
	// Subscribes to the channel if didn't unsubscribe from it intentionally
		channel.subscribeIfNotUnsubscribed();
	}
});
// Connect with the client
client.connect();

// If you no longer need the client - cancel the connection subscription and dispose it.

// Somewhere in future
await Future.delayed(const Duration(seconds: 5));
connectionSubs.cancel();
client.dispose();
```
Using `.subscribeIfNotUnsubscribed` of `Channel` instances is recommended if you had unsubscribed from it before intentionally and you don't want to subscribe to it unexpectedly when re-establishing  connection. `.subscribe` method, on other hand, forces an instance of a channel to subscribe no matter of its current state.

## Unsubscribing from a channel
```dart
// You also will be able to subscribe again if needed
myChannel.unsubscribe();
```

# Binding to events
Unlike other SDKs, `dart_pusher_channels` offers binding to events via Dart streams, so it's recommended to create StreamSubscription for each event you want to subscribe for.
Keep in mind: those StreamSubscription instances will contintue receiving events
unless it gets canceled or while the channel is subscribed. The statement means: if you cancel an instance of StreamSubscription - events won't be received, if you unsubscribe from a channel  - the stream won't be closed but prevented from receiving events unless you subscribe to the channel again.
```dart
// In order to bind to an event, use .bind method of an instance of Channel
StreamSubscription<ChannelReadEvent> somePrivateChannelEventSubs = myPrivateChannel.bind('private-MyEvent').listen((event) {
	print('Event from the private channel fired!');
});
...
// If you want to unbind it - simply cancel the subscription
somePrivateChannelEventSubs.cancel();
```
## Using the extension shortcuts to bind
You can bind to the predefined events (especially with presence channels) by using the extension shortcut methods on instances of `Channel`:

### .whenSubscriptionSucceeded()
Binding to `pusher:subscription_succeeded`

### .whenSubscriptionCount()
Binding to `pusher:subscription_count`

### .whenMemberAdded()
Binding to `pusher:member_added`

### .whenMemberRemoved()
Binding to `pusher:member_removed`

### .onSubscriptionError({String? errorType})
Binding to `pusher:subscription_error` filtered with `errorType`.

### .onAuthenticationSubscriptionFailed()
Binding to `pusher:subscription_error` with `errorType` of `AuthError`.

## Listening for all events of a channel
```dart
StreamSubscription<ChannelReadEvent> allEventsSubs = myChannel.bindToAll().listen((event) {
	// do something	
});
```
## Listening for all events coming from a client
```dart
StreamSubscription<PusherChannelsReadEvent> allEventsSubs = client.eventStream.listen((event) {
	// do something	
});
```
# Triggering events
Private channels and presence channels support triggering the client events:
```dart
myPresenceChannel.trigger(
	eventName: 'client-event',
	data: {'hello': 'Hello'},
);
```