part of 'options.dart';

@immutable
class _CustomOptions implements PusherChannelsOptions {
  final PusherChannelsOptionsCustomUriResolver uriResolver;
  final PusherChannelsOptionsMetadata metadata;

  const _CustomOptions({
    required this.uriResolver,
    this.metadata = const PusherChannelsOptionsMetadata.byDefault(),
  });

  @override
  Uri get uri => uriResolver.call(metadata);
}
