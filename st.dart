import 'dart:io';
import 'dart:convert';

const String KEY_PREFIX = 't_'; // Prefix for translation keys

void main(List<String> arguments) async {
  if (arguments.length != 1 ||
      (arguments[0] != '--modify' && arguments[0] != '--dry-run')) {
    print('Usage: dart script.dart [--modify|--dry-run]');
    exit(1);
  }

  final bool modifyFiles = arguments[0] == '--modify';

  if (modifyFiles && File('en.json').existsSync()) {
    print("Previous build file still exists");
    exit(1);
  }

  final libDir = Directory('lib');
  final translationStrings = <String, String>{};
  int filesScanned = 0;
  int filesModified = 0;

  print(
      'Starting scan ${modifyFiles ? "and modification " : ""}of the "lib" directory...');

  if (libDir.existsSync()) {
    try {
      final result = await _scanAndModifyDirectory(
          libDir, translationStrings, modifyFiles);
      filesScanned = result.filesScanned;
      filesModified = result.filesModified;
    } catch (e) {
      print('Error: $e');
      exit(1);
    }
  } else {
    print('Error: "lib" directory not found.');
    exit(1);
  }

  print('\nScan ${modifyFiles ? "and modification " : ""}completed. Results:');
  print('Total files scanned: $filesScanned');
  print(
      'Files ${modifyFiles ? "modified" : "that would be modified"}: $filesModified');
  print('Unique strings to be translated: ${translationStrings.length}');

  await _createJsonFile(translationStrings);
}

Future<void> _createJsonFile(Map<String, String> translationStrings) async {
  final jsonFile = File('en.json');
  final jsonString = JsonEncoder.withIndent('  ').convert(translationStrings);
  await jsonFile.writeAsString(jsonString);
  print('\nJSON file created: ${jsonFile.path}');
}

class ScanResult {
  final int filesScanned;
  final int filesModified;

  ScanResult(this.filesScanned, this.filesModified);
}

Future<ScanResult> _scanAndModifyDirectory(Directory dir,
    Map<String, String> translationStrings, bool modifyFiles) async {
  int filesScanned = 0;
  int filesModified = 0;

  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final result =
      await _scanAndModifyFile(entity, translationStrings, modifyFiles);
      filesScanned++;
      if (result.modified) {
        filesModified++;
      }
    } else if (entity is Directory) {
      final subResult = await _scanAndModifyDirectory(
          entity, translationStrings, modifyFiles);
      filesScanned += subResult.filesScanned;
      filesModified += subResult.filesModified;
    }
  }
  return ScanResult(filesScanned, filesModified);
}

class FileResult {
  final int stringsFound;
  final bool modified;

  FileResult(this.stringsFound, {this.modified = false});
}

Future<FileResult> _scanAndModifyFile(
    File file, Map<String, String> translationStrings, bool modifyFiles) async {
  int stringsFound = 0;
  bool modified = false;
  final regex = RegExp(
      r'''(?<![a-zA-Z0-9])(['"])((?:(?!\1|\\).|\\.)*)\1\s*\.tr\(\)''',
      multiLine: true);

  String content = await file.readAsString();
  String newContent = content;

  final matches = regex.allMatches(content);
  for (final match in matches) {
    final string = _unescapeString(match.group(2)!);
    print('Checking string: $string'); // Debug log
    if (_isValidTranslationString(string) &&
        !_isAlreadyTranslated(match.group(0)!)) {
      print('Valid translation string: $string'); // Debug log
      final key = _generateKey(string);
      translationStrings[key] = string;
      stringsFound++;

      // Replace the original string with the key
      newContent = newContent.replaceFirst(match.group(0)!, "'$key'.tr()");
      modified = true;
    } else {
      print('Invalid translation string: $string'); // Debug log
      print('isValid: ${_isValidTranslationString(string)}'); // Debug log
      print(
          'isAlreadyTranslated: ${_isAlreadyTranslated(match.group(0)!)}'); // Debug log
    }
  }

  if (modified && modifyFiles) {
    await file.writeAsString(newContent);
  }

  return FileResult(stringsFound, modified: modified);
}

bool _isValidTranslationString(String s) {
  return s.trim().isNotEmpty &&
      !s.contains(RegExp(r'^\$\{.*\}$')) &&
      !_isProbablyCodeIdentifier(s);
}

bool _isProbablyCodeIdentifier(String s) {
  // Check if the string is likely a code identifier, but allow capitalized words
  return RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$').hasMatch(s) &&
      s == s.toLowerCase();
}

bool _isAlreadyTranslated(String s) {
  // Check if the string already contains a translation key
  return s.startsWith("'${KEY_PREFIX}") && s.endsWith("'.tr()");
}

String _unescapeString(String s) {
  return s
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\r')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\"', '"')
      .replaceAll(r"\'", "'")
      .replaceAll(r'\\', '\\');
}

String _generateKey(String value) {
  // Remove any non-alphanumeric characters and trim whitespace
  String cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();

  // Split into words
  List<String> words = cleaned.split(RegExp(r'\s+'));

  List<String> keyWords = [];

  if (words.isEmpty) {
    return KEY_PREFIX + 'empty';
  } else if (words.length <= 3) {
    // For strings with 1 to 3 words, use all words
    keyWords = words;
  } else {
    // For strings with four or more words, use first two and last two words
    keyWords = [
      words[0],
      words[1],
      words[words.length - 2],
      words[words.length - 1]
    ];
  }

  // Convert to camelCase
  String key = keyWords.first.toLowerCase() +
      keyWords.skip(1).map((word) => word.capitalize()).join('');

  // Truncate if too long
  if (key.length > 30) {
    key = key.substring(0, 30);
  }

  return KEY_PREFIX + key;
}

// Helper extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
