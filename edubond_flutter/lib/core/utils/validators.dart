abstract final class Validators {
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return 'Please enter a valid Gmail address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter a password.';
    }
    if (trimmed.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? nonEmpty(String? value, String message) {
    if ((value?.trim() ?? '').isEmpty) {
      return message;
    }
    return null;
  }

  static String? httpUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a link';
    if (!trimmed.startsWith('http')) return 'Please enter a valid URL';
    return null;
  }
}
