import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/clock/clock.dart';
import '../domain/engine/beacon_engine.dart';
import '../domain/models/active_source.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/beacon_config.dart';
import '../domain/models/preset.dart';
import '../domain/repositories/built_in_presets.dart';
import '../domain/repositories/settings_repository.dart';
import '../platform/foreground/foreground_controller.dart';
import '../platform/screen/screen_controller.dart';
import '../platform/torch/torch_controller.dart';

/// Overridden in `main()` once `SharedPreferences` has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final torchControllerProvider = Provider<TorchController>((ref) {
  final controller = PluginTorchController();
  ref.onDispose(controller.dispose);
  return controller;
});

final screenControllerProvider = Provider<ScreenController>((ref) {
  final controller = PluginScreenController();
  ref.onDispose(controller.dispose);
  return controller;
});

final clockProvider = Provider<Clock>((ref) => StopwatchClock());

/// Window focus, used to pause the beacon while another window covers it.
final foregroundControllerProvider = Provider<ForegroundController>((ref) {
  final controller = PluginForegroundController();
  ref.onDispose(controller.dispose);
  return controller;
});

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).loadSettings();

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).saveSettings(next);
  }

  Future<void> setLocale(String? code) =>
      _persist(state.copyWith(localeCode: code, clearLocale: code == null));

  Future<void> acknowledgeSafety() =>
      _persist(state.copyWith(safetyAcknowledged: true));

  Future<void> setBrightnessCap(double value) =>
      _persist(state.copyWith(brightnessCap: value.clamp(0.1, 1.0)));

  Future<void> setKeepAwake(bool value) =>
      _persist(state.copyWith(keepAwake: value));

  Future<void> setPauseWhenBackgrounded(bool value) =>
      _persist(state.copyWith(pauseWhenBackgrounded: value));

  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).clearAll();
    await ref.read(presetsProvider.notifier).restoreFactory();
    await ref.read(modeOverridesProvider.notifier).resetAll();
    ref.read(activeSourceProvider.notifier).set(null);

    // The safety notice stays acknowledged: the user has already read it and
    // being sent back to the onboarding after a reset is only annoying.
    const next = AppSettings(safetyAcknowledged: true);
    state = next;
    await ref.read(settingsRepositoryProvider).saveSettings(next);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ---------------------------------------------------------------------------
// Beacon configuration
// ---------------------------------------------------------------------------

class BeaconConfigNotifier extends Notifier<BeaconConfig> {
  @override
  BeaconConfig build() {
    final saved = ref.watch(settingsRepositoryProvider).loadLastConfig();
    return saved ?? BeaconConfig.forMode(BeaconMode.strobe);
  }

  void apply(BeaconConfig config) {
    final normalized = config.normalized;
    state = normalized;
    unawaited(ref.read(settingsRepositoryProvider).saveLastConfig(normalized));
  }

  void update(BeaconConfig Function(BeaconConfig current) transform) =>
      apply(transform(state));

  /// Starts a home-screen mode: the user's override wins over the factory one.
  void loadMode(BeaconMode mode) {
    final override = ref.read(modeOverridesProvider)[mode];
    apply(override ?? BeaconConfig.forMode(mode));
    _setSource(ActiveSource.mode(mode));
  }

  /// Starts a preset.
  void loadPreset(Preset preset) {
    apply(preset.config);
    _setSource(ActiveSource.preset(preset.id));
  }

  /// Overwrites the mode the beacon was started from with the current config.
  void saveOverMode() {
    final mode = ref.read(activeSourceProvider)?.mode;
    if (mode == null) return;
    unawaited(ref.read(modeOverridesProvider.notifier).save(mode, state));
  }

  /// Drops the override of the current mode, back to the factory values.
  void resetMode() {
    final mode = ref.read(activeSourceProvider)?.mode;
    if (mode == null) return;
    unawaited(ref.read(modeOverridesProvider.notifier).reset(mode));
    apply(BeaconConfig.forMode(mode));
  }

  /// Overwrites the preset the beacon was started from.
  Future<void> saveOverPreset() async {
    final presetId = ref.read(activeSourceProvider)?.presetId;
    if (presetId == null) return;
    await ref.read(presetsProvider.notifier).overwrite(presetId, state);
  }

  /// Creates a preset from the current config and follows it.
  Future<void> saveAsNewPreset(String name) async {
    final preset = await ref.read(presetsProvider.notifier).save(name, state);
    _setSource(ActiveSource.preset(preset.id));
  }

