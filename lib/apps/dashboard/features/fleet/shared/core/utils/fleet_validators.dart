class FleetValidators {
  /// Rewrites Arabic-Indic (`٠..٩`) and Extended Arabic-Indic (`۰..۹`) digits as
  /// ASCII.
  ///
  /// Dart's `\d` and `FilteringTextInputFormatter.digitsOnly` are both ASCII-only,
  /// so a number typed the way it is printed on an Egyptian number plate is not a
  /// number as far as any of them are concerned. Every numeric field in the fleet
  /// forms except the plate is ASCII by construction (a `digitsOnly` formatter
  /// strips anything else as it is typed); the plate is free text because a plate
  /// is not a number, and it is the one place the difference is load-bearing.
  static String normalizeDigits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30); 
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30); 
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'الاسم الكامل مطلوب';
    final trimmed = value.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 2) return 'يرجى إدخال الاسم ثنائياً على الأقل';
    return null;
  }

  static String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرقم القومي مطلوب';
    final trimmed = value.trim();
    if (trimmed.length != 14 || !RegExp(r'^\d{14}$').hasMatch(trimmed)) {
      return 'الرقم القومي يجب أن يتكون من 14 رقماً فقط';
    }
    return null;
  }

  static String? validatePhone(String value, String fieldLabel) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$fieldLabel مطلوب';
    if (trimmed.length != 11 || !RegExp(r'^\d{11}$').hasMatch(trimmed)) {
      return '$fieldLabel يجب أن يتكون من 11 رقماً';
    }
    if (!RegExp(r'^(010|011|012|015)').hasMatch(trimmed)) {
      return '$fieldLabel يجب أن يبدأ برقم هاتف مصري صحيح (010, 011, 012, 015)';
    }
    return null;
  }

  static String? validateDate(String value, String fieldLabel) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$fieldLabel مطلوب';
    final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegExp.hasMatch(trimmed)) {
      return '$fieldLabel يجب أن يكون بالتنسيق YYYY-MM-DD (مثال: 2026-06-18)';
    }
    final date = DateTime.tryParse(trimmed);
    if (date == null) {
      return 'التاريخ المدخل غير صحيح';
    }
    return null;
  }

  static String? validateEmployeeCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'كود الموظف مطلوب';
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'كود الموظف يجب أن يتكون من 3 رموز على الأقل';
    }
    return null;
  }

  static String? validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الرخصة مطلوب';
    final trimmed = value.trim();
    if (trimmed.length < 4) return 'رقم الرخصة قصير جداً';
    return null;
  }

  static String? validateVehicleCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'كود المركبة مطلوب';
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'كود المركبة يجب أن يتكون من 3 رموز على الأقل';
    }
    return null;
  }

  /// An Egyptian plate is digits plus letters, in either script.
  ///
  /// This used to reject `٣٣٠٠ ق ل` — a plate transcribed exactly as it appears on
  /// the vehicle — on two counts at once: `\d` matches only ASCII digits, and the
  /// "letters" class `[\u0600-\u06FF]` *contains* the Arabic-Indic digits, so
  /// `٣٣٠٠` read as four letters and no digits at all. In an Arabic-first
  /// dashboard that made a whole class of real plate numbers unsaveable, and with
  /// them the vehicle's seat layout, driver assignment and documents.
  static String? validatePlateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم اللوحة مطلوب';
    final trimmed = normalizeDigits(value.trim());
    final hasDigits = RegExp(r'[0-9]').hasMatch(trimmed);
    
    final hasLetters = RegExp(
      r'[a-zA-Z\u0621-\u063A\u0641-\u064A\u0671-\u06D3]',
    ).hasMatch(trimmed);
    if (!hasDigits || !hasLetters) {
      return 'رقم اللوحة يجب أن يحتوي على أرقام وحروف معاً (مثال: 123 أ ب ج)';
    }
    return null;
  }

  static String? validateManufactureYear(String? value) {
    if (value == null || value.trim().isEmpty) return 'سنة الصنع مطلوبة';
    final trimmed = value.trim();
    final year = int.tryParse(trimmed);
    if (year == null) return 'سنة الصنع يجب أن تكون رقماً صحيحاً';
    final currentYear = DateTime.now().year;
    if (year < 1990 || year > currentYear + 1) {
      return 'سنة الصنع يجب أن تكون بين 1990 و ${currentYear + 1}';
    }
    return null;
  }

  static String? validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) return 'السعة الركابية مطلوبة';
    final trimmed = value.trim();
    final capacity = int.tryParse(trimmed);
    if (capacity == null) return 'السعة الركابية يجب أن تكون رقماً صحيحاً';
    if (capacity < 2 || capacity > 100) {
      return 'السعة الركابية يجب أن تكون بين 2 و 100 مقعد';
    }
    return null;
  }
}
