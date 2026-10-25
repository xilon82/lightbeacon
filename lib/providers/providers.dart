import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/clock/clock.dart';
import '../domain/engine/beacon_engine.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/beacon_config.dart';
import '../domain/models/preset.dart';
import '../domain/repositories/built_in_presets.dart';
import '../domain/repositories/settings_repository.dart';
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

  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).clearAll();
    state = const AppSettings();
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
    state = config;
    unawaited(ref.read(settingsRepositoryProvider).saveLastConfig(config));
  }

  void update(BeaconConfig Function(BeaconConfig current) transform) =>
      apply(transform(state));

  void loadMode(BeaconMode mode) => apply(BeaconConfig.forMode(mode));

  void loadPreset(Preset preset) => apply(preset.config);
}

final beaconConfigProvider =
    NotifierProvider<BeaconConfigNotifier, BeaconConfig>(
      BeaconConfigNotifier.new,
    );

// ---------------------------------------------------------------------------
// Presets
// ---------------------------------------------------------------------------

class PresetsNotifier extends Notifier<List<Preset>> {
  @override
  List<Preset> build() =>
      ref.watch(settingsRepositoryProvider).loadCustomPresets();

  Future<void> save(String name, BeaconConfig config) async {
    final preset = Preset(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      customName: name,
      config: config,
    );
    final next = [...state, preset];
    state = next;
    await ref.read(settingsRepositoryProvider).saveCustomPresets(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((p) => p.id != id).toList(growable: false);
    state = next;
    await ref.read(settingsRepositoryProvider).saveCustomPresets(next);
  }
}

final presetsProvider = NotifierProvider<PresetsNotifier, List<Preset>>(
  PresetsNotifier.new,
);

final builtInPresetsProvider = Provider<List<Preset>>(
  (ref) => BuiltInPresets.all,
);

// ---------------------------------------------------------------------------
// Beacon session
// ---------------------------------------------------------------------------

/// What the beacon screen needs to know about the running session.
class BeaconSessionState {
  const BeaconSessionState({
    this.running = false,
    this.torchAvailable = true,
    this.error,
    this.jitterWarning = false,
  });

  final bool running;
  final bool torchAvailable;
  final String? error;
  final bool jitterWarning;

  BeaconSessionState copyWith({
    bool? running,
    bool? torchAvailable,
    String? error,
    bool clearError = false,
    bool? jitterWarning,
  }) {
    return BeaconSessionState(
      running: running ?? this.running,
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
    final availability =
        await ref.read(torchControllerProvider).checkAvailability();
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

    state = state.copyWith(running: true, clearError: true, jitterWarning: false);

    if (config.screenEnabled) {
      final brightness =
          config.brightness.clamp(0.05, settings.brightnessCap);
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
    state = state.copyWith(running: false);
    await _teardown();
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
