import 'dart:async';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/extensions/channel_extension.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:test/test.dart';

typedef _AuthChannelBuilder<T extends EndpointAuthorizationData>
    = EndpointAuthorizableChannel Function(
  ChannelsManager manager,
  _ShellAuthDelegate<T> delegate,
);

typedef _ChannelMockDelegate = Channel Function(
  ChannelsManager manager,
);
typedef _ShellAuthDelegateDataGenerator<T extends EndpointAuthorizationData> = T
    Function();

const _defaultChannelName = 'hi_channel';

_ChannelMockDelegate _channelMockDelegate = (manager) => manager.publicChannel(
      _defaultChannelName,
      forceCreateNewInstance: false,
    );

class _ShellAuthDelegate<T extends EndpointAuthorizationData>
    implements EndpointAuthorizableChannelAuthorizationDelegate<T> {
  final _ShellAuthDelegateDataGenerator<T> generator;
  @override
  final EndpointAuthFailedCallback? onAuthFailed;
  _ShellAuthDelegate({
    required this.generator,
    this.onAuthFailed,
  });

  @override
  FutureOr<T> authorizationData(String socketId, String channelName) {
    return generator();
  }
}

ChannelReadEvent _fakeSubscriptionEvent(Channel channel) =>
    ChannelReadEvent.internalCreate(
      name: Channel.getInternalSubscriptionSucceededEventNameTest(),
      channel: channel,
      data: {},
    );

ChannelReadEvent _fakeCountEvent(Channel channel) =>
    ChannelReadEvent.internalCreate(
      data: {
        Channel.subscriptionsCountKey: 3,
      },
      name: Channel.getInternalSubscriptionsCountEventName(),
      channel: channel,
    );

// Ignoring while testing
// ignore: long-method
void _testSubscriptionGroupWithMock() {
  test(
    'Subscription is succeeded when ${Channel.getInternalSubscriptionSucceededEventNameTest()} is added to ChannelsManager',
    () {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      expectLater(
        channel.whenSubscriptionSucceeded().map(
              (event) => event.name,
            ),
        emitsInOrder(
          [
            Channel.subscriptionSucceededEventName,
            emitsDone,
          ],
        ),
      );
      channel.subscribe();
      manager.handleEvent(
        _fakeSubscriptionEvent(channel),
      );
      Future.microtask(() => manager.dispose());
    },
  );
  test(
    'Status is set to ${ChannelStatus.pendingSubscription} before subscribing',
    () async {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      unawaited(
        expectLater(
          channel.whenSubscriptionSucceeded().map(
                (event) => event.name,
              ),
          emitsInOrder(
            [
              Channel.subscriptionSucceededEventName,
              emitsDone,
            ],
          ),
        ),
      );
      channel.subscribe();
      expect(channel.state?.status, ChannelStatus.pendingSubscription);
      expect(
        channel.state?.subscriptionCount,
        null,
      );
      manager.handleEvent(
        _fakeSubscriptionEvent(channel),
      );
      unawaited(
        Future.microtask(
          () => expect(channel.state?.status, ChannelStatus.subscribed),
        ),
      );
      unawaited(Future.microtask(() => manager.dispose()));
    },
  );
  test(
    'Subscription count is fired when ${Channel.getInternalSubscriptionsCountEventName()} is added to ChannelsManager',
    () async {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      unawaited(
        expectLater(
          channel.whenSubscriptionSucceeded().map(
                (event) => event.name,
              ),
          emitsInOrder(
            [
              Channel.subscriptionSucceededEventName,
              emitsDone,
            ],
          ),
        ),
      );
      if (channel is PresenceChannel) {
        unawaited(
          expectLater(
            channel.whenSubscriptionCount().map(
                  (event) =>
                      event.tryGetDataAsMap()![Channel.subscriptionsCountKey],
                ),
            emitsInOrder(
              [
                3,
                emitsDone,
              ],
            ),
          ),
        );
      }
      channel.subscribe();
      manager.handleEvent(
        _fakeSubscriptionEvent(channel),
      );
      await Future.microtask(
        () => manager.handleEvent(
          _fakeCountEvent(channel),
        ),
      );
      await Future.microtask(() => expect(channel.state?.subscriptionCount, 3));
      await Future.microtask(() => manager.dispose());
    },
  );
  test(
    'Status is set to ${ChannelStatus.idle} if any event is fired before subscription',
    () async {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      unawaited(
        expectLater(
          channel.whenSubscriptionSucceeded().map(
                (event) => event.name,
              ),
          emitsInOrder(
            [
              Channel.subscriptionSucceededEventName,
              emitsDone,
            ],
          ),
        ),
      );

      if (channel is PresenceChannel) {
        unawaited(
          expectLater(
            channel.whenSubscriptionCount().map(
                  (event) =>
                      event.tryGetDataAsMap()![Channel.subscriptionsCountKey],
                ),
            emitsInOrder(
              [
                3,
                emitsDone,
              ],
            ),
          ),
        );
      }

      await Future.microtask(
        () => manager.handleEvent(
          _fakeCountEvent(channel),
        ),
      );
      expect(
        channel.state?.status,
        ChannelStatus.idle,
      );
      expect(channel.state?.subscriptionCount, 3);
      channel.subscribe();
      await Future.microtask(
        () => manager.handleEvent(
          _fakeSubscriptionEvent(channel),
        ),
      );
      expect(
        channel.state?.status == ChannelStatus.subscribed &&
            channel.state?.subscriptionCount == 3,
        true,
      );
      await Future.microtask(() => manager.dispose());
    },
  );
  test(
    'Any unrecognized pusher_internal: event will not be accessible for binding',
    () async {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      final fakeEventName = 'pusher_internal:fake';
      unawaited(
        expectLater(
          channel.bind(fakeEventName),
          emitsDone,
        ),
      );
      unawaited(
        expectLater(
          channel.whenSubscriptionSucceeded().map(
                (event) => event.name,
              ),
          emitsInOrder(
            [
              Channel.subscriptionSucceededEventName,
              Channel.subscriptionSucceededEventName,
              emitsDone,
            ],
          ),
        ),
      );
      channel.subscribe();
      await Future.microtask(
        () => manager.handleEvent(
          _fakeSubscriptionEvent(channel),
        ),
      );
      channel.subscribe();
      await Future.microtask(
        () => manager.handleEvent(
          _fakeSubscriptionEvent(channel),
        ),
      );
      await Future.microtask(
        () => manager.handleEvent(
          ChannelReadEvent.internalCreate(
            name: fakeEventName,
            data: const <String, String>{},
            channel: channel,
          ),
        ),
      );
      unawaited(
        Future.microtask(
          () => manager.dispose(),
        ),
      );
    },
  );

  test(
    'Ignore events handled by Channel supertype if unsubscribed',
    () async {
      final manager = ChannelsManager(
        channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
          sendEventDelegate: (event) {},
          socketIdGetter: () => null,
          triggerEventDelegate: (event) {},
        ),
      );
      final channel = _channelMockDelegate(manager);
      unawaited(
        expectLater(
          channel.bindToAll(),
          emitsDone,
        ),
      );
      channel.unsubscribe();
      await Future.microtask(
        () => manager.handleEvent(
          _fakeSubscriptionEvent(channel),
        ),
      );
      await Future.microtask(
        () => manager.handleEvent(
          _fakeCountEvent(channel),
        ),
      );
      expect(
        channel.state?.status,
        ChannelStatus.unsubscribed,
      );
      unawaited(Future.microtask(() => manager.dispose()));
    },
  );
}

