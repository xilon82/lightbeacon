import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const SettingsPage(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsCard(
            children: [
              _SettingsTile(
                title: l10n.settingsLanguage,
                trailing: DropdownButton<String?>(
                  value: settings.localeCode,
                  dropdownColor: AppTheme.surfaceHigh,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.settingsLanguageSystem),
                    ),
                    DropdownMenuItem(
                      value: 'it',
                      child: Text(l10n.settingsLanguageItalian),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.settingsLanguageEnglish),
                    ),
                  ],
                  onChanged: notifier.setLocale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsTile(
                title: l10n.settingsBrightnessCap,
                subtitle: l10n.settingsBrightnessCapDesc,
                below: Slider(
                  value: settings.brightnessCap,
                  min: 0.3,
                  max: 1.0,
                  divisions: 14,
                  label: '${(settings.brightnessCap * 100).round()}%',
                  onChanged: notifier.setBrightnessCap,
                ),
              ),
              const Divider(color: AppTheme.outline, height: 1),
              SwitchListTile(
                value: settings.keepAwake,
                onChanged: notifier.setKeepAwake,
                title: Text(l10n.settingsKeepAwake),
                subtitle: Text(l10n.settingsKeepAwakeDesc),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              ListTile(
                title: Text(l10n.settingsSafety),
                subtitle: Text(l10n.settingsSafetyDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _SafetyReviewPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              ListTile(
                title: Text(l10n.settingsReset),
                trailing: const Icon(Icons.restart_alt),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceHigh,
                      content: Text(l10n.settingsResetConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.commonCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.commonReset),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await notifier.reset();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              l10n.settingsVersion('1.0.0'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: trailing,
        ),
        if (below != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: below,
          ),
      ],
    );
  }
}

class _SafetyReviewPage extends StatelessWidget {
  const _SafetyReviewPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSafety)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
    );
  }
}

/// Reusable safety block, shared by the onboarding and the settings review.
class SafetySection extends StatelessWidget {
  const SafetySection({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
