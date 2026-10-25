import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/beacon_config.dart';
import '../models/preset.dart';

/// Persistence for settings, the last used config and user presets.
///
/// Everything is stored as versioned JSON so future schema changes can be
/// migrated instead of silently resetting the user's data.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'app_settings_v1';
  static const _lastConfigKey = 'last_config_v1';
  static const _customPresetsKey = 'custom_presets_v1';

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return AppSettings.fromJson(decoded);
    } catch (_) {
      // Corrupted entry: fall back to defaults rather than crashing.
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  BeaconConfig? loadLastConfig() {
    final raw = _prefs.getString(_lastConfigKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return BeaconConfig.fromJson(decoded);
    } catch (_) {
      // Ignore and fall back to the mode default.
    }
    return null;
  }

  Future<void> saveLastConfig(BeaconConfig config) =>
      _prefs.setString(_lastConfigKey, jsonEncode(config.toJson()));

  List<Preset> loadCustomPresets() {
    final raw = _prefs.getString(_customPresetsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, Object?>>()
            .map(Preset.fromJson)
            .toList(growable: false);
      }
    } catch (_) {
      // Ignore corrupted entries.
    }
    return const [];
  }

  Future<void> saveCustomPresets(List<Preset> presets) => _prefs.setString(
    _customPresetsKey,
    jsonEncode(presets.map((p) => p.toJson()).toList()),
  );

  Future<void> clearAll() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_lastConfigKey);
    await _prefs.remove(_customPresetsKey);
  }
}
