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
            eventStreamGetter: Stream.empty,
          ),
        );
        final oldPublicChannel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        final newPublicChannel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        expect(oldPublicChannel == newPublicChannel, true);
      },
    );
    test(
      'Disposing the manager will unsubscrive the channel',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
            eventStreamGetter: Stream.empty,
          ),
        );
        final channel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        expect(channel.state?.status, null);
        manager.dispose();
        expect(channel.state?.status, ChannelStatus.unsubscribed);
      },
    );

    test(
      'Sink will stop adding events when channel is unsubscribed',
      () async {
        int eventCount = 0;
        final eventStream = Stream<PusherChannelsReadEvent>.periodic(
          const Duration(seconds: 1),
          (_) => PusherChannelsReadEvent(
            rootObject: {
              'event': 'helloEvent',
              'channel': 'hello',
            },
          ),
        );
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            triggerEventDelegate: (event) {},
            socketIdGetter: () => null,
            sendEventDelegate: (event) {},
            eventStreamGetter: () => eventStream,
          ),
        );
        final channel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        channel.bind('helloEvent').listen((event) {
          eventCount++;
        });
        await Future.delayed(
          const Duration(seconds: 3),
        );
        channel.unsubscribe();
        await Future.delayed(
          const Duration(
            seconds: 2,
          ),
        );
        await Future.microtask(
          () => expect(eventCount, 3),
        );
      },
    );
  });
}
