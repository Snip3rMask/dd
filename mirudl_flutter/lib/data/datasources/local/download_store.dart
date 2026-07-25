import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/download_entry.dart';

/// Persistence for completed downloads (mirrors DownloadEntryStore.java)
class DownloadStore {
  static const String _prefKey = 'mirudl_downloads';
  static const String _keyEntries = 'entries';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError('DownloadStore not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Get all download entries, sorted by date descending
  List<DownloadEntry> all() {
    final raw = _p.getString(_keyEntries) ?? '[]';
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => DownloadEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Add or replace a download entry
  Future<void> add(DownloadEntry entry) async {
    final items = all();
    final key = entry.key;
    bool replaced = false;
    for (int i = 0; i < items.length; i++) {
      if (key == items[i].key) {
        items[i] = entry;
        replaced = true;
        break;
      }
    }
    if (!replaced) {
      items.insert(0, entry);
    }
    await _save(items);
  }

  /// Remove a specific entry
  Future<void> remove(DownloadEntry entry) async {
    final key = entry.key;
    final items = all().where((e) => e.key != key).toList();
    await _save(items);
  }

  /// Remove multiple entries
  Future<void> removeAll(List<DownloadEntry> entries) async {
    final keys = entries.map((e) => e.key).toSet();
    final items = all().where((e) => !keys.contains(e.key)).toList();
    await _save(items);
  }

  /// Save list to SharedPreferences as JSON
  Future<void> _save(List<DownloadEntry> items) async {
    final list = items.map((e) => e.toJson()).toList();
    await _p.setString(_keyEntries, jsonEncode(list));
  }
}
