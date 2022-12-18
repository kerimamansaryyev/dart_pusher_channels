import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

void connectToPusher() async {
  // Enable or disable logs
  PusherChannelsPackageLogger.enableLogs();
  // Create an instance PusherChannelsOptions
  // The test options can be accessed from test.pusher.com (using only for test purposes)
  const testOptions = PusherChannelsOptions.fromCluster(
    scheme: 'wss',
    cluster: 'mt1',
    key: 'a0173cd5499b34d93109',
    port: 443,
  );
  // Create an instance of PusherChannelsClient
  final client = PusherChannelsClient.websocket(
    options: testOptions,
    // Connection exceptions are handled here
    connectionErrorHandler: (exception, trace, refresh) async {
      // This method allows you to reconnect if any error is occurred.
      refresh();
    },
  );

  // Create instances of Channel
  PresenceChannel myPresenceChannel = client.presenceChannel(
    'presence-channel',
    // Private and Presence channels require users to be authorized.
    // Use EndpointAuthorizableChannelTokenAuthorizationDelegate to authorize through
    // an http endpoint or create your own delegate by implementing EndpointAuthorizableChannelAuthorizationDelegate
    authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate
        .forPresenceChannel(
      authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
      headers: const {},
    ),
  );
  PrivateChannel myPrivateChannel = client.privateChannel(
    'private-channel',
    authorizationDelegate:
        EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
      authorizationEndpoint: Uri.parse('https://test.pusher.com/pusher/auth'),
      headers: const {},
    ),
  );
  PublicChannel myPublicChannel = client.publicChannel(
    'public-channel',
  );

  // Unlike other SDKs, dart_pusher_channels offers binding to events
  // via Dart streams, so it's recommended to create StreamSubscription for
  // each event you want to subscribe for.

  // Keep in mind: those StreamSubscription instances will contintue receiving events
  // unless it gets canceled or channel gets unsubscribed.
  // Following statement means: if you cancel an instance of StreamSubscription - it stops
  // receiving events unless you bind to it to an event (with .listen method of the .bind stream) again,
  // if you will unsubscribe from channel and if then you will subscribe to it again -
  // an instance of StreamSubscription will continue receiving events.

  // Listen for events of the channel with .bind method
  StreamSubscription<ChannelReadEvent> somePrivateChannelEventSubs =
      myPrivateChannel.bind('private-MyEvent').listen((event) {
    print('Event from the private channel fired!');
  });
  StreamSubscription<ChannelReadEvent> somePublicChannelEventSubs =
      myPublicChannel.bind('public-MyEvent').listen((event) {
    print('Event from the public channel fired!');
  });

  // You may use some helpful extension shortcut methods for the predefined channel events.
  // For example, this one binds to events of the channel with name 'pusher:member_added'
  StreamSubscription<ChannelReadEvent> presenceMembersAddedSubs =
      myPresenceChannel.whenMemberAdded().listen((event) {
    print(
      'Member added, now members count is ${myPresenceChannel.state?.members?.membersCount}',
    );
  });

  // Organizing all subscriptions into 1 for readability
  final allEventSubs = <StreamSubscription?>[
    presenceMembersAddedSubs,
    somePrivateChannelEventSubs,
    somePublicChannelEventSubs,
  ];
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
  final connectionSubs = client.onConnectionEstablished.listen((_) async {
    for (final channel in allChannels) {
      // Subscribes to the channel if didn't unsubscribe from it intentionally
      channel.subscribeIfNotUnsubscribed();
    }
  });

  // Connect with the client
  unawaited(client.connect());

  // If you no longer need a channel - unsubscribe from it. Channel instances are reusable
  // so it is possible to subscribe to it later, if needed, using .subscribe method.

  // Somewhere in future
  await Future.delayed(const Duration(seconds: 5));
  myPresenceChannel.unsubscribe();
  // Somewhere in future
  await Future.delayed(const Duration(seconds: 5));
  myPresenceChannel.subscribe();

  // If you want to unbind from the event - simply cancel an event subscription.
  // Somewhere in future
  await Future.delayed(const Duration(seconds: 5));
  await presenceMembersAddedSubs.cancel();

  // If you no longer need the client - cancel the connection subscription and dispose it.

  // Somewhere in future
  await Future.delayed(const Duration(seconds: 5));
  await connectionSubs.cancel();
  // Consider canceling the event subscriptions to
  for (final subscription in allEventSubs) {
    subscription?.cancel();
  }
}
