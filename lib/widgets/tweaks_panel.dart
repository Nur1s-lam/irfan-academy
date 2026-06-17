import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class TweaksPanel extends StatefulWidget {
  const TweaksPanel({super.key});

  @override
  State<TweaksPanel> createState() => _TweaksPanelState();
}

class _TweaksPanelState extends State<TweaksPanel> {
  double _right = 16;
  double _bottom = 96;

  static const double _buttonSize = 48;

  void _drag(DragUpdateDetails details, Size screenSize) {
    const minEdge = 8.0;
    final maxRight = screenSize.width - _buttonSize - minEdge;
    final maxBottom = screenSize.height - _buttonSize - minEdge;

    setState(() {
      _right = (_right - details.delta.dx).clamp(minEdge, maxRight);
      _bottom = (_bottom - details.delta.dy).clamp(minEdge, maxBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: GestureDetector(
        onPanUpdate: (details) => _drag(details, screenSize),
        child: _OpenButton(onTap: () => _showTweaksSheet(context)),
      ),
    );
  }

  void _showTweaksSheet(BuildContext context) {
    final palette = AppTheme.palette(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: palette.ink.withValues(alpha: 0.42),
      builder: (context) {
        return _TweaksSheet(
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _TweaksSheet extends StatelessWidget {
  const _TweaksSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              _PanelCard(onClose: onClose),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Material(
      key: const ValueKey('tweaks-open'),
      color: palette.primary,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: palette.primaryDeep.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.settings_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      key: const ValueKey('tweaks-panel'),
      builder: (context, themeProvider, _) {
        final palette = AppTheme.palette(context);

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.ink.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Настройки дизайна',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: palette.inkSoft,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FieldLabel('Стиль приложения'),
              _Dropdown(
                value: themeProvider.appStyle,
                items: const {
                  'classic': 'Классик',
                  'minimal': 'Минимал',
                  'warm': 'Тёплый',
                },
                onChanged: themeProvider.setStyle,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: _FieldLabel('Количество золота')),
                  Text(
                    '${(themeProvider.goldIntensity * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.primaryDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.primary,
                  inactiveTrackColor: palette.primarySoft,
                  thumbColor: palette.primaryDeep,
                  overlayColor: palette.primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: themeProvider.goldIntensity,
                  min: 0,
                  max: 1,
                  onChanged: themeProvider.setGoldIntensity,
                ),
              ),
              _SwitchRow(
                label: 'Геометрический узор',
                value: themeProvider.showPattern,
                onChanged: (_) => themeProvider.togglePattern(),
              ),
              const SizedBox(height: 12),
              _FieldLabel('Шрифт заголовков'),
              _Dropdown(
                value: themeProvider.headingFont,
                items: const {
                  'Cormorant Garamond': 'Cormorant Garamond',
                  'Marcellus': 'Marcellus',
                  'Playfair Display': 'Playfair Display',
                },
                onChanged: themeProvider.setHeadingFont,
              ),
              const SizedBox(height: 12),
              _SwitchRow(
                label: 'Стартовый экран',
                value: themeProvider.showSplash,
                onChanged: (_) => themeProvider.toggleSplash(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: palette.inkSoft,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = items.containsKey(value);
    final palette = AppTheme.palette(context);

    return DropdownButton<String>(
      value: hasValue ? value : items.keys.first,
      isExpanded: true,
      iconEnabledColor: palette.primaryDeep,
      dropdownColor: palette.surface,
      underline: Container(height: 1, color: palette.border),
      items: [
        for (final item in items.entries)
          DropdownMenuItem(value: item.key, child: Text(item.value)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.inkSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: palette.primary,
          activeTrackColor: palette.primarySoft,
          inactiveThumbColor: palette.inkFaint,
          inactiveTrackColor: palette.border,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
