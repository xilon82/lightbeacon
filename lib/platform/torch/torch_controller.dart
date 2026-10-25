import 'package:torch_light/torch_light.dart';

/// Result of a torch capability probe.
enum TorchAvailability { available, unavailable, unknown }

/// Seam over the torch hardware.
///
/// The MVP uses `torch_light` (one MethodChannel round-trip per toggle). When
/// the native strobe service lands, only this class changes: the engine, the
/// UI and the tests keep talking to the same interface.
abstract class TorchController {
  Future<TorchAvailability> checkAvailability();

  Future<void> setTorch(bool on);

  Future<void> dispose();
}

class PluginTorchController implements TorchController {
  TorchAvailability _availability = TorchAvailability.unknown;
  bool _isOn = false;

  @override
  Future<TorchAvailability> checkAvailability() async {
    if (_availability != TorchAvailability.unknown) return _availability;
    try {
      final available = await TorchLight.isTorchAvailable();
      _availability =
          available ? TorchAvailability.available : TorchAvailability.unavailable;
    } catch (_) {
      _availability = TorchAvailability.unavailable;
    }
    return _availability;
  }

  @override
  Future<void> setTorch(bool on) async {
    if (on == _isOn) return;
    if (on) {
      await TorchLight.enableTorch();
    } else {
      await TorchLight.disableTorch();
    }
    _isOn = on;
  }

  @override
  Future<void> dispose() async {
    if (!_isOn) return;
    _isOn = false;
    try {
      await TorchLight.disableTorch();
    } catch (_) {
      // The camera may already be released; nothing left to do.
    }
  }
}

/// No-op implementation used in tests and on platforms without a torch.
class NoopTorchController implements TorchController {
  NoopTorchController({this.availability = TorchAvailability.unavailable});

  final TorchAvailability availability;
  final List<bool> calls = <bool>[];

  @override
  Future<TorchAvailability> checkAvailability() async => availability;

  @override
  Future<void> setTorch(bool on) async => calls.add(on);

  @override
  Future<void> dispose() async {}
}
