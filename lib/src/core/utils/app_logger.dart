import 'package:flutter/foundation.dart';

/// نظام إدارة السجلات واللوجات المحمي للتطبيق
class AppLogger {
  /// طباعة معلومات عادية (في بيئة التطوير فقط)
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }

  /// طباعة تحذير (في بيئة التطوير فقط)
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ $message');
    }
  }

  /// طباعة خطأ (في جميع البيئات بخلاصة غير ضخمة)
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      print('❌ $message ${error != null ? '-> $error' : ''}');
    }
  }

  /// إخفاء أرقام الهواتف لحماية بيانات المرضى والخصوصية
  static String maskPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '****';
    final clean = phone.trim();
    if (clean.length < 8) return '****';
    return '${clean.substring(0, 4)}****${clean.substring(clean.length - 3)}';
  }
}
