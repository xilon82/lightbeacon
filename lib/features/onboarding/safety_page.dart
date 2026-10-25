import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../settings/settings_page.dart';

/// First-run safety notice.
///
/// The app deliberately exceeds the WCAG "three flashes" threshold, so the
/// user must acknowledge the risk before the beacon can be started.
class SafetyPage extends ConsumerWidget {
  const SafetyPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const SafetyPage(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                children: [
                  Text(
                    l10n.safetyTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  SafetySection(
                    icon: Icons.bolt,
                    title: l10n.safetyPhotosensitivityTitle,
                    body: l10n.safetyPhotosensitivityBody,
                  ),
                  SafetySection(
                    icon: Icons.directions_walk,
                    title: l10n.safetyRoadTitle,
                    body: l10n.safetyRoadBody,
                  ),
                  SafetySection(
                    icon: Icons.gavel,
                    title: l10n.safetyLawTitle,
                    body: l10n.safetyLawBody,
                  ),
                  SafetySection(
                    icon: Icons.battery_alert,
                    title: l10n.safetyBatteryTitle,
                    body: l10n.safetyBatteryBody,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: () =>
                    ref.read(settingsProvider.notifier).acknowledgeSafety(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.safetyAccept),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
