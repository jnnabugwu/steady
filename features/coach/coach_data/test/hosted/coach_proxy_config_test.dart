import 'package:coach_data/coach_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a profile or release build', () {
    test('drops the dev bypass and the Vercel bypass, whatever the defines '
        'say', () {
      final config = coachProxyConfigFor(
        debugBuild: false,
        baseUrl: 'https://coach.example.com',
        devBypassToken: 'dev-token',
        vercelProtectionBypass: 'vercel-secret',
      );
      expect(config.baseUrl, Uri.parse('https://coach.example.com'));
      expect(config.devBypassToken, isNull);
      expect(config.vercelProtectionBypass, isNull);
    });

    test('accepts only https', () {
      expect(
        coachProxyConfigFor(
          debugBuild: false,
          baseUrl: 'http://localhost:3000',
          devBypassToken: '',
          vercelProtectionBypass: '',
        ).baseUrl,
        isNull,
      );
    });
  });

  group('a debug build', () {
    test('keeps both bypass values, trimmed', () {
      final config = coachProxyConfigFor(
        debugBuild: true,
        baseUrl: 'https://preview.example.com',
        devBypassToken: ' dev-token ',
        vercelProtectionBypass: 'vercel-secret',
      );
      expect(config.devBypassToken, 'dev-token');
      expect(config.vercelProtectionBypass, 'vercel-secret');
    });

    test('accepts http too, for vercel dev on this Mac', () {
      expect(
        coachProxyConfigFor(
          debugBuild: true,
          baseUrl: 'http://localhost:3000/',
          devBypassToken: '',
          vercelProtectionBypass: '',
        ).baseUrl,
        Uri.parse('http://localhost:3000'),
      );
    });

    test('treats empty values as unset', () {
      final config = coachProxyConfigFor(
        debugBuild: true,
        baseUrl: '',
        devBypassToken: '',
        vercelProtectionBypass: '  ',
      );
      expect(config.baseUrl, isNull);
      expect(config.devBypassToken, isNull);
      expect(config.vercelProtectionBypass, isNull);
    });
  });

  test('a base URL loses its trailing slash and keeps its path', () {
    expect(
      coachProxyConfigFor(
        debugBuild: false,
        baseUrl: 'https://example.com/coach/',
        devBypassToken: '',
        vercelProtectionBypass: '',
      ).baseUrl,
      Uri.parse('https://example.com/coach'),
    );
  });

  test("a base URL that isn't one counts as none: the coach is off", () {
    for (final value in [
      'coach.example.com',
      'ftp://example.com',
      'https://',
      'https://example.com?x=1',
      'https://example.com#top',
      'not a url at all',
    ]) {
      expect(
        coachProxyConfigFor(
          debugBuild: true,
          baseUrl: value,
          devBypassToken: '',
          vercelProtectionBypass: '',
        ).baseUrl,
        isNull,
        reason: value,
      );
    }
  });

  test('fromEnvironment, with no defines (this test run), has no proxy and '
      'no bypass', () {
    final config = CoachProxyConfig.fromEnvironment();
    expect(config.baseUrl, isNull);
    expect(config.devBypassToken, isNull);
    expect(config.vercelProtectionBypass, isNull);
  });
}
