/// مساعد لتنسيق أسماء وألقاب الأطباء بشكل موحد وبدون تكرار
class DoctorUtils {
  /// يقوم بتنسيق اسم الطبيب بإضافة بادئة "د." فقط إذا لم يكن الاسم يبدأ بالفعل
  /// بلقب مثل "د."، "د/"، "دكتور"، "الدكتور"، أو "Dr."
  static String formatTitle(String? name) {
    if (name == null) return '';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (trimmed.startsWith('د.') ||
        trimmed.startsWith('د/') ||
        trimmed.startsWith('د ') ||
        trimmed.startsWith('دكتور') ||
        trimmed.startsWith('الدكتور') ||
        lower.startsWith('dr.') ||
        lower.startsWith('dr ')) {
      return trimmed;
    }

    return 'د. $trimmed';
  }
}
