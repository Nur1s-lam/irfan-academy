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
  bool _open = false;
  double _right = 16;
  double _bottom = 96;

  static const double _buttonSize = 48;
  static const double _panelWidth = 280;

  void _drag(DragUpdateDetails details, Size screenSize) {
    final width = _open ? _panelWidth : _buttonSize;
    const minEdge = 8.0;
    final maxRight = screenSize.width - width - minEdge;
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
        child: AnimatedSwitcher(
          duration: AppTheme.motion,
          switchInCurve: AppTheme.motionCurve,
          switchOutCurve: AppTheme.motionCurve,
          child: _open
              ? _PanelCard(onClose: () => setState(() => _open = false))
              : _OpenButton(onTap: () => setState(() => _open = true)),
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
    return Material(
      key: const ValueKey('tweaks-open'),
      color: AppTheme.gold,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: AppTheme.goldDeep.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.settings_rounded, color: AppTheme.surface),
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
        return Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.14),
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
                    color: AppTheme.inkSoft,
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
                      color: AppTheme.goldDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.gold,
                  inactiveTrackColor: AppTheme.goldSoft,
                  thumbColor: AppTheme.goldDeep,
                  overlayColor: AppTheme.gold.withValues(alpha: 0.12),
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
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.inkSoft,
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
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      iconEnabledColor: AppTheme.goldDeep,
      dropdownColor: AppTheme.surface,
      underline: Container(height: 1, color: AppTheme.border),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.inkSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppTheme.gold,
          activeTrackColor: AppTheme.goldSoft,
          inactiveThumbColor: AppTheme.inkFaint,
          inactiveTrackColor: AppTheme.border,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
