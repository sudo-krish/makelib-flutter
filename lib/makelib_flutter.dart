/// makelib_flutter — Centralized GNU Make Library and Toolchain for Flutter/Dart.
library makelib_flutter;

/// Library metadata and version configuration.
class MakelibFlutter {
  /// The current semantic version of the makelib library.
  static const String version = '1.0.0+1';

  /// Standard permitted open source software licenses.
  static const List<String> permittedLicenses = <String>[
    'MIT',
    'Apache-2.0',
    'BSD-2-Clause',
    'BSD-3-Clause',
    'ISC',
    '0BSD',
    'Unlicense',
    'CC0-1.0',
  ];

  /// Standard shift-left branch naming regex pattern.
  static const String branchNamingRegex =
      r'^(feat|feature|fix|patch|major|breaking|docs|chore|refactor|ci)/[a-z0-9._-]+$';

  /// Default line coverage threshold requirement (in percent).
  static const double defaultMinCoverage = 80.0;

  /// Validates whether a given Git branch name satisfies the shift-left policy.
  static bool isValidBranchName(String branchName) {
    if (branchName == 'main' || branchName == 'master' || branchName.isEmpty) {
      return false;
    }
    final RegExp regex = RegExp(branchNamingRegex);
    return regex.hasMatch(branchName);
  }

  /// Classifies a branch name into its corresponding SemVer release level.
  static String classifyBranch(String branchName) {
    if (branchName.startsWith('major/') || branchName.startsWith('breaking/')) {
      return 'major';
    }
    if (branchName.startsWith('feat/') || branchName.startsWith('feature/')) {
      return 'minor';
    }
    return 'patch';
  }

  /// Validates if an open-source license is within the approved whitelist.
  static bool isPermittedLicense(String license) {
    final String normalized = license.trim().toLowerCase();
    for (final String permitted in permittedLicenses) {
      if (permitted.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  /// Calculates next SemVer version string given current version and bump level.
  static String computeNextVersion(String currentVersion, String bumpLevel) {
    final bool hasBuild = currentVersion.contains('+');
    final String semver =
        hasBuild ? currentVersion.split('+')[0] : currentVersion;
    final int? buildNum =
        hasBuild ? int.tryParse(currentVersion.split('+')[1]) : null;

    final List<String> parts = semver.split('.');
    if (parts.length != 3) {
      throw ArgumentError('Invalid SemVer format: $currentVersion');
    }

    int major = int.parse(parts[0]);
    int minor = int.parse(parts[1]);
    int patch = int.parse(parts[2]);

    switch (bumpLevel.toLowerCase()) {
      case 'major':
        major += 1;
        minor = 0;
        patch = 0;
        break;
      case 'minor':
        minor += 1;
        patch = 0;
        break;
      case 'patch':
        patch += 1;
        break;
      default:
        throw ArgumentError('Unknown bump level: $bumpLevel');
    }

    final String nextSemver = '$major.$minor.$patch';
    if (buildNum != null) {
      return '$nextSemver+${buildNum + 1}';
    }
    return nextSemver;
  }
}
