import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/engine/jitter_monitor.dart';

void main() {
  group('JitterMonitor', () {
    test('reports nothing until enough samples are collected', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 4; i++) {
        monitor.record(const Duration(milliseconds: 1));
      }
      expect(monitor.median, isNull);
      expect(monitor.p95, isNull);
      expect(monitor.isUnstable, isFalse);
    });

    test('median ignores the sign of the jitter', () {
      final monitor = JitterMonitor();
      for (final ms in [-2, 2, -2, 2, -2, 2, -2]) {
        monitor.record(Duration(milliseconds: ms));
      }
      expect(monitor.median, const Duration(milliseconds: 2));
    });

    test('flags instability above the threshold', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 40));
      }
      expect(monitor.isUnstable, isTrue);
    });

    test('stays stable below the threshold', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 3));
      }
      expect(monitor.isUnstable, isFalse);
    });

    test('keeps only the most recent window', () {
      final monitor = JitterMonitor(windowSize: 5);
      for (var i = 0; i < 20; i++) {
        monitor.record(const Duration(milliseconds: 1));
      }
      expect(monitor.sampleCount, 5);
    });

    test('suggests a lower frequency when jitter is high', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 60));
      }
      expect(monitor.suggestedMaxFrequency(10), lessThan(10));
    });

    test('keeps the requested frequency when jitter is low', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 1));
      }
      expect(monitor.suggestedMaxFrequency(2), 2);
    });

    test('reset clears the samples', () {
      final monitor = JitterMonitor();
      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 5));
      }
      monitor.reset();
      expect(monitor.sampleCount, 0);
      expect(monitor.median, isNull);
    });
  });
}
