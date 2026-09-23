import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/data/db/app_database.dart';
import 'package:stream_mediary/data/repositories/settings_repository.dart';
import 'package:stream_mediary/data/repositories/source_repository.dart';

/// Regression suite for the local-only source history and header templates.
void main() {
  late AppDatabase db;
  late SourceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SourceRepository(SettingsRepository(db));
  });

  tearDown(() async => db.close());

  group('recent urls', () {
    test('remembers urls newest-first without duplicates', () async {
      await repo.remember('https://a/1.m3u8');
      await repo.remember('https://a/2.m3u8');
      await repo.remember('https://a/1.m3u8'); // re-use moves to front
      expect(await repo.recentUrls(), [
        'https://a/1.m3u8',
        'https://a/2.m3u8',
      ]);
    });

    test('caps history at 20 entries', () async {
      for (var i = 0; i < 25; i++) {
        await repo.remember('https://a/$i.m3u8');
      }
      final recent = await repo.recentUrls();
      expect(recent, hasLength(20));
      expect(recent.first, 'https://a/24.m3u8');
      expect(recent, isNot(contains('https://a/4.m3u8')));
    });

    test('corrupt stored json degrades to empty list', () async {
      await SettingsRepository(db).setRaw('recent_urls', 'not-json{{');
      expect(await repo.recentUrls(), isEmpty);
    });
  });

  group('header templates', () {
    test('saves, replaces by name and deletes', () async {
      await repo.saveTemplate(const SourceTemplate(
        name: 'site-a',
        headers: {'Referer': 'https://a.example'},
      ));
      await repo.saveTemplate(const SourceTemplate(
        name: 'site-b',
        headers: {'Cookie': 'x=1'},
      ));
      var all = await repo.templates();
      expect(all.map((t) => t.name), containsAll(['site-a', 'site-b']));

      // Same name replaces instead of duplicating.
      await repo.saveTemplate(const SourceTemplate(
        name: 'site-a',
        headers: {'Referer': 'https://new.example'},
      ));
      all = await repo.templates();
      expect(all.where((t) => t.name == 'site-a'), hasLength(1));
      expect(
        all.firstWhere((t) => t.name == 'site-a').headers['Referer'],
        'https://new.example',
      );

      await repo.deleteTemplate('site-a');
      all = await repo.templates();
      expect(all.map((t) => t.name), ['site-b']);
    });

    test('template json round-trips headers', () {
      const template = SourceTemplate(
        name: 'n',
        headers: {'A': '1', 'B': '2'},
      );
      final restored = SourceTemplate.fromJson(template.toJson());
      expect(restored.name, 'n');
      expect(restored.headers, {'A': '1', 'B': '2'});
    });

    test('corrupt stored json degrades to empty list', () async {
      await SettingsRepository(db).setRaw('source_templates', '[broken');
      expect(await repo.templates(), isEmpty);
    });
  });
}
