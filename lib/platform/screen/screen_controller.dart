import 'package:screen_brightness/screen_brightness.dart';

/// Seam over the display brightness.
///
/// Only the *application* brightness is touched, so no system permission is
/// needed and the user's setting is restored when the beacon stops.
abstract class ScreenController {
  Future<void> applyBrightness(double value);

  Future<void> restore();

  Future<void> dispose();
}

class PluginScreenController implements ScreenController {
  double? _applied;

  @override
  Future<void> applyBrightness(double value) async {
    final clamped = value.clamp(0.05, 1.0);
    if (_applied != null && (_applied! - clamped).abs() < 0.01) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(clamped);
      _applied = clamped;
    } catch (_) {
      // Brightness control is a nicety: never let it break the beacon.
    }
  }

  @override
  Future<void> restore() async {
    if (_applied == null) return;
    _applied = null;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // Ignore: the OS restores the value when the activity is destroyed.
    }
  }

  @override
  Future<void> dispose() => restore();
}

/// No-op implementation for tests.
class NoopScreenController implements ScreenController {
  final List<double> applied = <double>[];
  int restoreCount = 0;

  @override
  Future<void> applyBrightness(double value) async => applied.add(value);

  @override
  Future<void> restore() async => restoreCount++;

  @override
  Future<void> dispose() async {}
}
