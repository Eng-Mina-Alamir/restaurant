/// Convenience extension for nullable strings.
extension StringNullableExtensions on String? {
  /// Returns this string or an empty string when null.
  ///
  /// Example: `user.name.orEmpty()` → `''` when `name` is null.
  String orEmpty() => this ?? '';
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
