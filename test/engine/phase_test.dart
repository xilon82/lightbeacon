import 'package:flutter_test/flutter_test.dart';
import 'package:light_beacon/domain/engine/phase.dart';

void main() {
  group('PhaseCalculator.phaseAt', () {
    test('starts at zero', () {
      expect(PhaseCalculator.phaseAt(Duration.zero, const Duration(seconds: 1)), 0);
    });

    test('is proportional to elapsed time', () {
      expect(
        PhaseCalculator.phaseAt(
          const Duration(milliseconds: 250),
          const Duration(seconds: 1),
        ),
        closeTo(0.25, 1e-9),
      );
    });

    test('wraps every cycle', () {
      expect(
        PhaseCalculator.phaseAt(
          const Duration(milliseconds: 1250),
          const Duration(seconds: 1),
        ),
        closeTo(0.25, 1e-9),
      );
    });

    test('returns zero for a non-positive cycle', () {
      expect(PhaseCalculator.phaseAt(const Duration(seconds: 3), Duration.zero), 0);
    });
  });

  group('PhaseCalculator.shifted', () {
    test('shifts by half a cycle', () {
      expect(PhaseCalculator.shifted(0.0), closeTo(0.5, 1e-9));
      expect(PhaseCalculator.shifted(0.25), closeTo(0.75, 1e-9));
    });

    test('wraps past one', () {
      expect(PhaseCalculator.shifted(0.75), closeTo(0.25, 1e-9));
      expect(PhaseCalculator.shifted(0.5), closeTo(0.0, 1e-9));
    });
  });
}
