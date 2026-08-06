/// Pure Dart input validators used by forms and the domain layer.
///
/// All functions accept `String?` so they can be used directly with form
/// controller values without null handling at the call site.
abstract final class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _localNumberRegex = RegExp(r'^5[0-9]{8}$');

  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  static final RegExp _spaceCleanupRegex = RegExp(r'[\s\-]');

  static final RegExp _letterRegex = RegExp(r'[\p{L}]', unicode: true);

  /// Returns `true` if [email] is a structurally valid email address.
  static bool isValidEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.length > 254) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  /// Returns `true` if [phone] is a valid Saudi mobile number.
  ///
  /// Accepts the following formats:
  /// - `05xxxxxxxx` (national)
  /// - `+9665xxxxxxxx` (international)
  /// - `009665xxxxxxxx` (international with trunk prefix)
  static bool isValidPhone(String? phone) {
    if (phone == null) return false;
    final cleaned = phone.trim().replaceAll(_spaceCleanupRegex, '');
    if (cleaned.isEmpty) return false;

    if (cleaned.startsWith('+966')) {
      return _localNumberRegex.hasMatch(cleaned.substring(4));
    }
    if (cleaned.startsWith('00966')) {
      return _localNumberRegex.hasMatch(cleaned.substring(5));
    }
    if (cleaned.startsWith('05')) {
      return _localNumberRegex.hasMatch(cleaned.substring(1));
    }
    return false;
  }

  /// Returns `true` if [otp] is exactly six digits.
  static bool isValidOtp(String? otp) {
    if (otp == null) return false;
    return _otpRegex.hasMatch(otp.trim());
  }

  /// Returns `true` if [name] is a plausible person/restaurant name:
  /// non-empty, not too long and contains at least one letter.
  static bool isValidName(String? name) {
    if (name == null) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) return false;
    return _letterRegex.hasMatch(trimmed);
  }
}
