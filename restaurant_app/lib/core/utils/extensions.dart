import 'formatters.dart';

/// Convenience extension for nullable strings.
extension StringNullableExtensions on String? {
  /// Returns this string or an empty string when null.
  ///
  /// Example: `user.name.orEmpty()` → `''` when `name` is null.
  String orEmpty() => this ?? '';

  /// Returns `true` when the string is null or blank after trimming.
  bool get isNullOrBlank {
    final value = this;
    return value == null || value.trim().isEmpty;
  }
}

/// Convenience extensions for [DateTime].
extension DateTimeArabicExtensions on DateTime {
  /// Formats this date with an Arabic locale (e.g. `6 أغسطس 2026`).
  String toArabicString() => Formatters.formatDate(this);

  /// Formats this date and time with an Arabic locale.
  String toArabicDateTimeString() => Formatters.formatDateTime(this);
}

/// Convenience extensions for numeric values.
extension NumCurrencyExtensions on num {
  /// Formats this number as an Arabic currency string (e.g. `50.00 ر.س`).
  String toArabicCurrency() => Formatters.formatCurrency(toDouble());
}

/// Separator helper for building comma-separated / joined widget lists.
extension SeparatedListExtension<T> on List<T> {
  /// Returns a new list where [separator] is inserted between every pair of
  /// elements. Returns an unmodified list when empty.
  ///
  /// Example: `[1, 2, 3].separatedBy(0)` → `[1, 0, 2, 0, 3]`.
  List<T> separatedBy(T separator) {
    if (isEmpty) return this;
    return <T>[
      for (var i = 0; i < length; i++) ...<T>[
        this[i],
        if (i != length - 1) separator,
      ],
    ];
  }
}
