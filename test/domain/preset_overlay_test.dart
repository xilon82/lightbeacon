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

  group('PresetLibrary', () {
    test('ships every built-in preset with no overrides', () async {
      final container = await _container();
      final library = container.read(presetsProvider);

      expect(library.builtIn, hasLength(BuiltInPresets.all.length));
      expect(library.custom, isEmpty);
      expect(library.overriddenIds, isEmpty);
    });

    test('deleting a built-in hides it and leaves a tombstone', () async {
      final container = await _container();
      await container
          .read(presetsProvider.notifier)
          .remove(BuiltInPresets.worksite.id);

      final library = container.read(presetsProvider);
      expect(
        library.builtIn.map((preset) => preset.id),
        isNot(contains('worksite')),
      );
      expect(library.builtIn, hasLength(BuiltInPresets.all.length - 1));

      // A deleted built-in must not come back on the next launch.
      final second = await _container(resetStorage: false);
      expect(
        second.read(presetsProvider).builtIn.map((preset) => preset.id),
        isNot(contains('worksite')),
      );
    });

    test('restoring a deleted built-in brings it back', () async {
      final container = await _container();
      final notifier = container.read(presetsProvider.notifier);

      await notifier.remove(BuiltInPresets.worksite.id);
      await notifier.restoreBuiltIn(BuiltInPresets.worksite.id);

      expect(
        container.read(presetsProvider).builtIn.map((preset) => preset.id),
        contains('worksite'),
      );
    });

    test(
      'overwriting a built-in keeps its name and marks it modified',
      () async {
        final container = await _container();
        await container
            .read(presetsProvider.notifier)
            .overwrite('pedestrian', BeaconConfig.forMode(BeaconMode.sos));

        final library = container.read(presetsProvider);
        final preset = library.byId('pedestrian')!;
        expect(preset.config, BeaconConfig.forMode(BeaconMode.sos));
        expect(preset.nameKey, 'presetPedestrian');
        expect(preset.customName, isNull);
        expect(library.isOverridden('pedestrian'), isTrue);
      },
    );

    test('renaming a built-in wins over its localized name', () async {
      final container = await _container();
      await container
          .read(presetsProvider.notifier)
          .rename('pedestrian', 'Mio pedone');

      expect(
        container.read(presetsProvider).byId('pedestrian')?.customName,
        'Mio pedone',
      );
    });

    test('a custom preset is overwritten in place', () async {
      final container = await _container();
      final notifier = container.read(presetsProvider.notifier);

      final created = await notifier.save(
        'Mio',
        BeaconConfig.forMode(BeaconMode.sos),
      );
      await notifier.overwrite(
        created.id,
        BeaconConfig.forMode(BeaconMode.torch),
      );

      final library = container.read(presetsProvider);
      expect(library.custom, hasLength(1));
      expect(
        library.custom.single.config,
        BeaconConfig.forMode(BeaconMode.torch),
      );
      expect(library.custom.single.customName, 'Mio');
    });

    test(
      'a factory reset restores the built-ins and drops the custom ones',
      () async {
        final container = await _container();
        final notifier = container.read(presetsProvider.notifier);

        await notifier.remove('bike');
        await notifier.rename('worksite', 'Cantiere mio');
        await notifier.save('Mio', BeaconConfig.forMode(BeaconMode.sos));
        await notifier.restoreFactory();

        final library = container.read(presetsProvider);
        expect(library.builtIn, hasLength(BuiltInPresets.all.length));
        expect(library.custom, isEmpty);
        expect(library.overriddenIds, isEmpty);
        expect(library.byId('worksite')?.customName, isNull);
      },
    );

    test('a corrupted overlay falls back to the factory list', () async {
      final container = await _container(
        values: {
          'preset_overrides_v1': 'not json',
          'preset_removed_v1': 'not json either',
        },
      );

      expect(
        container.read(presetsProvider).builtIn,
        hasLength(BuiltInPresets.all.length),
      );
    });
  });

  group('active source', () {
    test(
      'loading a preset makes it the source, saving over keeps it',
      () async {
        final container = await _container();
        final config = container.read(beaconConfigProvider.notifier);

        config.loadPreset(BuiltInPresets.pedestrian);
        expect(
          container.read(activeSourceProvider),
          const ActiveSource.preset('pedestrian'),
        );
        expect(container.read(beaconConfigDirtyProvider), isFalse);

        config.apply(BeaconConfig.forMode(BeaconMode.sos));
        expect(container.read(beaconConfigDirtyProvider), isTrue);

        await config.saveOverPreset();
        expect(
          container.read(presetsProvider).byId('pedestrian')?.config,
          BeaconConfig.forMode(BeaconMode.sos),
        );
        expect(container.read(beaconConfigDirtyProvider), isFalse);
      },
    );

    test('saving as new follows the new preset', () async {
      final container = await _container();
      final config = container.read(beaconConfigProvider.notifier);

      config.loadMode(BeaconMode.strobe);
      await config.saveAsNewPreset('Nuovo');

      final created = container.read(presetsProvider).custom.single;
      expect(created.customName, 'Nuovo');
      expect(
        container.read(activeSourceProvider),
        ActiveSource.preset(created.id),
      );
    });
  });
}
