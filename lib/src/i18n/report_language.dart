/// Supported languages for SATE AI report generation.
enum ReportLanguage {
  /// English (default)
  en,

  /// Spanish
  es,

  /// French
  fr,

  /// German
  de,

  /// Portuguese
  pt,
}

/// Extension methods for [ReportLanguage].
extension ReportLanguageX on ReportLanguage {
  /// Standard language code (e.g. 'en', 'es').
  String get code => name;

  /// Native display name of the language.
  String get displayName {
    switch (this) {
      case ReportLanguage.en:
        return 'English';
      case ReportLanguage.es:
        return 'Español';
      case ReportLanguage.fr:
        return 'Français';
      case ReportLanguage.de:
        return 'Deutsch';
      case ReportLanguage.pt:
        return 'Português';
    }
  }

  /// Parses a string language code or enum value into a [ReportLanguage].
  static ReportLanguage parse(dynamic input) {
    if (input is ReportLanguage) return input;
    if (input is! String) return ReportLanguage.en;
    final normalized = input.trim().toLowerCase();
    switch (normalized) {
      case 'es':
      case 'spanish':
      case 'espanol':
      case 'español':
        return ReportLanguage.es;
      case 'fr':
      case 'french':
      case 'francais':
      case 'français':
        return ReportLanguage.fr;
      case 'de':
      case 'german':
      case 'deutsch':
        return ReportLanguage.de;
      case 'pt':
      case 'portuguese':
      case 'portugues':
      case 'português':
        return ReportLanguage.pt;
      case 'en':
      case 'english':
      default:
        return ReportLanguage.en;
    }
  }
}
