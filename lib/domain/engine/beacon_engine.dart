import 'dart:async';

import '../../core/clock/clock.dart';
import '../models/beacon_config.dart';
import 'jitter_monitor.dart';
import 'pattern.dart';

/// Drives the torch edges of a running beacon.
///
/// The screen is *not* driven from here: the widget reads [startedAt] and
/// computes its own phase from the render ticker, so a slow frame never
/// delays a flash.
///
/// Edges are always scheduled against an absolute origin
/// (`startedAt + n * cycle + offset`) instead of accumulating `sleep(period)`
/// delays, so timer jitter never drifts the pattern.
class BeaconEngine {
  BeaconEngine({
    required this.clock,
    required this.setTorch,
    TimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final Clock clock;

  /// Applies the torch state. Errors are reported through [onError] and do not
  /// stop the engine, so the screen keeps working on devices without a torch.
  final Future<void> Function(bool on) setTorch;

  final TimerFactory _timerFactory;

  final JitterMonitor jitter = JitterMonitor();

  void Function(bool on)? onTorchChanged;
  void Function()? onTimeout;
  void Function(Object error)? onError;

  BeaconConfig? _config;
  Duration? _startedAt;
  Duration _cycle = const Duration(seconds: 1);
  List<PatternSegment> _transitions = const [];
  List<int> _edgeOffsetsUs = const [];
  int _cycleIndex = 0;
  int _edgeIndex = 0;
  Timer? _edgeTimer;
  Timer? _timeoutTimer;
  bool _running = false;
  bool _torchOn = false;

  bool get isRunning => _running;

  /// Origin of the current run, used by the screen to compute its phase.
  Duration? get startedAt => _startedAt;

  Duration get cycle => _cycle;

  bool get torchOn => _torchOn;

  void start(BeaconConfig config) {
    stop();
    _config = config;
    _cycle = config.cycleDuration;
    _transitions = PatternBuilder.transitions(config.pattern, config.dutyCycle);
    _edgeOffsetsUs = _cumulativeOffsets(_transitions, _cycle);
    _startedAt = clock.now;
    _cycleIndex = 0;
    _edgeIndex = 0;
    _running = true;
    jitter.reset();

    _applyTorch(config.torchEnabled && _transitions.first.isOn);

    if (config.torchEnabled && _transitions.length > 1) {
      _advance();
      _scheduleNextEdge();
    }

    if (config.timeoutMinutes > 0) {
      _timeoutTimer = _timerFactory(
        Duration(minutes: config.timeoutMinutes),
        () {
          if (!_running) return;
          stop();
          onTimeout?.call();
        },
      );
    }
  }

  /// Applies a new configuration.
  ///
  /// Timing-relevant changes restart the cycle origin (a visible but
  /// predictable hiccup); cosmetic changes are applied in place.
  void updateConfig(BeaconConfig config) {
    final previous = _config;
    if (!_running || previous == null) {
      _config = config;
      return;
    }

    final timingChanged =
        previous.pattern != config.pattern ||
        previous.frequencyHz != config.frequencyHz ||
        previous.dutyCycle != config.dutyCycle ||
        previous.torchEnabled != config.torchEnabled ||
        previous.timeoutMinutes != config.timeoutMinutes;

    if (timingChanged) {
      start(config);
      return;
    }

    _config = config;
  }

  void stop() {
    _edgeTimer?.cancel();
    _edgeTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _running = false;
    _startedAt = null;
    _applyTorch(false);
  }

  void dispose() {
    stop();
    onTorchChanged = null;
    onTimeout = null;
    onError = null;
  }

  void _advance() {
    _edgeIndex++;
    if (_edgeIndex >= _transitions.length) {
      _edgeIndex = 0;
      _cycleIndex++;
    }
  }

  void _scheduleNextEdge() {
    _edgeTimer?.cancel();
    if (!_running) return;

    final origin = _startedAt;
    if (origin == null) return;

    final target = _targetFor(_cycleIndex, _edgeIndex);
    final delay = target - clock.now;

    if (delay.isNegative) {
      // We fell behind by at least one edge: resynchronise instead of
      // replaying the missed edges back to back.
      _resync(origin);
      return;
    }

    _edgeTimer = _timerFactory(delay, _onEdge);
  }

  void _onEdge() {
    if (!_running) return;
    final origin = _startedAt;
    if (origin == null) return;

    final target = _targetFor(_cycleIndex, _edgeIndex);
    jitter.record(clock.now - target);

    _applyTorch(_transitions[_edgeIndex].isOn);
    _advance();
    _scheduleNextEdge();
  }

  void _resync(Duration origin) {
    final now = clock.now;
    final cycleUs = _cycle.inMicroseconds;
    if (cycleUs <= 0) return;

    final elapsedUs = now.inMicroseconds - origin.inMicroseconds;
    var cycle = elapsedUs ~/ cycleUs;
    var edge = 0;
    while (edge < _edgeOffsetsUs.length) {
      final t = cycle * cycleUs + _edgeOffsetsUs[edge];
      if (t > elapsedUs) break;
      edge++;
    }
    if (edge >= _edgeOffsetsUs.length) {
      edge = 0;
      cycle++;
    }

    _cycleIndex = cycle;
    _edgeIndex = edge;
    _applyTorch(_transitions[_edgeIndex].isOn);
    _advance();
    _scheduleNextEdge();
  }

  Duration _targetFor(int cycleIndex, int edgeIndex) {
    final origin = _startedAt ?? Duration.zero;
    return origin +
        Duration(
          microseconds:
              cycleIndex * _cycle.inMicroseconds + _edgeOffsetsUs[edgeIndex],
        );
  }

  void _applyTorch(bool on) {
    if (_torchOn == on) return;
    _torchOn = on;
    onTorchChanged?.call(on);
    try {
      setTorch(on).catchError((Object error) {
        onError?.call(error);
      });
    } catch (error) {
      onError?.call(error);
    }
  }

  /// Converts segment fractions into microsecond offsets inside [cycle].
  ///
  /// The fractions are relative to the cycle, not to a second: scaling by a
  /// fixed 1e6 would make the duty cycle wrong at any frequency other than
  /// 1 Hz.
  static List<int> _cumulativeOffsets(
    List<PatternSegment> segments,
    Duration cycle,
  ) {
    final cycleUs = cycle.inMicroseconds;
    final offsets = <int>[];
    var accumulated = 0.0;
    for (final segment in segments) {
      offsets.add((accumulated * cycleUs).round());
      accumulated += segment.fraction;
    }
    return offsets;
  }
}
