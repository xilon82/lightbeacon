import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/engine/pattern.dart';
import '../../domain/models/beacon_config.dart';

/// Paints the screen effect for a given phase of the flash cycle.
///
/// The painter is a pure function of (config, phase, torchOn), which keeps it
/// deterministic and testable with golden files.
class EffectPainter extends CustomPainter {
  EffectPainter({
    required this.config,
    required this.phase,
    required this.torchOn,
    required this.reduceMotion,
  });

  final BeaconConfig config;
  final double phase;
  final bool torchOn;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final primary = config.primaryColor;
    final secondary = config.secondaryColor;

    switch (config.effect) {
      case ScreenEffect.solid:
        _fill(canvas, rect, primary);
      case ScreenEffect.pulse:
        final wave = reduceMotion ? 0.75 : 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
        _fill(canvas, rect, primary.withValues(alpha: 0.35 + 0.65 * wave));
      case ScreenEffect.strobe:
        final segments = PatternBuilder.segments(config.pattern, config.dutyCycle);
        final on = PatternBuilder.isOnAt(segments, phase);
        _fill(canvas, rect, on ? primary : Colors.black);
      case ScreenEffect.alternate:
        final segments = PatternBuilder.segments(config.pattern, config.dutyCycle);
        final on = PatternBuilder.isOnAt(segments, phase);
        _fill(canvas, rect, on ? primary : secondary);
      case ScreenEffect.sweep:
        _paintSweep(canvas, rect, primary, secondary);
      case ScreenEffect.rainbow:
        _paintRainbow(canvas, rect);
    }
  }

  void _fill(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _paintSweep(Canvas canvas, Rect rect, Color primary, Color secondary) {
    _fill(canvas, rect, secondary.withValues(alpha: 0.35));

    final travel = reduceMotion ? 0.5 : phase;
    final center = rect.width * (travel * 1.4 - 0.2);
    final band = rect.width * 0.45;

    final shader = LinearGradient(
      colors: [
        primary.withValues(alpha: 0.0),
        primary,
        primary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(
      Rect.fromLTWH(center - band / 2, 0, band, rect.height),
    );

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  void _paintRainbow(Canvas canvas, Rect rect) {
    final hue = (reduceMotion ? 0.0 : phase) * 360;
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSVColor.fromAHSV(1, hue % 360, 0.85, 1).toColor(),
        HSVColor.fromAHSV(1, (hue + 120) % 360, 0.85, 1).toColor(),
        HSVColor.fromAHSV(1, (hue + 240) % 360, 0.85, 1).toColor(),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(EffectPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.torchOn != torchOn ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.config != config;
}
