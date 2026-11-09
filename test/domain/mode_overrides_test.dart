import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/models/active_source.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/domain/repositories/built_in_presets.dart';
import 'package:light_beacon/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  Map<String, Object> values = const {},
  bool resetStorage = true,
}) async {
  if (resetStorage) SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModeOverridesNotifier', () {
    test('starts empty, so every mode uses its factory values', () async {
      final container = await _container();
      expect(container.read(modeOverridesProvider), isEmpty);

      container.read(beaconConfigProvider.notifier).loadMode(BeaconMode.sos);
      expect(
        container.read(beaconConfigProvider),
        BeaconConfig.forMode(BeaconMode.sos),
      );
      expect(
        container.read(activeSourceProvider),
        const ActiveSource.mode(BeaconMode.sos),
      );
    });

    test('saving over a mode stores the override and reloads it', () async {
      final container = await _container();
      final config = container.read(beaconConfigProvider.notifier);

      config.loadMode(BeaconMode.strobe);
      config.apply(
        BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 5),
      );
      expect(container.read(beaconConfigDirtyProvider), isTrue);

      config.saveOverMode();
      expect(
        container.read(modeOverridesProvider)[BeaconMode.strobe]?.frequencyHz,
        5,
      );
      expect(container.read(beaconConfigDirtyProvider), isFalse);

      // Reloading the mode must pick the saved values, not the factory ones.
      config.loadMode(BeaconMode.sos);
      config.loadMode(BeaconMode.strobe);
      expect(container.read(beaconConfigProvider).frequencyHz, 5);
    });

    test('the override survives a new container on the same storage', () async {
      final first = await _container();
      first.read(beaconConfigProvider.notifier).loadMode(BeaconMode.strobe);
      first
          .read(beaconConfigProvider.notifier)
          .apply(
            BeaconConfig.forMode(BeaconMode.strobe).copyWith(dutyCycle: 0.8),
          );
      first.read(beaconConfigProvider.notifier).saveOverMode();
      await Future<void>.delayed(Duration.zero);

      final second = await _container(resetStorage: false);
      second.read(beaconConfigProvider.notifier).loadMode(BeaconMode.strobe);
      expect(second.read(beaconConfigProvider).dutyCycle, 0.8);
    });

    test(
      'resetting a mode drops the override and restores the defaults',
      () async {
        final container = await _container();
        final config = container.read(beaconConfigProvider.notifier);

        config.loadMode(BeaconMode.strobe);
        config.apply(
          BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 7),
        );
        config.saveOverMode();
        expect(container.read(modeOverridesProvider), isNotEmpty);

        config.resetMode();
        expect(container.read(modeOverridesProvider), isEmpty);
        expect(
          container.read(beaconConfigProvider),
          BeaconConfig.forMode(BeaconMode.strobe),
        );
      },
    );

    test('resetAll clears every mode at once', () async {
      final container = await _container();
      final config = container.read(beaconConfigProvider.notifier);

      config.loadMode(BeaconMode.strobe);
      config.apply(
        BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 6),
      );
      config.saveOverMode();
      config.loadMode(BeaconMode.sos);
      config.apply(
        BeaconConfig.forMode(BeaconMode.sos).copyWith(brightness: 0.4),
      );
      config.saveOverMode();
      expect(container.read(modeOverridesProvider), hasLength(2));

      await container.read(modeOverridesProvider.notifier).resetAll();
      expect(container.read(modeOverridesProvider), isEmpty);
    });

    test('a corrupted overlay falls back to the factory values', () async {
      final container = await _container(
        values: {'mode_overrides_v1': 'not json at all'},
      );
      expect(container.read(modeOverridesProvider), isEmpty);

      container.read(beaconConfigProvider.notifier).loadMode(BeaconMode.sos);
      expect(
        container.read(beaconConfigProvider),
        BeaconConfig.forMode(BeaconMode.sos),
      );
    });

    test('the settings reset wipes modes, presets and overrides', () async {
      final container = await _container();
      final config = container.read(beaconConfigProvider.notifier);

      config.loadMode(BeaconMode.strobe);
      config.apply(
        BeaconConfig.forMode(BeaconMode.strobe).copyWith(frequencyHz: 4),
      );
      config.saveOverMode();
      await container.read(presetsProvider.notifier).remove('bike');
      await container
          .read(presetsProvider.notifier)
          .save('Mio', BeaconConfig.forMode(BeaconMode.sos));

      await container.read(settingsProvider.notifier).reset();

      expect(container.read(modeOverridesProvider), isEmpty);
      expect(container.read(presetsProvider).custom, isEmpty);
      expect(
        container.read(presetsProvider).builtIn,
        hasLength(BuiltInPresets.all.length),
      );
      expect(container.read(activeSourceProvider), isNull);
      // The safety notice stays acknowledged: no surprise onboarding.
      expect(container.read(settingsProvider).safetyAcknowledged, isTrue);
    });
  });
}
