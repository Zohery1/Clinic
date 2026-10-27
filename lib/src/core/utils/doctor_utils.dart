/// مساعد لتنسيق أسماء وألقاب الأطباء بشكل موحد وبدون تكرار
class DoctorUtils {
  /// يقوم بتنسيق اسم الطبيب بإضافة بادئة "د." فقط إذا لم يكن الاسم يبدأ بالفعل
  /// بلقب مثل "د."، "د/"، "دكتور"، "الدكتور"، أو "Dr."
  static String formatTitle(String? name) {
    if (name == null) return '';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    // تنظيف وتوحيد البادئة لتجنب التكرار مثل "د. د. " أو الأشكال المختلفة
    final regex = RegExp(
      r'^(د\.\s*|د\/\s*|د\s+|دكتور\s+|الدكتور\s+|dr\.\s*|dr\s+)',
      caseSensitive: false,
    );

    if (regex.hasMatch(trimmed)) {
      final cleanName = trimmed.replaceFirst(regex, '').trim();
      return 'د. $cleanName';
    }

    return 'د. $trimmed';
  }
}
