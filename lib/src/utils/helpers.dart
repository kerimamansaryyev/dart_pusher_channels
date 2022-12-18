import 'dart:convert';

/// Takes the [message] of any type and tries to deserialize it.
///
/// If the [message] is Map - the [leaveOnlyStringKeys] function will remove all non-[String] keys.
///
/// Will decode [message] with the [jsonDecode] if that is [String].
///
/// In all other cases, if the result is not Map - returns null.
Map<String, dynamic>? safeMessageToMapDeserializer(dynamic message) {
  if (message is Map) {
    return leaveOnlyStringKeys(message);
  } else if (message is String) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map) {
        return leaveOnlyStringKeys(decoded);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Removes all non-[String] keys of the [other].
Map<String, dynamic> leaveOnlyStringKeys(Map other) {
  final copy = {...other}..removeWhere((key, value) => key is! String);
  return {...copy};
}

/// Used as a shell delegate for mapping events of an instance of [Stream]
void voidStreamMapper(_) {
  return;
}