void _testAuthGroupThrowingErrorOnSubscription<
    T extends EndpointAuthorizationData>(
  _AuthChannelBuilder<T> authChannelBuilder,
) async {
  final manager = ChannelsManager(
    channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
      sendEventDelegate: (event) {},
      socketIdGetter: () => '123',
      triggerEventDelegate: (event) {},
    ),
  );
  final delegate = _ShellAuthDelegate(
    generator: () => throw UnimplementedError(),
    onAuthFailed: (exception, trace) => expect(
      exception,
      isA<UnimplementedError>(),
    ),
  );
  final channel = authChannelBuilder(
    manager,
    delegate,
  );
  unawaited(
    expectLater(
      channel.onAuthenticationSubscriptionFailed().map(
            (event) => event.name,
          ),
      emitsInOrder(
        [
          Channel.subscriptionErrorEventName,
          emitsDone,
        ],
      ),
    ),
  );
  await Future.microtask(
    () => channel.subscribe(),
  );
  unawaited(Future.microtask(() => manager.dispose()));
}

void main() {
  group(
      'PublicChannel general subscription/unsubscription/subscription_count |',
      () {
    _channelMockDelegate = (manager) => manager.publicChannel(
          'hello_channel',
          forceCreateNewInstance: false,
        );
    _testSubscriptionGroupWithMock();
  });
  group(
      'PrivateChannel general subscription/unsubscription/subscription_count |',
      () {
    _channelMockDelegate = (manager) => manager.privateChannel(
          'hello_channel',
          forceCreateNewInstance: false,
          authorizationDelegate:
              _ShellAuthDelegate<PrivateChannelAuthorizationData>(
            generator: () => PrivateChannelAuthorizationData(
              authKey: 'authKey',
            ),
          ),
        );
    _testSubscriptionGroupWithMock();
  });
  group(
      'PresenceChannel general subscription/unsubscription/subscription_coun |t',
      () {
    _channelMockDelegate = (manager) => manager.presenceChannel(
          'hello_channel',
          forceCreateNewInstance: false,
          authorizationDelegate:
              _ShellAuthDelegate<PresenceChannelAuthorizationData>(
            generator: () => PresenceChannelAuthorizationData(
              authKey: 'authKey',
              channelDataEncoded: '',
            ),
          ),
        );
    _testSubscriptionGroupWithMock();
  });

  group(
    'Authorization channels test |',
    () {
      test(
        'An error thrown when PrivateChannel fails to authenticate user',
        () {
          _testAuthGroupThrowingErrorOnSubscription<
              PrivateChannelAuthorizationData>(
            (manager, delegate) => manager.privateChannel(
              'hi_channel',
              authorizationDelegate: delegate,
              forceCreateNewInstance: false,
            ),
          );
        },
      );
      test(
        'An error thrown when PresenceChannel fails to authenticate user',
        () {
          _testAuthGroupThrowingErrorOnSubscription<
              PresenceChannelAuthorizationData>(
            (manager, delegate) => manager.presenceChannel(
              'hi_channel',
              authorizationDelegate: delegate,
              forceCreateNewInstance: false,
            ),
          );
        },
      );
    },
  );
}
