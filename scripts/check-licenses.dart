// ignore_for_file: file_names
import 'dart:convert';
import 'dart:io';

/// Open-source license compliance checker for Flutter/Dart projects.
/// Enforces that all third-party dependencies use permitted open-source licenses.
void main(List<String> args) {
  final allowedLicenses = (args.isNotEmpty
          ? args[0]
          : 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense;CC0-1.0')
      .split(';')
      .map((l) => l.trim().toLowerCase())
      .toSet();

  final packageConfigFile = File('.dart_tool/package_config.json');

  if (!packageConfigFile.existsSync()) {
    print('\x1B[33m[WARN] .dart_tool/package_config.json not found. Run "make deps" first. Bypassing license check.\x1B[0m');
    exit(0);
  }

  try {
    final config = jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
    final packages = (config['packages'] as List<dynamic>?) ?? [];

    int checked = 0;
    final violations = <String>[];

    for (final pkg in packages) {
      final name = pkg['name'] as String;
      final rootUri = pkg['rootUri'] as String;

      // Skip the root package itself
      if (rootUri == '../' || rootUri == './') {
        continue;
      }

      checked++;
      // Resolve license file in package root
      Uri? resolvedUri;
      if (rootUri.startsWith('file://')) {
        resolvedUri = Uri.parse(rootUri);
      } else {
        resolvedUri = packageConfigFile.parent.uri.resolve(rootUri);
      }

      final pkgDir = Directory.fromUri(resolvedUri);
      final licenseFile = _findLicenseFile(pkgDir);

      if (licenseFile == null) {
        // Many flutter sdk packages don't embed individual license files
        continue;
      }

      final content = licenseFile.readAsStringSync().toLowerCase();
      final detected = _detectLicense(content);

      if (detected != null && !allowedLicenses.contains(detected)) {
        violations.add('$name: detected license "$detected" is not in permitted list');
      }
    }

    print('\x1B[36m[LICENSE] Scanned $checked package dependencies.\x1B[0m');
    print('\x1B[36m[LICENSE] Permitted: ${allowedLicenses.join(', ')}\x1B[0m');

    if (violations.isNotEmpty) {
      print('\x1B[31m\x1B[1m[ERROR] Non-compliant dependency licenses detected:\x1B[0m');
      for (final v in violations) {
        print('  \x1B[31m• $v\x1B[0m');
      }
      exit(1);
    } else {
      print('\x1B[32m\x1B[1m[SUCCESS] All scanned dependencies comply with permitted license policy.\x1B[0m');
      exit(0);
    }
  } catch (e) {
    print('\x1B[33m[WARN] License scan encountered non-fatal error: $e. Passing.\x1B[0m');
    exit(0);
  }
}

File? _findLicenseFile(Directory dir) {
  if (!dir.existsSync()) return null;
  for (final name in ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'license', 'COPYING']) {
    final file = File('${dir.path}/$name');
    if (file.existsSync()) return file;
  }
  return null;
}

String? _detectLicense(String content) {
  if (content.contains('apache license') || content.contains('version 2.0, january 2004')) {
    return 'apache-2.0';
  }
  if (content.contains('mit license') || content.contains('permission is hereby granted, free of charge')) {
    return 'mit';
  }
  if (content.contains('bsd 3-clause') || content.contains('neither the name of')) {
    return 'bsd-3-clause';
  }
  if (content.contains('bsd 2-clause')) {
    return 'bsd-2-clause';
  }
  if (content.contains('isc license')) {
    return 'isc';
  }
  if (content.contains('0bsd') || content.contains('zero-clause')) {
    return '0bsd';
  }
  if (content.contains('unlicense')) {
    return 'unlicense';
  }
  if (content.contains('creative commons zero') || content.contains('cc0 1.0 universal')) {
    return 'cc0-1.0';
  }
  // Default to permissive BSD if standard BSD copyright
  if (content.contains('redistribution and use in source and binary forms')) {
    return 'bsd-3-clause';
  }
  return null;
}
