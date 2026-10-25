import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/models/app_settings.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/domain/models/preset.dart';

void main() {
  group('BeaconConfig serialization', () {
    test('round-trips every field', () {
      const config = BeaconConfig(
        pattern: FlashPattern.triple,
        frequencyHz: 3.5,
        dutyCycle: 0.35,
        primaryColor: BeaconPalette.red,
        secondaryColor: BeaconPalette.cyan,
        effect: ScreenEffect.alternate,
        brightness: 0.65,
        sync: SyncMode.counterPhase,
        timeoutMinutes: 15,
        torchEnabled: false,
        screenEnabled: true,
      );

      final restored = BeaconConfig.fromJson(config.toJson());

      expect(restored, config);
    });

    test('writes a schema version', () {
      final json = BeaconConfig.forMode(BeaconMode.strobe).toJson();
      expect(json['schemaVersion'], 1);
    });

    test('falls back to defaults for missing or invalid fields', () {
      final restored = BeaconConfig.fromJson(const {});

      expect(restored.pattern, FlashPattern.single);
      expect(restored.frequencyHz, 2);
      expect(restored.dutyCycle, 0.5);
      expect(restored.effect, ScreenEffect.strobe);
      expect(restored.sync, SyncMode.inPhase);
      expect(restored.torchEnabled, isTrue);
      expect(restored.screenEnabled, isTrue);
    });

    test('clamps out-of-range values from storage', () {
      final restored = BeaconConfig.fromJson(const {
        'frequencyHz': 99.0,
        'dutyCycle': 5.0,
        'brightness': 4.0,
      });

      expect(restored.frequencyHz, 10.0);
      expect(restored.dutyCycle, 0.95);
      expect(restored.brightness, 1.0);
    });

    test('ignores unknown enum names', () {
      final restored = BeaconConfig.fromJson(const {
        'pattern': 'not_a_pattern',
        'effect': 'not_an_effect',
      });

      expect(restored.pattern, FlashPattern.single);
      expect(restored.effect, ScreenEffect.strobe);
    });

    test('preserves colors through ARGB round-trip', () {
      final config = BeaconConfig.forMode(
        BeaconMode.screen,
      ).copyWith(primaryColor: const Color(0xFF123456));
      final restored = BeaconConfig.fromJson(config.toJson());
      expect(restored.primaryColor, const Color(0xFF123456));
    });
  });

  group('BeaconConfig.forMode', () {
    test('torch mode keeps the screen off', () {
      final config = BeaconConfig.forMode(BeaconMode.torch);
      expect(config.torchEnabled, isTrue);
      expect(config.screenEnabled, isFalse);
      expect(config.pattern, FlashPattern.steady);
    });

    test('screen mode keeps the torch off', () {
      final config = BeaconConfig.forMode(BeaconMode.screen);
      expect(config.torchEnabled, isFalse);
      expect(config.screenEnabled, isTrue);
    });

    test('strobe mode uses both outputs', () {
      final config = BeaconConfig.forMode(BeaconMode.strobe);
      expect(config.torchEnabled, isTrue);
      expect(config.screenEnabled, isTrue);
    });

    test('every mode stays within the safe frequency range', () {
      for (final mode in BeaconMode.values) {
        final config = BeaconConfig.forMode(mode);
        expect(config.frequencyHz, inInclusiveRange(0.5, 10.0));
        expect(config.dutyCycle, inInclusiveRange(0.05, 0.95));
      }
    });
  });

  group('AppSettings serialization', () {
    test('round-trips every field', () {
      const settings = AppSettings(
        localeCode: 'en',
        safetyAcknowledged: true,
        brightnessCap: 0.6,
        keepAwake: false,
      );

      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored, settings);
    });

    test('defaults to the system locale and unacknowledged safety', () {
      final restored = AppSettings.fromJson(const {});
      expect(restored.localeCode, isNull);
      expect(restored.safetyAcknowledged, isFalse);
      expect(restored.brightnessCap, 0.8);
      expect(restored.keepAwake, isTrue);
    });

    test('clearLocale resets to the system language', () {
      const settings = AppSettings(localeCode: 'it');
      expect(settings.copyWith(clearLocale: true).localeCode, isNull);
    });
  });

  group('Preset serialization', () {
    test('round-trips a custom preset', () {
      final preset = Preset(
        id: 'custom_1',
        customName: 'My beacon',
        config: BeaconConfig.forMode(BeaconMode.combo),
      );

      final restored = Preset.fromJson(preset.toJson());

      expect(restored.id, 'custom_1');
      expect(restored.customName, 'My beacon');
      expect(restored.config, preset.config);
      expect(restored.isBuiltIn, isFalse);
    });

    test('built-in presets are flagged and localized by key', () {
      final preset = Preset.fromJson(const {
        'id': 'pedestrian',
        'nameKey': 'presetPedestrian',
        'config': <String, Object?>{},
      });

      expect(preset.nameKey, 'presetPedestrian');
      expect(preset.isBuiltIn, isFalse);
    });
  });
}
