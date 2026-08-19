import 'package:flutter/foundation.dart';

/// أداة موحدة وذكية لاستخراج كود الدعوة من أي صيغة للرابط
class InviteUtils {
  /// استخراج كود الدعوة من كائن الـ Uri ومسار المسار Route Name
  static String? extractInviteCode({Uri? uri, String? routeName}) {
    // 1. فحص مسار الـ Route الممرر
    if (routeName != null && routeName.isNotEmpty) {
      final codeFromRoute = _extractFromQueryString(routeName);
      if (codeFromRoute != null && codeFromRoute.isNotEmpty) {
        return codeFromRoute;
      }
    }

    // 2. استخدام Uri الممرر أو Uri.base الافتراضي في الويب
    final targetUri = uri ?? (kIsWeb ? Uri.base : null);
    if (targetUri == null) return null;

    // 2.1 الفحص في QueryParameters الأساسية
    final queryCode = targetUri.queryParameters['invite'] ??
        targetUri.queryParameters['code'] ??
        targetUri.queryParameters['invite_code'];
    if (queryCode != null && queryCode.trim().isNotEmpty) {
      return queryCode.trim();
    }

    // 2.2 الفحص داخل الـ Fragment (لأن Flutter Web بالوضع الافتراضي يضع المسار بعد #)
    // مثال: https://myclinic.app/#/register?invite=ABC123
    if (targetUri.fragment.isNotEmpty) {
      final fragment = targetUri.fragment;
      final codeFromFrag = _extractFromQueryString(fragment);
      if (codeFromFrag != null && codeFromFrag.isNotEmpty) {
        return codeFromFrag;
      }

      // محاولة تحليل الـ Fragment كـ Uri كامل
      try {
        final parsedFragUri = Uri.tryParse(
          fragment.startsWith('/') ? fragment : '/$fragment',
        );
        if (parsedFragUri != null) {
          final fragQueryCode = parsedFragUri.queryParameters['invite'] ??
              parsedFragUri.queryParameters['code'] ??
              parsedFragUri.queryParameters['invite_code'];
          if (fragQueryCode != null && fragQueryCode.trim().isNotEmpty) {
            return fragQueryCode.trim();
          }
        }
      } catch (_) {}
    }

    // 2.3 الفحص عبر التعبير النمطي الشامل (Regex) في الرابط الكامل
    try {
      final fullUrl = targetUri.toString();
      final regex = RegExp(r'[?&](?:invite|code|invite_code)=([^&#\s]+)', caseSensitive: false);
      final match = regex.firstMatch(fullUrl);
      if (match != null && match.group(1) != null) {
        final val = Uri.decodeComponent(match.group(1)!);
        if (val.trim().isNotEmpty) {
          return val.trim();
        }
      }
    } catch (_) {}

    return null;
  }

  /// دالة مساعدة داخلية لاستخراج الكود من أي نص يحتوي على query string
  static String? _extractFromQueryString(String input) {
    try {
      final regex = RegExp(r'[?&](?:invite|code|invite_code)=([^&#\s]+)', caseSensitive: false);
      final match = regex.firstMatch(input);
      if (match != null && match.group(1) != null) {
        final val = Uri.decodeComponent(match.group(1)!);
        if (val.trim().isNotEmpty) {
          return val.trim();
        }
      }
    } catch (_) {}
    return null;
  }
}
