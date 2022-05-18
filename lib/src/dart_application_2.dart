import 'options.dart';
import 'pusher.dart';

void main() async {
  var pusher = Pusher.websocket(
      onConnectionErrorHandle: (error, trace) {
        print(error);
      },
      options: PusherOptions.ws(
          port: null,
          key: 'asmanKbdgI',
          protocol: 7,
          version: '7.0.3',
          host: 'amm-ws.asmantiz.com'));
  await pusher.connect();
  var c = pusher.publicChannel('hello');
  c.subscribe();
  await Future.delayed(const Duration(seconds: 2));
  c.unsubscribe();
}
