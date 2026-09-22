import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Loads template files in JSON or YAML format.
class TemplateLoader {
  /// Loads a template from a file path.
  ///
  /// Auto-detects the format by file extension:
  /// - `.yaml` or `.yml` → YAML
  /// - `.json` → JSON
  ///
  /// Throws [FormatException] if the file format is unsupported.
  /// Throws [FileSystemException] if the file does not exist.
  static Map<String, dynamic> load(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Template file not found', filePath);
    }

    final content = file.readAsStringSync();
    final lower = filePath.toLowerCase();

    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
      return _parseYaml(content);
    } else if (lower.endsWith('.json')) {
      return _parseJson(content);
    } else {
      throw FormatException(
        'Unsupported template format: $filePath. Use .yaml, .yml, or .json',
      );
    }
  }

  static Map<String, dynamic> _parseYaml(String content) {
    final yaml = loadYaml(content);
    if (yaml is! Map) {
      throw FormatException('YAML template must be an object at the top level');
    }
    return _deepConvertMap(yaml);
  }

  static Map<String, dynamic> _parseJson(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw FormatException('JSON template must be an object at the top level');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// Recursively converts YAML types to plain Dart maps/lists.
  static Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map(
      (k, v) => MapEntry(k.toString(), _deepConvert(v)),
    );
  }

  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return _deepConvertMap(value);
    } else if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }
}
