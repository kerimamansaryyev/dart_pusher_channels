import 'dart:async';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Testing ChannelsManager |', () {
    test(
      'Gives the same instance of channels if exists',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
          ),
        );
        final oldPublicChannel =
            manager.publicChannel('hello', forceCreateNewInstance: false);
        final newPublicChannel = manager.publicChannel(
          'hello',
          forceCreateNewInstance: false,
        );
        expect(oldPublicChannel == newPublicChannel, true);
      },
    );
    test(
      'Gives a new instance of channels if forceCreateNewInstance is set to true',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
          ),
        );
        final oldPublicChannel =
            manager.publicChannel('hello', forceCreateNewInstance: false);
        final newPublicChannel = manager.publicChannel(
          'hello',
          forceCreateNewInstance: true,
        );
        expect(oldPublicChannel != newPublicChannel, true);
      },
    );
    test(
      'Disposing the manager will unsubscribe the channel',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
          ),
        );
        final channel = manager.publicChannel(
          'hello',
          forceCreateNewInstance: false,
        );
        expect(channel.getStateTest()?.status, null);
        manager.dispose();
        expect(channel.getStateTest()?.status, ChannelStatus.unsubscribed);
      },
    );

    test(
      'Sink will stop adding events when channel is unsubscribed',
      () async {
        int eventCount = 0;
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
          ),
        );
        final subs = Stream<PusherChannelsReadEvent>.periodic(
          const Duration(seconds: 1),
          (_) => PusherChannelsReadEvent(
            rootObject: {
              'event': 'helloEvent',
              'channel': 'hello',
            },
          ),
        ).listen(manager.handleEvent);

        final channel = manager.publicChannel(
          'hello',
          forceCreateNewInstance: false,
        );
        channel.bind('helloEvent').listen((event) {
          eventCount++;
        });
        await Future.delayed(
          const Duration(seconds: 3),
        );
        channel.unsubscribe();
        print(channel.getStateTest()?.status);
        await Future.delayed(
          const Duration(
            seconds: 2,
          ),
        );
        await Future.microtask(
          () => expect(eventCount, 3),
        );
        unawaited(subs.cancel());
      },
    );
  });
}
