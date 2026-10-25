import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/engine/pattern.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';

void main() {
  group('PatternBuilder.segments', () {
    test('steady is a single always-on segment', () {
      final segments = PatternBuilder.segments(FlashPattern.steady, 0.5);
      expect(segments, hasLength(1));
      expect(segments.single.isOn, isTrue);
      expect(segments.single.fraction, 1.0);
    });

    test('segments always cover exactly one cycle', () {
      for (final pattern in FlashPattern.values) {
        for (final duty in [0.1, 0.3, 0.5, 0.9]) {
          final total = PatternBuilder.segments(pattern, duty)
              .fold<double>(0, (sum, s) => sum + s.fraction);
          expect(
            total,
            closeTo(1.0, 1e-9),
            reason: 'pattern=$pattern duty=$duty',
          );
        }
      }
    });

    test('on-time matches the requested duty cycle', () {
      for (final pattern in [
        FlashPattern.single,
        FlashPattern.double,
        FlashPattern.triple,
      ]) {
        for (final duty in [0.2, 0.4, 0.6]) {
          final onTime = PatternBuilder.segments(pattern, duty)
              .where((s) => s.isOn)
              .fold<double>(0, (sum, s) => sum + s.fraction);
          expect(onTime, closeTo(duty, 1e-9), reason: 'pattern=$pattern');
        }
      }
    });

    test('single pulse has one on and one off segment', () {
      final segments = PatternBuilder.segments(FlashPattern.single, 0.4);
      expect(segments, hasLength(2));
      expect(segments[0].isOn, isTrue);
      expect(segments[1].isOn, isFalse);
    });

    test('double and triple produce the requested number of pulses', () {
      expect(
        PatternBuilder.segments(FlashPattern.double, 0.4)
            .where((s) => s.isOn)
            .length,
        2,
      );
      expect(
        PatternBuilder.segments(FlashPattern.triple, 0.4)
            .where((s) => s.isOn)
            .length,
        3,
      );
    });

    test('SOS encodes three short, three long, three short', () {
      final segments = PatternBuilder.segments(FlashPattern.sos, 0.5);
      final onSegments = segments.where((s) => s.isOn).toList();
      expect(onSegments, hasLength(9));

      final units = onSegments.map((s) => (s.fraction * 34).round()).toList();
      expect(units, [1, 1, 1, 3, 3, 3, 1, 1, 1]);
    });

    test('duty cycle is clamped to a safe range', () {
      final tooLow = PatternBuilder.segments(FlashPattern.single, 0.0);
      final tooHigh = PatternBuilder.segments(FlashPattern.single, 1.0);
      expect(tooLow.first.fraction, closeTo(0.05, 1e-9));
      expect(tooHigh.first.fraction, closeTo(0.95, 1e-9));
    });
  });

  group('PatternBuilder.transitions', () {
    test('steady collapses to a single on transition', () {
      final transitions = PatternBuilder.transitions(FlashPattern.steady, 0.5);
      expect(transitions, hasLength(1));
      expect(transitions.single.isOn, isTrue);
    });

    test('single pulse yields on then off', () {
      final transitions = PatternBuilder.transitions(FlashPattern.single, 0.4);
      expect(transitions.map((s) => s.isOn).toList(), [true, false]);
    });

    test('SOS merges the trailing gap with the leading gap of the next cycle', () {
      final transitions = PatternBuilder.transitions(FlashPattern.sos, 0.5);
      // 9 pulses -> 9 on transitions, and the gaps between them merge into 8
      // off transitions. The trailing word gap is the last off segment.
      expect(transitions.where((s) => s.isOn).length, 9);
      expect(transitions.last.isOn, isFalse);
    });
  });

  group('PatternBuilder.isOnAt', () {
    final segments = PatternBuilder.segments(FlashPattern.single, 0.4);

    test('is on at the start of the cycle', () {
      expect(PatternBuilder.isOnAt(segments, 0.0), isTrue);
      expect(PatternBuilder.isOnAt(segments, 0.39), isTrue);
    });

    test('is off after the pulse', () {
      expect(PatternBuilder.isOnAt(segments, 0.4), isFalse);
      expect(PatternBuilder.isOnAt(segments, 0.99), isFalse);
    });

    test('wraps around the cycle', () {
      expect(PatternBuilder.isOnAt(segments, 1.0), isTrue);
      expect(PatternBuilder.isOnAt(segments, 1.6), isFalse);
    });
  });

  group('BeaconConfig.cycleDuration', () {
    test('derives the cycle from the frequency', () {
      const config = BeaconConfig(
        pattern: FlashPattern.single,
        frequencyHz: 2,
        dutyCycle: 0.5,
        primaryColor: BeaconPalette.white,
        secondaryColor: BeaconPalette.amber,
        effect: ScreenEffect.strobe,
        brightness: 0.8,
        sync: SyncMode.inPhase,
        timeoutMinutes: 0,
        torchEnabled: true,
        screenEnabled: true,
      );
      expect(config.cycleDuration, const Duration(milliseconds: 500));
    });

    test('SOS ignores the frequency slider', () {
      final config = BeaconConfig.forMode(BeaconMode.sos);
      expect(config.frequencyLocked, isTrue);
      expect(config.cycleDuration, const Duration(seconds: 7));
    });

    test('frequency is clamped to the supported range', () {
      final tooFast = BeaconConfig.forMode(
        BeaconMode.strobe,
      ).copyWith(frequencyHz: 50);
      expect(tooFast.cycleDuration, const Duration(milliseconds: 100));
    });
  });
}
