class ArabicUtils {
  /// Normalizes Arabic text for flexible matching:
  /// - Normalizes hamzas (أ, إ, آ -> ا)
  /// - Normalizes taa marbouta (ة -> ه)
  /// - Normalizes alif maqsura (ى -> ي)
  /// - Removes tashkeel & tatweel
  /// - Removes extra whitespace
  static String normalize(String text) {
    if (text.isEmpty) return text;
    var normalized = text.trim();

    // Remove Arabic tashkeel (diacritics)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    // Remove Tatweel (ـ)
    normalized = normalized.replaceAll('\u0640', '');

    // Normalize Alifs
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Normalize Taa Marbouta
    normalized = normalized.replaceAll('ة', 'ه');
    // Normalize Alif Maqsura
    normalized = normalized.replaceAll('ى', 'ي');

    return normalized;
  }

  /// Extracts tokens (words) without 'ال' prefix for fuzzy similarity matching
  static Set<String> getTokens(String name) {
    final norm = normalize(name);
    final words = norm.split(RegExp(r'\s+')).where((w) => w.length >= 2);
    final tokens = <String>{};
    for (var w in words) {
      tokens.add(w);
      if (w.startsWith('ال') && w.length >= 4) {
        tokens.add(w.substring(2));
      }
    }
    return tokens;
  }

  /// Calculates word token similarity percentage (0.0 to 1.0)
  static double tokenSimilarity(String name1, String name2) {
    final tokens1 = getTokens(name1);
    final tokens2 = getTokens(name2);
    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    int intersectionCount = 0;
    for (var t1 in tokens1) {
      for (var t2 in tokens2) {
        if (t1 == t2 || (t1.length >= 3 && t2.length >= 3 && (t1.contains(t2) || t2.contains(t1)))) {
          intersectionCount++;
          break;
        }
      }
    }

    return (intersectionCount * 2.0) / (tokens1.length + tokens2.length);
  }
}
