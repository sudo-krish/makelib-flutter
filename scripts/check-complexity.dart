// ignore_for_file: file_names
import 'dart:io';

/// Standalone Cyclomatic Complexity Checker for Dart/Flutter projects.
/// Enforces McCabe cyclomatic complexity <= 10 per method/function.
void main(List<String> args) {
  final targetDir = Directory(args.isNotEmpty ? args[0] : 'lib');
  final maxComplexity = args.length > 1 ? int.parse(args[1]) : 10;

  if (!targetDir.existsSync()) {
    print('\x1B[33m[WARN] Target directory does not exist: ${targetDir.path}\x1B[0m');
    exit(0);
  }

  final dartFiles = targetDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart') && !f.path.contains('.freezed.dart'))
      .toList();

  int totalFunctionsChecked = 0;
  final violations = <String>[];

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    final fileResults = analyzeFile(file.path, lines, maxComplexity);
    totalFunctionsChecked += fileResults.totalFunctions;
    violations.addAll(fileResults.violations);
  }

  print('\x1B[36m[SMELL] Evaluated $totalFunctionsChecked functions across ${dartFiles.length} files.\x1B[0m');
  print('\x1B[36m[SMELL] Cyclomatic complexity threshold: <= $maxComplexity\x1B[0m');

  if (violations.isNotEmpty) {
    print('\x1B[31m\x1B[1m[ERROR] Complexity threshold exceeded in ${violations.length} function(s):\x1B[0m');
    for (final v in violations) {
      print('  \x1B[31m• $v\x1B[0m');
    }
    exit(1);
  } else {
    print('\x1B[32m\x1B[1m[SUCCESS] All functions satisfy cyclomatic complexity <= $maxComplexity.\x1B[0m');
    exit(0);
  }
}

class FileAnalysisResult {
  final int totalFunctions;
  final List<String> violations;
  FileAnalysisResult(this.totalFunctions, this.violations);
}

FileAnalysisResult analyzeFile(String filePath, List<String> lines, int maxComplexity) {
  int totalFunctions = 0;
  final violations = <String>[];

  // Regex pattern identifying function/method signatures
  final fnSignatureRegex = RegExp(r'^\s*(?:@\w+\s+)*(?:(?:static|final|const|async|void|[A-Za-z0-9_<>?]+)\s+)+([A-Za-z0-9_]+)\s*\([^)]*\)\s*(?:async\*?|\s*)=?>?\s*\{?');

  int currentComplexity = 0;
  String? currentFunctionName;
  int currentFunctionStartLine = 0;
  int braceDepth = 0;
  bool inFunction = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Skip comment lines
    if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
      continue;
    }

    // Detect function start
    if (!inFunction) {
      final match = fnSignatureRegex.firstMatch(line);
      if (match != null && !trimmed.startsWith('class ') && !trimmed.startsWith('enum ') && !trimmed.startsWith('abstract ')) {
        currentFunctionName = match.group(1);
        currentFunctionStartLine = i + 1;
        currentComplexity = 1; // Base complexity
        inFunction = true;
        braceDepth = 0;
      }
    }

    if (inFunction) {
      // Track brace depth
      final openBraces = '{'.allMatches(line).length;
      final closeBraces = '}'.allMatches(line).length;
      braceDepth += (openBraces - closeBraces);

      // Increment complexity for branching constructs
      currentComplexity += RegExp(r'\bif\b').allMatches(line).length;
      currentComplexity += RegExp(r'\bfor\b').allMatches(line).length;
      currentComplexity += RegExp(r'\bwhile\b').allMatches(line).length;
      currentComplexity += RegExp(r'\bcase\b').allMatches(line).length;
      currentComplexity += RegExp(r'\bcatch\b').allMatches(line).length;
      currentComplexity += RegExp(r'\?\?').allMatches(line).length;
      currentComplexity += RegExp(r'&&').allMatches(line).length;
      currentComplexity += RegExp(r'\|\|').allMatches(line).length;
      currentComplexity += RegExp(r'\?[^:]+:').allMatches(line).length; // ternary

      // End of function detected
      if (braceDepth <= 0 && (openBraces > 0 || trimmed.endsWith(';') || trimmed.endsWith('}'))) {
        totalFunctions++;
        if (currentComplexity > maxComplexity) {
          violations.add('$filePath:$currentFunctionStartLine ($currentFunctionName) has complexity $currentComplexity > $maxComplexity');
        }
        inFunction = false;
        currentFunctionName = null;
        currentComplexity = 0;
      }
    }
  }

  return FileAnalysisResult(totalFunctions, violations);
}
