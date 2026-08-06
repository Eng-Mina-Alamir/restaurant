/// JSON converters used by freezed/json_serializable for `DateTime` fields.
///
/// The app consumes ISO-8601 strings from the backend, but tolerates epoch
/// milliseconds (e.g. Firebase timestamps) for resilience.
library;

DateTime dateTimeFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? nullableDateTimeFromJson(Object? value) {
  if (value == null) return null;
  return dateTimeFromJson(value);
}

Object? dateTimeToJson(DateTime value) => value.toIso8601String();

Object? nullableDateTimeToJson(DateTime? value) => value?.toIso8601String();