  void _setSource(ActiveSource source) =>
      ref.read(activeSourceProvider.notifier).set(source);
}

final beaconConfigProvider =
    NotifierProvider<BeaconConfigNotifier, BeaconConfig>(
      BeaconConfigNotifier.new,
    );

// ---------------------------------------------------------------------------
// Mode overrides
// ---------------------------------------------------------------------------

/// Home-screen modes the user personalised.
///
/// Only the modes they saved over are stored; the others keep coming from
/// [BeaconConfig.forMode], which stays the factory default.
class ModeOverridesNotifier extends Notifier<Map<BeaconMode, BeaconConfig>> {
  @override
  Map<BeaconMode, BeaconConfig> build() {
    final stored = ref.watch(settingsRepositoryProvider).loadModeOverrides();
    return {
      for (final entry in stored.entries)
        for (final mode in BeaconMode.values)
          if (mode.name == entry.key) mode: entry.value,
    };
  }

  Future<void> save(BeaconMode mode, BeaconConfig config) async {
    state = {...state, mode: config.normalized};
    await _persist();
  }

  Future<void> reset(BeaconMode mode) async {
    state = {...state}..remove(mode);
    await _persist();
  }

  Future<void> resetAll() async {
    state = const {};
    await ref.read(settingsRepositoryProvider).saveModeOverrides(const {});
  }

  Future<void> _persist() =>
      ref.read(settingsRepositoryProvider).saveModeOverrides({
        for (final entry in state.entries) entry.key.name: entry.value,
      });
}

final modeOverridesProvider =
    NotifierProvider<ModeOverridesNotifier, Map<BeaconMode, BeaconConfig>>(
      ModeOverridesNotifier.new,
    );

/// The mode or preset the running configuration comes from, if any.
class ActiveSourceNotifier extends Notifier<ActiveSource?> {
  @override
  ActiveSource? build() =>
      ref.watch(settingsRepositoryProvider).loadActiveSource();

  void set(ActiveSource? source) {
    state = source;
    unawaited(ref.read(settingsRepositoryProvider).saveActiveSource(source));
  }
}

final activeSourceProvider =
    NotifierProvider<ActiveSourceNotifier, ActiveSource?>(
      ActiveSourceNotifier.new,
    );

/// True when the current configuration differs from the one it started from.
///
/// Drives the "save over" affordance: with nothing to overwrite the only
/// option left is saving a new preset.
final beaconConfigDirtyProvider = Provider<bool>((ref) {
  final config = ref.watch(beaconConfigProvider);
  final source = ref.watch(activeSourceProvider);
  if (source == null) return false;

  final mode = source.mode;
  if (mode != null) {
    final overrides = ref.watch(modeOverridesProvider);
    final base = overrides[mode] ?? BeaconConfig.forMode(mode);
    return config != base;
  }

  final preset = ref.watch(presetsProvider).byId(source.presetId ?? '');
  return preset != null && config != preset.config;
});

// ---------------------------------------------------------------------------
// Presets
// ---------------------------------------------------------------------------

/// Built-in presets as the user sees them: factory defaults with their own
/// changes applied, minus the ones they deleted, plus their own presets.
///
/// The factory list stays in [BuiltInPresets] and is never mutated, so a
/// factory reset only has to forget the overlays.
class PresetLibrary {
  const PresetLibrary({
    required this.builtIn,
    required this.custom,
    required this.overriddenIds,
  });

  final List<Preset> builtIn;
  final List<Preset> custom;
  final Set<String> overriddenIds;

  List<Preset> get all => [...builtIn, ...custom];

  bool isOverridden(String id) => overriddenIds.contains(id);

  Preset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

class PresetsNotifier extends Notifier<PresetLibrary> {
  @override
  PresetLibrary build() => _assemble();

  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  PresetLibrary _assemble() {
    final overrides = _repository.loadPresetOverrides();
    final removed = _repository.loadRemovedPresetIds().toSet();

    final builtIn = <Preset>[];
    for (final factory in BuiltInPresets.all) {
      if (removed.contains(factory.id)) continue;
      final override = overrides[factory.id];
      builtIn.add(
        override == null
            ? factory
            : factory.copyWith(
                config: override.config,
                customName: override.customName,
              ),
      );
    }

    return PresetLibrary(
      builtIn: builtIn,
      custom: _repository.loadCustomPresets(),
      overriddenIds: {
        for (final entry in overrides.entries)
          if (!removed.contains(entry.key)) entry.key,
      },
    );
  }

