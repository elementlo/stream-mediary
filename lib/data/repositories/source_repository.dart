import 'dart:convert';

import 'settings_repository.dart';

class SourceTemplate {
  const SourceTemplate({required this.name, required this.headers});
  final String name;
  final Map<String, String> headers;

  Map<String, dynamic> toJson() => {'name': name, 'headers': headers};
  factory SourceTemplate.fromJson(Map<String, dynamic> json) => SourceTemplate(
    name: json['name'] as String,
    headers: (json['headers'] as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    ),
  );
}

/// Local, user-controlled history. No URL or request header leaves the device.
class SourceRepository {
  SourceRepository(this._settings);
  final SettingsRepository _settings;

  Future<List<String>> recentUrls() async {
    try {
      return (jsonDecode(await _settings.raw('recent_urls') ?? '[]') as List)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> remember(String url) async {
    final recent = await recentUrls();
    await _settings.setRaw(
      'recent_urls',
      jsonEncode([url, ...recent.where((old) => old != url)].take(20).toList()),
    );
  }

  Future<List<SourceTemplate>> templates() async {
    try {
      return (jsonDecode(await _settings.raw('source_templates') ?? '[]')
              as List)
          .map((e) => SourceTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTemplate(SourceTemplate template) async {
    final all = await templates();
    await _settings.setRaw(
      'source_templates',
      jsonEncode([
        ...all
            .where((item) => item.name != template.name)
            .map((e) => e.toJson()),
        template.toJson(),
      ]),
    );
  }

  Future<void> deleteTemplate(String name) async {
    final all = await templates();
    await _settings.setRaw(
      'source_templates',
      jsonEncode(
        all.where((item) => item.name != name).map((e) => e.toJson()).toList(),
      ),
    );
  }
}
