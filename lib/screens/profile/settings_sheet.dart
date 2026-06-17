import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/app_card.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Выйти из аккаунта?'),
          content: const Text('Вы точно хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !context.mounted) {
      return;
    }

    await AuthService().signOut();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomPadding),
      child: SafeArea(
        top: false,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.inkFaint.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Настройки',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: palette.inkSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Тёмная тема',
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.setDarkMode,
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Уведомления',
                    value: themeProvider.notificationsEnabled,
                    onChanged: themeProvider.setNotificationsEnabled,
                  ),
                  const _LanguageTile(),
                  Divider(
                    height: 24,
                    color: palette.inkFaint.withValues(alpha: 0.18),
                  ),
                  _SignOutTile(onTap: () => _confirmSignOut(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _SettingsIcon(icon: icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Switch(
        value: value,
        activeThumbColor: palette.primaryDeep,
        activeTrackColor: palette.primarySoft,
        inactiveThumbColor: palette.inkFaint,
        inactiveTrackColor: palette.border,
        onChanged: onChanged,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _SettingsIcon(icon: Icons.language_rounded),
      title: Text(
        'Язык интерфейса',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Text(
        'Русский',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: palette.primaryDeep,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _SettingsIcon(icon: Icons.logout_rounded, color: errorColor),
      title: Text(
        'Выйти из аккаунта',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: errorColor,
          fontWeight: FontWeight.w900,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.palette(context).primaryDeep;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}
