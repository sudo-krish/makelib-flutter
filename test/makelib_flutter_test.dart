import 'package:makelib_flutter/makelib_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('MakelibFlutter Constants', () {
    test('version is defined', () {
      expect(MakelibFlutter.version, equals('1.0.0+1'));
    });

    test('defaultMinCoverage is 80.0', () {
      expect(MakelibFlutter.defaultMinCoverage, equals(80.0));
    });

    test('permittedLicenses contains standard permissive licenses', () {
      expect(MakelibFlutter.permittedLicenses, contains('MIT'));
      expect(MakelibFlutter.permittedLicenses, contains('Apache-2.0'));
      expect(MakelibFlutter.permittedLicenses, contains('BSD-3-Clause'));
    });
  });

  group('Shift-Left Branch Validation', () {
    test('rejects direct commits to main and master', () {
      expect(MakelibFlutter.isValidBranchName('main'), isFalse);
      expect(MakelibFlutter.isValidBranchName('master'), isFalse);
      expect(MakelibFlutter.isValidBranchName(''), isFalse);
    });

    test('accepts compliant feature branches', () {
      expect(MakelibFlutter.isValidBranchName('feat/add-login'), isTrue);
      expect(
        MakelibFlutter.isValidBranchName('feature/profile-screen'),
        isTrue,
      );
    });

    test('accepts compliant fix, chore, docs, and ci branches', () {
      expect(MakelibFlutter.isValidBranchName('fix/memory-leak'), isTrue);
      expect(MakelibFlutter.isValidBranchName('patch/hotfix-v1.0'), isTrue);
      expect(MakelibFlutter.isValidBranchName('docs/quickstart-guide'), isTrue);
      expect(MakelibFlutter.isValidBranchName('chore/upgrade-deps'), isTrue);
      expect(
        MakelibFlutter.isValidBranchName('refactor/service-locator'),
        isTrue,
      );
      expect(MakelibFlutter.isValidBranchName('ci/matrix-test'), isTrue);
    });

    test('accepts compliant major and breaking branches', () {
      expect(MakelibFlutter.isValidBranchName('major/null-safety-v2'), isTrue);
      expect(
        MakelibFlutter.isValidBranchName('breaking/new-api-schema'),
        isTrue,
      );
    });

    test('rejects non-compliant branch names', () {
      expect(MakelibFlutter.isValidBranchName('my-feature'), isFalse);
      expect(
        MakelibFlutter.isValidBranchName('feature_without_slash'),
        isFalse,
      );
      expect(MakelibFlutter.isValidBranchName('test/branch'), isFalse);
    });
  });

  group('SemVer Branch Classification', () {
    test('classifies major and breaking branches as major', () {
      expect(
        MakelibFlutter.classifyBranch('major/v2-rewrite'),
        equals('major'),
      );
      expect(MakelibFlutter.classifyBranch('breaking/api-v2'), equals('major'));
    });

    test('classifies feat and feature branches as minor', () {
      expect(MakelibFlutter.classifyBranch('feat/export-csv'), equals('minor'));
      expect(
        MakelibFlutter.classifyBranch('feature/dark-mode'),
        equals('minor'),
      );
    });

    test('classifies fix, chore, docs and other branches as patch', () {
      expect(MakelibFlutter.classifyBranch('fix/null-check'), equals('patch'));
      expect(MakelibFlutter.classifyBranch('docs/readme-fix'), equals('patch'));
      expect(
        MakelibFlutter.classifyBranch('chore/clean-logs'),
        equals('patch'),
      );
      expect(
        MakelibFlutter.classifyBranch('other/custom-task'),
        equals('patch'),
      );
    });
  });

  group('License Compliance Verification', () {
    test('accepts approved open-source licenses', () {
      expect(MakelibFlutter.isPermittedLicense('MIT'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('mit'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('Apache-2.0'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('BSD-2-Clause'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('BSD-3-Clause'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('ISC'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('0BSD'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('Unlicense'), isTrue);
      expect(MakelibFlutter.isPermittedLicense('CC0-1.0'), isTrue);
    });

    test('rejects proprietary or copyleft licenses', () {
      expect(MakelibFlutter.isPermittedLicense('GPL-3.0'), isFalse);
      expect(MakelibFlutter.isPermittedLicense('AGPL-3.0'), isFalse);
      expect(MakelibFlutter.isPermittedLicense('Commercial'), isFalse);
    });
  });

  group('SemVer Calculation & Build Increments', () {
    test('bumps patch correctly with build number', () {
      final String next = MakelibFlutter.computeNextVersion('1.0.0+1', 'patch');
      expect(next, equals('1.0.1+2'));
    });

    test('bumps minor correctly with build number', () {
      final String next = MakelibFlutter.computeNextVersion('1.0.0+1', 'minor');
      expect(next, equals('1.1.0+2'));
    });

    test('bumps major correctly with build number', () {
      final String next = MakelibFlutter.computeNextVersion('1.0.0+1', 'major');
      expect(next, equals('2.0.0+2'));
    });

    test('bumps version without build number', () {
      expect(
        MakelibFlutter.computeNextVersion('2.3.4', 'patch'),
        equals('2.3.5'),
      );
      expect(
        MakelibFlutter.computeNextVersion('2.3.4', 'minor'),
        equals('2.4.0'),
      );
      expect(
        MakelibFlutter.computeNextVersion('2.3.4', 'major'),
        equals('3.0.0'),
      );
    });

    test('throws ArgumentError on invalid SemVer or bump level', () {
      expect(
        () => MakelibFlutter.computeNextVersion('invalid-version', 'patch'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => MakelibFlutter.computeNextVersion('1.0.0', 'super-major'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
