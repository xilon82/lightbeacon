import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/active_source.dart';
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
  static const _modeOverridesKey = 'mode_overrides_v1';
  static const _presetOverridesKey = 'preset_overrides_v1';
  static const _removedPresetsKey = 'preset_removed_v1';
  static const _activeSourceKey = 'active_source_v1';

  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return AppSettings.fromJson(decoded);
      }
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
      if (decoded is Map<String, Object?>) {
        return BeaconConfig.fromJson(decoded);
      }
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

  // ---------------------------------------------------------------------------
  // Personalisation overlays
  //
  // Built-in modes and presets are factory values and stay immutable; what the
  // user changes lives in these overlays. A factory reset is therefore just
  // "forget the overlays", and a missing or unreadable overlay is never an
  // error: the factory value is used instead.
  // ---------------------------------------------------------------------------

  Map<String, BeaconConfig> _loadConfigOverrides(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return {
          for (final entry in decoded.entries)
            if (entry.value is Map<String, Object?>)
              entry.key: BeaconConfig.fromJson(
                entry.value as Map<String, Object?>,
              ),
        };
      }
    } catch (_) {
      // Corrupted overlay: the factory values are still valid.
    }
    return const {};
  }

  Future<void> _saveConfigOverrides(
    String key,
    Map<String, BeaconConfig> overrides,
  ) => _prefs.setString(
    key,
    jsonEncode({
      for (final entry in overrides.entries) entry.key: entry.value.toJson(),
    }),
  );

  /// Mode name → configuration the user saved over that mode.
  Map<String, BeaconConfig> loadModeOverrides() =>
      _loadConfigOverrides(_modeOverridesKey);

  Future<void> saveModeOverrides(Map<String, BeaconConfig> overrides) =>
      _saveConfigOverrides(_modeOverridesKey, overrides);

  /// Built-in preset id → configuration and optional name the user chose.
  Map<String, PresetOverride> loadPresetOverrides() {
    final raw = _prefs.getString(_presetOverridesKey);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return {
          for (final entry in decoded.entries)
            if (entry.value is Map<String, Object?>)
              entry.key: PresetOverride.fromJson(
                entry.value as Map<String, Object?>,
              ),
        };
      }
    } catch (_) {
      // Corrupted overlay: the factory values are still valid.
    }
    return const {};
  }

  Future<void> savePresetOverrides(Map<String, PresetOverride> overrides) =>
      _prefs.setString(
        _presetOverridesKey,
        jsonEncode({
          for (final entry in overrides.entries)
            entry.key: entry.value.toJson(),
        }),
      );

  /// Built-in presets the user deleted.
  ///
  /// Kept as tombstones so a preset deleted on purpose does not come back on
  /// the next launch; only a factory reset clears them.
  List<String> loadRemovedPresetIds() {
    final raw = _prefs.getString(_removedPresetsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      // Ignore corrupted entries.
    }
    return const [];
  }

  Future<void> saveRemovedPresetIds(List<String> ids) =>
      _prefs.setString(_removedPresetsKey, jsonEncode(ids));

  ActiveSource? loadActiveSource() {
    final raw = _prefs.getString(_activeSourceKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return ActiveSource.fromJson(decoded);
      }
    } catch (_) {
      // Ignore: without a source the UI only offers "save as new".
    }
    return null;
  }

  Future<void> saveActiveSource(ActiveSource? source) => source == null
      ? _prefs.remove(_activeSourceKey)
      : _prefs.setString(_activeSourceKey, jsonEncode(source.toJson()));

  /// Wipes settings, the last config, user presets and every personalisation
  /// overlay. Built-in modes and presets come back as they ship.
  Future<void> clearAll() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_lastConfigKey);
    await _prefs.remove(_customPresetsKey);
    await _prefs.remove(_modeOverridesKey);
    await _prefs.remove(_presetOverridesKey);
    await _prefs.remove(_removedPresetsKey);
    await _prefs.remove(_activeSourceKey);
  }
}
