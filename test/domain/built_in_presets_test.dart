import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/domain/repositories/built_in_presets.dart';

void main() {
  group('BuiltInPresets', () {
    test('every preset has a unique id', () {
      final ids = BuiltInPresets.all.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every preset is flagged as built-in and has a name key', () {
      for (final preset in BuiltInPresets.all) {
        expect(preset.isBuiltIn, isTrue, reason: preset.id);
        expect(preset.nameKey, isNotNull, reason: preset.id);
        expect(preset.customName, isNull, reason: preset.id);
      }
    });

    test('no preset uses blue, which is reserved for emergency vehicles', () {
      for (final preset in BuiltInPresets.all) {
        expect(_isBlue(preset.config.primaryColor), isFalse, reason: preset.id);
        expect(_isBlue(preset.config.secondaryColor), isFalse, reason: preset.id);
      }
    });

    test('no preset exceeds the safe frequency range', () {
      for (final preset in BuiltInPresets.all) {
        expect(
          preset.config.frequencyHz,
          inInclusiveRange(0.5, 10.0),
          reason: preset.id,
        );
      }
    });

    test('the illuminate preset only uses the torch', () {
      expect(BuiltInPresets.illuminate.config.torchEnabled, isTrue);
      expect(BuiltInPresets.illuminate.config.screenEnabled, isFalse);
    });

    test('the emergency preset uses the SOS pattern', () {
      expect(BuiltInPresets.emergency.config.pattern, FlashPattern.sos);
    });
  });
}

bool _isBlue(Color color) {
  final hsv = HSVColor.fromColor(color);
  return hsv.hue >= 200 && hsv.hue <= 260 && hsv.saturation > 0.3;
}
