/// Position inside a flash cycle, expressed as a fraction in `[0, 1)`.
abstract final class PhaseCalculator {
  /// Phase of [elapsed] within [cycle].
  ///
  /// Returns 0 when the cycle is not positive, so callers never divide by zero.
  static double phaseAt(Duration elapsed, Duration cycle) {
    final cycleUs = cycle.inMicroseconds;
    if (cycleUs <= 0) return 0;
    final remainder = elapsed.inMicroseconds % cycleUs;
    return remainder / cycleUs;
  }

  /// Phase shifted by half a cycle, used for counter-phase sync.
  static double shifted(double phase) {
    final shifted = phase + 0.5;
    return shifted >= 1.0 ? shifted - 1.0 : shifted;
  }
}
