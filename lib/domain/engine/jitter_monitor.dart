import 'dart:math' as math;

/// Rolling statistics over the difference between the scheduled and the actual
/// moment a torch edge fired.
///
/// A large median means the platform cannot keep up with the requested
/// frequency, which is the signal used to warn the user and lower the rate.
class JitterMonitor {
  JitterMonitor({this.windowSize = 31});

  final int windowSize;
  final List<int> _samplesUs = <int>[];

  void record(Duration jitter) {
    _samplesUs.add(jitter.inMicroseconds);
    if (_samplesUs.length > windowSize) {
      _samplesUs.removeAt(0);
    }
  }

  void reset() => _samplesUs.clear();

  int get sampleCount => _samplesUs.length;

  /// Median absolute jitter, or `null` while there is not enough data.
  Duration? get median {
    if (_samplesUs.length < 5) return null;
    final sorted = _samplesUs.map((v) => v.abs()).toList()..sort();
    return Duration(microseconds: sorted[sorted.length ~/ 2]);
  }

  /// 95th percentile of the absolute jitter, or `null` while there is not
  /// enough data.
  Duration? get p95 {
    if (_samplesUs.length < 5) return null;
    final sorted = _samplesUs.map((v) => v.abs()).toList()..sort();
    final index = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
    return Duration(microseconds: sorted[index]);
  }

  /// True when the platform is consistently late enough to be noticeable.
  bool get isUnstable {
    final m = median;
    return m != null && m > const Duration(milliseconds: 15);
  }

  /// Suggested frequency cap given the observed jitter.
  ///
  /// Keeps at least ~20 ms of headroom per edge, which is roughly what a
  /// camera HAL needs to toggle the LED reliably.
  double suggestedMaxFrequency(double requestedHz) {
    final m = median;
    if (m == null) return requestedHz;
    final headroomUs = math.max(m.inMicroseconds * 4, 20000);
    final cap = 1000000 / (headroomUs * 2);
    return math.min(requestedHz, cap.clamp(0.5, 10.0));
  }
}