  /// Creates a preset from the current configuration.
  Future<Preset> save(String name, BeaconConfig config) async {
    final preset = Preset(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      customName: name,
      config: config.normalized,
    );
    await _repository.saveCustomPresets([...state.custom, preset]);
    state = _assemble();
    return preset;
  }

  /// Overwrites [id] with [config], keeping its name.
  Future<void> overwrite(String id, BeaconConfig config) async {
    final custom = state.custom;
    final index = custom.indexWhere((preset) => preset.id == id);
    if (index >= 0) {
      final next = [...custom];
      next[index] = custom[index].copyWith(config: config.normalized);
      await _repository.saveCustomPresets(next);
      state = _assemble();
      return;
    }
    await _saveOverride(id, config: config.normalized);
  }

  /// Renames [id]; a built-in keeps its localized name as a fallback.
  Future<void> rename(String id, String name) async {
    final custom = state.custom;
    final index = custom.indexWhere((preset) => preset.id == id);
    if (index >= 0) {
      final next = [...custom];
      next[index] = custom[index].copyWith(customName: name);
      await _repository.saveCustomPresets(next);
      state = _assemble();
      return;
    }
    await _saveOverride(id, customName: name);
  }

  /// Deletes [id].
  ///
  /// A built-in leaves a tombstone, so a preset deleted on purpose does not
  /// come back on the next launch; only a factory reset clears it.
  Future<void> remove(String id) async {
    final custom = state.custom;
    if (custom.any((preset) => preset.id == id)) {
      await _repository.saveCustomPresets(
        custom.where((preset) => preset.id != id).toList(growable: false),
      );
      state = _assemble();
      return;
    }

    final overrides = Map<String, PresetOverride>.from(
      _repository.loadPresetOverrides(),
    )..remove(id);
    await _repository.savePresetOverrides(overrides);
    await _repository.saveRemovedPresetIds(
      {..._repository.loadRemovedPresetIds(), id}.toList(growable: false),
    );
    state = _assemble();
  }

  /// Brings a built-in back to its factory configuration and name.
  Future<void> restoreBuiltIn(String id) async {
    final overrides = Map<String, PresetOverride>.from(
      _repository.loadPresetOverrides(),
    )..remove(id);
    await _repository.savePresetOverrides(overrides);
    await _repository.saveRemovedPresetIds(
      _repository
          .loadRemovedPresetIds()
          .where((removedId) => removedId != id)
          .toList(growable: false),
    );
    state = _assemble();
  }

  /// Deletes every user preset and every change to the built-ins.
  Future<void> restoreFactory() async {
    await _repository.saveCustomPresets(const []);
    await _repository.savePresetOverrides(const {});
    await _repository.saveRemovedPresetIds(const []);
    state = _assemble();
  }

  Future<void> _saveOverride(
    String id, {
    BeaconConfig? config,
    String? customName,
  }) async {
    final overrides = Map<String, PresetOverride>.from(
      _repository.loadPresetOverrides(),
    );
    final previous = overrides[id];
    final nextConfig = config ?? previous?.config ?? _factoryById(id)?.config;
    if (nextConfig == null) return;

    overrides[id] = PresetOverride(
      config: nextConfig,
      customName: customName ?? previous?.customName,
    );
    await _repository.savePresetOverrides(overrides);
    state = _assemble();
  }

