import 'dart:async';

/// Monotonic time source.
///
/// Injected into the beacon engine so timing logic can be tested without
/// waiting for real time to pass.
abstract class Clock {
  Duration get now;
}

/// Production clock backed by a [Stopwatch] (monotonic, unaffected by wall
/// clock changes).
class StopwatchClock implements Clock {
  StopwatchClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get now => _stopwatch.elapsed;
}

/// Controllable clock for tests.
class FakeClock implements Clock {
  Duration _now = Duration.zero;

  @override
  Duration get now => _now;

  void advance(Duration delta) => _now += delta;
}

/// Indirection over [Timer] so tests can drive edges manually.
typedef TimerFactory = Timer Function(Duration delay, void Function() callback);
