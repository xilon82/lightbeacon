import 'dart:async';

import 'package:flutter/services.dart';

/// Reports whether the app window has focus.
///
/// Opening the notification shade does not pause the activity — it stays
/// resumed and Flutter never emits an `AppLifecycleState` change — so window
/// focus is the only signal that the beacon is covered by another window.
///
/// It matters because the system posts a notification on every torch state
/// change: with a flashing torch the notification shade visibly churns.
abstract class ForegroundController {
  /// Emits `false` when the app window loses focus, `true` when it returns.
  Stream<bool> get focusChanges;

  Future<void> dispose();
}

/// Implementation backed by the `MainActivity` window-focus hook.
class PluginForegroundController implements ForegroundController {
  PluginForegroundController() {
    _channel.setMethodCallHandler(_handleCall);
  }

  static const _channel = MethodChannel('lightbeacon/window_focus');
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Future<Object?> _handleCall(MethodCall call) async {
    if (call.method == 'windowFocusChanged' && call.arguments is bool) {
      _controller.add(call.arguments as bool);
    }
    return null;
  }

  @override
  Stream<bool> get focusChanges => _controller.stream;

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _controller.close();
  }
}

/// No-op implementation for tests and platforms without the native hook.
class NoopForegroundController implements ForegroundController {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Emits a focus change, exactly as the platform would.
  void emit({required bool focused}) => _controller.add(focused);

  @override
  Stream<bool> get focusChanges => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
