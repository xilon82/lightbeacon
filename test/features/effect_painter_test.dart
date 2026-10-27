import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';
import 'package:light_beacon/features/beacon/effect_painter.dart';

/// Paints [config] at [phase] and returns the colour of the top-left pixel.
Future<Color> _paintTopLeft(BeaconConfig config, double phase) async {
  const size = Size(8, 8);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  EffectPainter(
    config: config,
    phase: phase,
    torchOn: true,
    reduceMotion: false,
  ).paint(canvas, size);

  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  return Color.fromARGB(bytes[3], bytes[0], bytes[1], bytes[2]);
}

void main() {
  group('EffectPainter', () {
    test('a steady pattern paints strobe as a solid primary fill', () async {
      final config = BeaconConfig.forMode(
        BeaconMode.combo,
      ).copyWith(effect: ScreenEffect.strobe);

      // Phase 0.5 would be "off" for a blinking pattern: without the fallback
      // the screen would go black instead of staying on the primary colour.
      expect(await _paintTopLeft(config, 0.5), config.primaryColor);
    });

    test('a steady pattern paints alternate as a solid primary fill', () async {
      final config = BeaconConfig.forMode(
        BeaconMode.combo,
      ).copyWith(effect: ScreenEffect.alternate);

      expect(await _paintTopLeft(config, 0.5), config.primaryColor);
    });

    test(
      'a blinking pattern still alternates between the two colours',
      () async {
        final config = BeaconConfig.forMode(
          BeaconMode.strobe,
        ).copyWith(effect: ScreenEffect.alternate, dutyCycle: 0.4);

        expect(await _paintTopLeft(config, 0.1), config.primaryColor);
        expect(await _paintTopLeft(config, 0.9), config.secondaryColor);
      },
    );
  });
}
