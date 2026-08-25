/// Pure Dart input validators used by forms and the domain layer.
///
/// All functions accept `String?` so they can be used directly with form
/// controller values without null handling at the call site.
///
/// This is the **single source of truth** for validation rules across the app.
/// Both the UI layer (form validators) and the domain layer (use cases) must
/// delegate here instead of reimplementing ad-hoc checks.
abstract final class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _localNumberRegex = RegExp(r'^5[0-9]{8}$');

  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  static final RegExp _spaceCleanupRegex = RegExp(r'[\s\-]');

  static final RegExp _letterRegex = RegExp(r'[\p{L}]', unicode: true);

  static final RegExp _digitRegex = RegExp(r'[0-9]');

  /// Minimum password length enforced across all registration paths.
  static const int kMinPasswordLength = 8;

  /// Returns `true` if [email] is a structurally valid email address.
  static bool isValidEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.length > 254) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  /// Returns a localized error message if [email] is invalid, or `null` if OK.
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!isValidEmail(email)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
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

  /// Returns a localized error message if [phone] is invalid, or `null` if OK.
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    if (!isValidPhone(phone)) {
      return 'يرجى إدخال رقم هاتف سعودي صحيح (05xxxxxxxx)';
    }
    return null;
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

  /// Returns a localized error message if [name] is invalid, or `null` if OK.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'يرجى إدخال الاسم بالكامل';
    }
    if (!isValidName(name)) {
      return 'الاسم يجب أن يحتوي على حرف واحد على الأقل';
    }
    return null;
  }

  /// Number of strength criteria satisfied by [password], from 0 to 3:
  /// 1. Length of at least [kMinPasswordLength] characters.
  /// 2. Contains at least one letter (any script).
  /// 3. Contains at least one digit.
  ///
  /// Shared scoring helper used by [isStrongPassword], [validatePassword] and
  /// the UI password-strength indicator, so their criteria can never diverge.
  static int passwordStrengthScore(String? password) {
    if (password == null || password.isEmpty) return 0;
    var met = 0;
    if (password.length >= kMinPasswordLength) met++;
    if (_letterRegex.hasMatch(password)) met++;
    if (_digitRegex.hasMatch(password)) met++;
    return met;
  }

  /// Returns `true` when [password] meets the minimum strength bar:
  /// * At least [kMinPasswordLength] characters.
  /// * Contains at least one letter (any script).
  /// * Contains at least one digit.
  ///
  /// This is intentionally kept simple — Supabase may enforce its own server-
  /// side rules on top.
  static bool isStrongPassword(String? password) =>
      passwordStrengthScore(password) == 3;

  /// Returns a localized error message describing what's wrong with [password],
  /// or `null` when the password passes all strength checks.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (password.length < kMinPasswordLength) {
      return 'كلمة المرور يجب أن لا تقل عن $kMinPasswordLength أحرف';
    }
    if (!_letterRegex.hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حرف واحد على الأقل';
    }
    if (!_digitRegex.hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    return null;
  }
}
