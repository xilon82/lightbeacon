import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/engine/beacon_engine.dart';
import '../../domain/engine/phase.dart';
import '../../domain/models/beacon_config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import 'beacon_labels.dart';
import 'control_sheet.dart';
import 'effect_painter.dart';

/// Fullscreen beacon.
///
/// The screen is driven by a [Ticker] that recomputes the phase from the
/// engine's origin, so the visual stays locked to the torch even if a frame is
/// dropped. The torch itself is driven by the engine, never by this widget.
class BeaconPage extends ConsumerStatefulWidget {
  const BeaconPage({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const BeaconPage(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  @override
  ConsumerState<BeaconPage> createState() => _BeaconPageState();
}

class _BeaconPageState extends ConsumerState<BeaconPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final BeaconEngine _engine;
  late final Clock _clock;
  double _phase = 0;
  bool _hudVisible = true;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    // Resolved once: reading providers on every frame would break as soon as
    // the container is disposed while the ticker is still alive.
    _engine = ref.read(beaconSessionProvider.notifier).engine;
    _clock = ref.read(clockProvider);
    _ticker = createTicker(_onTick)..start();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onTick(Duration _) {
    final origin = _engine.startedAt;
    if (origin == null) return;
    final elapsed = _clock.now - origin;
    final next = PhaseCalculator.phaseAt(elapsed, _engine.cycle);
    if ((next - _phase).abs() > 0.0005) {
      setState(() => _phase = next);
    }
  }

  Future<void> _stop() async {
    if (_stopping) return;
    _stopping = true;
    await ref.read(beaconSessionProvider.notifier).stop();
    if (!mounted) return;
    // `pop()` is unconditional: `maybePop()` would be intercepted by the
    // PopScope below and re-enter this method forever.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(beaconConfigProvider);
    final session = ref.watch(beaconSessionProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = context.l10n;

    final screenPhase = switch (config.sync) {
      SyncMode.inPhase => _phase,
      SyncMode.counterPhase => PhaseCalculator.shifted(_phase),
      SyncMode.independent => _phase,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _hudVisible = !_hudVisible),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (config.screenEnabled)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: EffectPainter(
                      config: config,
                      phase: screenPhase,
                      torchOn: session.running,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                )
              else
                const ColoredBox(color: Colors.black),
              if (_hudVisible) _buildHud(context, config, session, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud(
    BuildContext context,
    BeaconConfig config,
    BeaconSessionState session,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _HudPill(
                  icon: Icons.bolt,
                  label: config.frequencyLocked
                      ? l10n.patternSos
                      : l10n.controlFrequencyValue(
                          config.frequencyHz.toStringAsFixed(1),
                        ),
                ),
                const SizedBox(width: 8),
                _HudPill(
                  icon: Icons.palette_outlined,
                  label: BeaconLabels.effect(context, config.effect),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => ControlSheet.show(context),
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.beaconControls,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      AppTheme.minTouchTarget,
                      AppTheme.minTouchTarget,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (!session.torchAvailable && config.torchEnabled)
              _HudBanner(
                icon: Icons.flash_off,
                text: l10n.beaconTorchUnavailable,
              ),
            if (session.jitterWarning)
              _HudBanner(
                icon: Icons.speed,
                text: l10n.beaconJitterWarning,
              ),
            if (session.error != null)
              _HudBanner(icon: Icons.error_outline, text: l10n.beaconTorchError),
            const Spacer(),
            FilledButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: Text(l10n.beaconStop),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(64),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudBanner extends StatelessWidget {
  const _HudBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
