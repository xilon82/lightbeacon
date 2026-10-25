import '../models/beacon_config.dart';

/// One slice of a flash cycle, expressed as a fraction of the whole cycle.
class PatternSegment {
  const PatternSegment(this.fraction, {required this.isOn});

  final double fraction;
  final bool isOn;

  @override
  String toString() =>
      'PatternSegment(${fraction.toStringAsFixed(4)}, on: $isOn)';
}

/// Turns a [FlashPattern] plus a duty cycle into cycle segments.
///
/// Segments are fractions of the cycle, never absolute durations, so changing
/// the frequency rescales the whole pattern consistently.
abstract final class PatternBuilder {
  /// SOS timing in Morse units: dot = 1, dash = 3, intra-letter gap = 1,
  /// letter gap = 3, word gap = 7. Total = 34 units.
  static const _sosUnits = <int>[1, 1, 1, 1, 1, 3, 3, 1, 3, 1, 3, 3, 1, 1, 1, 1, 1, 7];
  static const _sosTotalUnits = 34;

  /// Full segment list for one cycle, including consecutive segments with the
  /// same state.
  static List<PatternSegment> segments(
    FlashPattern pattern,
    double dutyCycle,
  ) {
    final duty = dutyCycle.clamp(0.05, 0.95);
    switch (pattern) {
      case FlashPattern.steady:
        return const [PatternSegment(1.0, isOn: true)];
      case FlashPattern.sos:
        return _sosSegments();
      case FlashPattern.single:
        return _pulseSegments(1, duty);
      case FlashPattern.double:
        return _pulseSegments(2, duty);
      case FlashPattern.triple:
        return _pulseSegments(3, duty);
    }
  }

  /// Only the points where the state changes, which is what the torch needs.
  ///
  /// Consecutive segments with the same state are merged, so a `steady`
  /// pattern yields a single "on" transition at offset 0.
  static List<PatternSegment> transitions(
    FlashPattern pattern,
    double dutyCycle,
  ) {
    final all = segments(pattern, dutyCycle);
    final merged = <PatternSegment>[];
    for (final segment in all) {
      if (merged.isNotEmpty && merged.last.isOn == segment.isOn) {
        merged[merged.length - 1] = PatternSegment(
          merged.last.fraction + segment.fraction,
          isOn: segment.isOn,
        );
      } else {
        merged.add(segment);
      }
    }
    return merged;
  }

  /// Whether the pattern is "on" at [phase] (0.0 - 1.0).
  static bool isOnAt(List<PatternSegment> segments, double phase) {
    if (segments.isEmpty) return false;
    final p = phase % 1.0;
    var accumulated = 0.0;
    for (final segment in segments) {
      accumulated += segment.fraction;
      if (p < accumulated) return segment.isOn;
    }
    return segments.last.isOn;
  }

  static List<PatternSegment> _pulseSegments(int pulses, double duty) {
    final onEach = duty / pulses;
    final offTotal = 1.0 - duty;

    if (pulses == 1) {
      return [
        PatternSegment(onEach, isOn: true),
        PatternSegment(offTotal, isOn: false),
      ];
    }

    // Inter-pulse gaps take a minority of the off time so a double/triple
    // flash reads as one burst rather than as a faster single flash.
    const interShare = 0.35;
    final interEach = offTotal * interShare / (pulses - 1);
    final trailing = offTotal * (1.0 - interShare);

    final out = <PatternSegment>[];
    for (var i = 0; i < pulses; i++) {
      out.add(PatternSegment(onEach, isOn: true));
      if (i < pulses - 1) {
        out.add(PatternSegment(interEach, isOn: false));
      }
    }
    out.add(PatternSegment(trailing, isOn: false));
    return out;
  }

  static List<PatternSegment> _sosSegments() {
    final out = <PatternSegment>[];
    for (var i = 0; i < _sosUnits.length; i++) {
      out.add(
        PatternSegment(
          _sosUnits[i] / _sosTotalUnits,
          isOn: i.isEven,
        ),
      );
    }
    return out;
  }
}
