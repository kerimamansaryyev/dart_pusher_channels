/// Constant event names of Pusher Channels

abstract class PusherEventNames {
  static const connectionEstablished = 'pusher:connection_established';
  static const error = 'pusher:error';
  static const ping = 'pusher:ping';
  static const pong = 'pusher:pong';
  static const subscribe = 'pusher:subscribe';
  static const unsubscribe = 'pusher:unsubscribe';
  static const internalSubscriptionSucceeded =
      'pusher_internal:subscription_succeeded';
  static const subscriptionSucceeded = 'pusher:subscription_succeeded';
}