  Preset? _factoryById(String id) {
    for (final preset in BuiltInPresets.all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

final presetsProvider = NotifierProvider<PresetsNotifier, PresetLibrary>(
  PresetsNotifier.new,
);

// ---------------------------------------------------------------------------
// Beacon session
// ---------------------------------------------------------------------------

/// What the beacon screen needs to know about the running session.
class BeaconSessionState {
  const BeaconSessionState({
    this.running = false,
    this.paused = false,
    this.torchAvailable = true,
    this.error,
    this.jitterWarning = false,
  });

  final bool running;

  /// The session is alive but suspended: another window has focus.
  final bool paused;
  final bool torchAvailable;
  final String? error;
  final bool jitterWarning;

  BeaconSessionState copyWith({
    bool? running,
    bool? paused,
    bool? torchAvailable,
    String? error,
    bool clearError = false,
    bool? jitterWarning,
  }) {
    return BeaconSessionState(
      running: running ?? this.running,
      paused: paused ?? this.paused,
      torchAvailable: torchAvailable ?? this.torchAvailable,
      error: clearError ? null : (error ?? this.error),
      jitterWarning: jitterWarning ?? this.jitterWarning,
    );
  }
}

class BeaconSessionNotifier extends Notifier<BeaconSessionState> {
  late final BeaconEngine engine;
  Timer? _jitterCheck;

  @override
  BeaconSessionState build() {
    final torch = ref.watch(torchControllerProvider);
    engine = BeaconEngine(
      clock: ref.watch(clockProvider),
      setTorch: torch.setTorch,
    );
    engine.onError = _onEngineError;
    engine.onTimeout = _onTimeout;

    ref.onDispose(() {
      _jitterCheck?.cancel();
      engine.dispose();
    });

    unawaited(_probeTorch());
    return const BeaconSessionState();
  }

  Future<void> _probeTorch() async {
    final availability = await ref
        .read(torchControllerProvider)
        .checkAvailability();
    if (!ref.mounted) return;
    state = state.copyWith(
      torchAvailable: availability == TorchAvailability.available,
    );
  }

  void _onEngineError(Object error) {
    if (!ref.mounted) return;
    state = state.copyWith(error: error.toString());
  }

  void _onTimeout() {
    if (!ref.mounted) return;
    state = state.copyWith(running: false);
    unawaited(_teardown());
  }

  Future<void> start(BeaconConfig config) async {
    final settings = ref.read(settingsProvider);
    final screen = ref.read(screenControllerProvider);

    state = state.copyWith(
      running: true,
      paused: false,
      clearError: true,
      jitterWarning: false,
    );

    if (config.screenEnabled) {
      final brightness = config.brightness.clamp(0.05, settings.brightnessCap);
      await screen.applyBrightness(brightness);
    } else {
      await screen.restore();
    }

    if (settings.keepAwake) {
      _setWakelock(true);
    }

    engine.start(config);
    _startJitterWatch();
  }

  Future<void> stop() async {
    engine.stop();
    state = state.copyWith(running: false, paused: false);
    await _teardown();
  }

  /// Suspends the blinking while another window covers the beacon.
  ///
  /// The torch stays **on and steady**: the system posts a notification on
  /// every torch change, so it is the blinking that makes the notification
  /// shade churn, not the light itself. Keeping it on also preserves the whole
  /// point of the app while the user checks a notification.
  ///
  /// [resume] restarts the engine with a fresh origin, so the pause cannot
  /// introduce drift.
  void pause() {
    if (!state.running || state.paused) return;
    _jitterCheck?.cancel();
    _jitterCheck = null;
    state = state.copyWith(paused: true);

    if (ref.read(beaconConfigProvider).torchEnabled) {
      engine.holdTorch();
    } else {
      engine.stop();
    }
  }

  /// Restarts a paused session with the current configuration.
  void resume() {
    if (!state.running || !state.paused) return;
    state = state.copyWith(paused: false);
    engine.start(ref.read(beaconConfigProvider));
    _startJitterWatch();
  }

  void updateConfig(BeaconConfig config) {
    engine.updateConfig(config);
    if (!state.running) return;
    if (config.screenEnabled) {
      final cap = ref.read(settingsProvider).brightnessCap;
      unawaited(
        ref
            .read(screenControllerProvider)
            .applyBrightness(config.brightness.clamp(0.05, cap)),
      );
    } else {
      unawaited(ref.read(screenControllerProvider).restore());
    }
  }

  Future<void> _teardown() async {
    _jitterCheck?.cancel();
    _jitterCheck = null;
    await ref.read(screenControllerProvider).restore();
    _setWakelock(false);
  }

  /// The wakelock is a nicety: a platform channel that never answers must not
  /// keep the beacon alive or block the stop path, so this is fire-and-forget.
  void _setWakelock(bool enable) {
    try {
      final call = enable ? WakelockPlus.enable() : WakelockPlus.disable();
      call.catchError((Object _) {});
    } catch (_) {
      // Ignore: the screen may still sleep, but the beacon keeps working.
    }
  }

  void _startJitterWatch() {
    _jitterCheck?.cancel();
    _jitterCheck = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!ref.mounted || !engine.isRunning) return;
      final unstable = engine.jitter.isUnstable;
      if (unstable != state.jitterWarning) {
        state = state.copyWith(jitterWarning: unstable);
      }
    });
  }
}

final beaconSessionProvider =
    NotifierProvider<BeaconSessionNotifier, BeaconSessionState>(
      BeaconSessionNotifier.new,
    );
