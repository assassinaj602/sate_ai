import 'dart:io';

import 'package:test/test.dart';
import 'package:sate_core/sate_core.dart';

void main() {
  group('ReportLanguage', () {
    test('parses language strings correctly', () {
      expect(ReportLanguageX.parse('en'), equals(ReportLanguage.en));
      expect(ReportLanguageX.parse('english'), equals(ReportLanguage.en));
      expect(ReportLanguageX.parse('es'), equals(ReportLanguage.es));
      expect(ReportLanguageX.parse('Spanish'), equals(ReportLanguage.es));
      expect(ReportLanguageX.parse('fr'), equals(ReportLanguage.fr));
      expect(ReportLanguageX.parse('French'), equals(ReportLanguage.fr));
      expect(ReportLanguageX.parse('de'), equals(ReportLanguage.de));
      expect(ReportLanguageX.parse('German'), equals(ReportLanguage.de));
      expect(ReportLanguageX.parse('pt'), equals(ReportLanguage.pt));
      expect(ReportLanguageX.parse('Portuguese'), equals(ReportLanguage.pt));
    });

    test('defaults to English for unknown languages', () {
      expect(ReportLanguageX.parse('unknown'), equals(ReportLanguage.en));
      expect(ReportLanguageX.parse(null), equals(ReportLanguage.en));
      expect(ReportLanguageX.parse(123), equals(ReportLanguage.en));
    });

    test('returns native display names', () {
      expect(ReportLanguage.en.displayName, equals('English'));
      expect(ReportLanguage.es.displayName, equals('Español'));
      expect(ReportLanguage.fr.displayName, equals('Français'));
      expect(ReportLanguage.de.displayName, equals('Deutsch'));
      expect(ReportLanguage.pt.displayName, equals('Português'));
    });
  });

  group('I18n Translations', () {
    test('provides translations for all supported languages', () {
      for (final lang in ReportLanguage.values) {
        expect(I18n.text('reportTitle', language: lang), isNotEmpty);
        expect(I18n.text('summary', language: lang), isNotEmpty);
        expect(I18n.text('testResults', language: lang), isNotEmpty);
      }
    });

    test('verifies specific translation strings', () {
      expect(
        I18n.text('summary', language: ReportLanguage.es),
        equals('Resumen'),
      );
      expect(
        I18n.text('summary', language: ReportLanguage.fr),
        equals('Résumé'),
      );
      expect(
        I18n.text('summary', language: ReportLanguage.de),
        equals('Zusammenfassung'),
      );
      expect(
        I18n.text('summary', language: ReportLanguage.pt),
        equals('Resumo'),
      );
    });
  });

  group('Localized Reports', () {
    late StressReport report;

    setUp(() {
      report = StressReport(
        modelId: 'test-i18n-model',
        passed: true,
        results: [
          const FaultResult(
            injectorType: FaultType.memoryPressure,
            passed: true,
            inferenceTime: Duration(milliseconds: 150),
            memoryUsageMB: 120.0,
          ),
          const FaultResult(
            injectorType: FaultType.malformedInput,
            passed: false,
            errorMessage: 'Syntax error',
          ),
        ],
        failures: [],
        startTime: DateTime.parse('2026-10-02T10:00:00Z'),
        endTime: DateTime.parse('2026-10-02T10:00:02Z'),
        totalDuration: const Duration(seconds: 2),
      );
    });

    test('generates Spanish Markdown report', () {
      final md = report.toMarkdownLocalized('es');
      expect(md, contains('Informe de Prueba de Esfuerzo SATE AI'));
      expect(md, contains('Resumen'));
      expect(md, contains('Resultados de las Pruebas'));
      expect(md, contains('Modelo'));
      expect(md, contains('Pruebas totales'));
    });

    test('generates French Markdown report', () {
      final md = report.toMarkdownLocalized(ReportLanguage.fr);
      expect(md, contains('Rapport de Test de Stress SATE AI'));
      expect(md, contains('Résumé'));
      expect(md, contains('Résultats des Tests'));
      expect(md, contains('Modèle'));
    });

    test('generates German Markdown report', () {
      final md = report.toMarkdownLocalized('de');
      expect(md, contains('SATE AI Stresstest-Bericht'));
      expect(md, contains('Zusammenfassung'));
      expect(md, contains('Testergebnisse'));
      expect(md, contains('Modell'));
    });

    test('generates Portuguese Markdown report', () {
      final md = report.toMarkdownLocalized('pt');
      expect(md, contains('Relatório de Teste de Estresse SATE AI'));
      expect(md, contains('Resumo'));
      expect(md, contains('Resultados dos Testes'));
      expect(md, contains('Modelo'));
    });

    test('generates Spanish HTML report', () {
      final html = report.toHtmlLocalized('es');
      expect(html, contains('<html lang="es">'));
      expect(html, contains('Informe de Prueba de Esfuerzo SATE AI'));
      expect(html, contains('Resultados de las Pruebas'));
    });

    test('writes localized HTML to file', () async {
      final tempDir = await Directory.systemTemp.createTemp('sate_i18n_test');
      final htmlFile = File('${tempDir.path}/report_es.html');

      try {
        await report.writeHtmlToFileLocalized(htmlFile.path, 'es');
        expect(htmlFile.existsSync(), isTrue);
        final content = await htmlFile.readAsString();
        expect(content, contains('Informe de Prueba de Esfuerzo SATE AI'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('FaultResult.toMarkdownLocalized formats localized result section',
        () {
      const result = FaultResult(
        injectorType: FaultType.memoryPressure,
        passed: true,
        inferenceTime: Duration(milliseconds: 100),
        memoryUsageMB: 50.0,
      );

      final esMd = result.toMarkdownLocalized('es');
      expect(esMd, contains('Tiempo de inferencia'));
      expect(esMd, contains('Uso de memoria'));

      final deMd = result.toMarkdownLocalized('de');
      expect(deMd, contains('Inferenzzeit'));
      expect(deMd, contains('Speichernutzung'));
    });
  });
}
