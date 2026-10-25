import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/core/clock/clock.dart';
import 'package:light_beacon/domain/engine/beacon_engine.dart';
import 'package:light_beacon/domain/models/beacon_config.dart';

/// Deterministic timer harness: timers fire only when the test advances the
/// clock, which makes the drift compensation observable.
class _FakeScheduler {
  _FakeScheduler(this.clock);

  final FakeClock clock;
  final List<_PendingTimer> pending = <_PendingTimer>[];

  Timer schedule(Duration delay, void Function() callback) {
    final timer = _PendingTimer(clock.now + delay, callback);
    pending.add(timer);
    return timer;
  }

  /// Advances the clock by [delta], firing every timer that becomes due in
  /// chronological order.
  void advance(Duration delta) {
    final target = clock.now + delta;
    while (true) {
      pending.removeWhere((t) => t.cancelled);
      final due = pending.where((t) => t.dueAt <= target).toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
      if (due.isEmpty) break;
      final next = due.first;
      pending.remove(next);
      clock.advance(next.dueAt - clock.now);
      next.callback();
    }
    clock.advance(target - clock.now);
  }
}

class _PendingTimer implements Timer {
  _PendingTimer(this.dueAt, this.callback);

  final Duration dueAt;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

BeaconConfig _config({
  FlashPattern pattern = FlashPattern.single,
  double frequencyHz = 2,
  double dutyCycle = 0.5,
  bool torchEnabled = true,
  int timeoutMinutes = 0,
}) {
  return BeaconConfig(
    pattern: pattern,
    frequencyHz: frequencyHz,
    dutyCycle: dutyCycle,
    primaryColor: BeaconPalette.white,
    secondaryColor: BeaconPalette.amber,
    effect: ScreenEffect.strobe,
    brightness: 0.8,
    sync: SyncMode.inPhase,
    timeoutMinutes: timeoutMinutes,
    torchEnabled: torchEnabled,
    screenEnabled: true,
  );
}

void main() {
  late FakeClock clock;
  late _FakeScheduler scheduler;
  late List<bool> torchCalls;
  late BeaconEngine engine;

  setUp(() {
    clock = FakeClock();
    scheduler = _FakeScheduler(clock);
    torchCalls = <bool>[];
    engine = BeaconEngine(
      clock: clock,
      setTorch: (on) async => torchCalls.add(on),
      timerFactory: scheduler.schedule,
    );
  });

  tearDown(() => engine.dispose());

  test('steady pattern turns the torch on once and never toggles', () {
    engine.start(_config(pattern: FlashPattern.steady));
    scheduler.advance(const Duration(seconds: 5));

    expect(torchCalls, [true]);
    expect(engine.torchOn, isTrue);
  });

  test('single pulse at 2 Hz toggles twice per second', () {
    engine.start(_config(frequencyHz: 2, dutyCycle: 0.5));
    scheduler.advance(const Duration(seconds: 2));

    // Edges at 0, 250, 500, ... 2000 ms: the run starts on, so there is one
    // more "on" than "off" edge.
    expect(torchCalls.first, isTrue);
    expect(torchCalls.length, 9);
    expect(torchCalls.where((on) => on).length, 5);
    expect(torchCalls.where((on) => !on).length, 4);
  });

  test('duty cycle is honoured at frequencies other than 1 Hz', () {
    // Regression: offsets used to be scaled by a fixed second instead of the
    // cycle, so at 2 Hz a 40% duty became 80% on-time.
    engine.start(_config(frequencyHz: 2, dutyCycle: 0.4));

    final onAt = <Duration>[];
    final offAt = <Duration>[];
    var seen = 0;
    for (var i = 0; i < 150; i++) {
      scheduler.advance(const Duration(milliseconds: 10));
      while (seen < torchCalls.length) {
        (torchCalls[seen] ? onAt : offAt).add(clock.now);
        seen++;
      }
    }

    // 2 Hz cycle = 500 ms, 40% duty = 200 ms on, 300 ms off.
    expect(onAt.length, greaterThanOrEqualTo(3));
    expect(offAt.length, greaterThanOrEqualTo(3));

    final onDuration = offAt[1] - onAt[1];
    expect(
      onDuration.inMilliseconds,
      closeTo(200, 15),
      reason: 'on-time should be 40% of a 500 ms cycle',
    );

    final offDuration = onAt[2] - offAt[1];
    expect(
      offDuration.inMilliseconds,
      closeTo(300, 15),
      reason: 'off-time should be 60% of a 500 ms cycle',
    );
  });

  test('edges stay aligned to the absolute origin (no drift)', () {
    engine.start(_config(frequencyHz: 2, dutyCycle: 0.5));

    // Advance in irregular chunks; the engine must still schedule against
    // multiples of the 500 ms cycle.
    for (var i = 0; i < 40; i++) {
      scheduler.advance(const Duration(milliseconds: 137));
    }

    final median = engine.jitter.median;
    expect(median, isNotNull);
    expect(median!.inMilliseconds, lessThan(5));
  });

  test('stop turns the torch off and clears the origin', () {
    engine.start(_config(pattern: FlashPattern.steady));
    expect(engine.torchOn, isTrue);

    engine.stop();

    expect(engine.torchOn, isFalse);
    expect(engine.isRunning, isFalse);
    expect(engine.startedAt, isNull);
    expect(torchCalls.last, isFalse);
  });

  test('torch is never enabled when the config disables it', () {
    engine.start(_config(torchEnabled: false));
    scheduler.advance(const Duration(seconds: 2));

    expect(torchCalls, isEmpty);
    expect(engine.torchOn, isFalse);
  });

  test('timeout stops the beacon and notifies', () {
    var timedOut = false;
    engine.onTimeout = () => timedOut = true;

    engine.start(_config(timeoutMinutes: 1));
    scheduler.advance(const Duration(seconds: 59));
    expect(timedOut, isFalse);

    scheduler.advance(const Duration(seconds: 2));
    expect(timedOut, isTrue);
    expect(engine.isRunning, isFalse);
  });

  test('cosmetic config changes do not restart the cycle', () {
    engine.start(_config());
    scheduler.advance(const Duration(milliseconds: 300));
    final origin = engine.startedAt;

    engine.updateConfig(
      _config().copyWith(primaryColor: BeaconPalette.red),
    );

    expect(engine.startedAt, origin);
    expect(engine.isRunning, isTrue);
  });

  test('timing config changes restart the cycle', () {
    engine.start(_config());
    scheduler.advance(const Duration(milliseconds: 300));
    final origin = engine.startedAt;

    engine.updateConfig(_config(frequencyHz: 4));

    expect(engine.startedAt, isNot(origin));
    expect(engine.cycle, const Duration(milliseconds: 250));
  });

  test('torch errors are reported without stopping the engine', () async {
    final failing = BeaconEngine(
      clock: clock,
      setTorch: (on) async => throw StateError('camera busy'),
      timerFactory: scheduler.schedule,
    );
    Object? reported;
    failing.onError = (error) => reported = error;

    failing.start(_config(pattern: FlashPattern.steady));
    await Future<void>.delayed(Duration.zero);

    expect(reported, isA<StateError>());
    expect(failing.isRunning, isTrue);
    failing.dispose();
  });
}
