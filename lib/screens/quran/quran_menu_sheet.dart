import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class QuranReadingSettings {
  const QuranReadingSettings({
    required this.arabicFontSize,
    required this.showTranslation,
    required this.showTajweed,
    required this.reciter,
  });

  final double arabicFontSize;
  final bool showTranslation;
  final bool showTajweed;
  final String reciter;
}

class QuranBookmarkSelection {
  const QuranBookmarkSelection({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;
}

class QuranMenuSheet extends StatefulWidget {
  const QuranMenuSheet({
    super.key,
    required this.bookmarksStream,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBookmarkSelected,
  });

  final Stream<List<QuranBookmark>> bookmarksStream;
  final QuranReadingSettings settings;
  final ValueChanged<QuranReadingSettings> onSettingsChanged;
  final ValueChanged<QuranBookmarkSelection> onBookmarkSelected;

  @override
  State<QuranMenuSheet> createState() => _QuranMenuSheetState();
}

class _QuranMenuSheetState extends State<QuranMenuSheet> {
  late double _arabicFontSize;
  late bool _showTranslation;
  late bool _showTajweed;
  late String _reciter;

  @override
  void initState() {
    super.initState();
    _arabicFontSize = widget.settings.arabicFontSize;
    _showTranslation = widget.settings.showTranslation;
    _showTajweed = widget.settings.showTajweed;
    _reciter = widget.settings.reciter;
  }

  void _emitSettings() {
    widget.onSettingsChanged(
      QuranReadingSettings(
        arabicFontSize: _arabicFontSize,
        showTranslation: _showTranslation,
        showTajweed: _showTajweed,
        reciter: _reciter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.86,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Меню чтения',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: palette.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Закладки',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _BookmarksList(
                      stream: widget.bookmarksStream,
                      onSelected: widget.onBookmarkSelected,
                    ),
                    Divider(
                      height: 30,
                      color: palette.inkFaint.withValues(alpha: 0.16),
                    ),
                    Text(
                      'Настройки чтения',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Размер арабского текста',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Text(
                                '${_arabicFontSize.round()}px',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: palette.primaryDeep),
                              ),
                            ],
                          ),
                          Slider(
                            min: 20,
                            max: 36,
                            divisions: 16,
                            value: _arabicFontSize,
                            onChanged: (value) {
                              setState(() => _arabicFontSize = value);
                              _emitSettings();
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Показывать перевод'),
                            value: _showTranslation,
                            activeThumbColor: palette.primaryDeep,
                            onChanged: (value) {
                              setState(() => _showTranslation = value);
                              _emitSettings();
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Показывать таджвид'),
                            value: _showTajweed,
                            activeThumbColor: palette.primaryDeep,
                            onChanged: (value) {
                              setState(() => _showTajweed = value);
                              _emitSettings();
                            },
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _reciter,
                            decoration: const InputDecoration(
                              labelText: 'Чтец',
                            ),
                            items: [
                              for (final reciter
                                  in QuranAudioService.reciters.entries)
                                DropdownMenuItem(
                                  value: reciter.key,
                                  child: Text(reciter.value),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _reciter = value);
                              QuranAudioService.reciter = value;
                              _emitSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList({required this.stream, required this.onSelected});

  final Stream<List<QuranBookmark>> stream;
  final ValueChanged<QuranBookmarkSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return StreamBuilder<List<QuranBookmark>>(
      stream: stream,
      builder: (context, snapshot) {
        final bookmarks = snapshot.data ?? const <QuranBookmark>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(color: palette.primary),
            ),
          );
        }

        if (bookmarks.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              'У вас пока нет закладок',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < bookmarks.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              _BookmarkTile(
                bookmark: bookmarks[index],
                onSelected: onSelected,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.onSelected,
  });

  final QuranBookmark bookmark;
  final ValueChanged<QuranBookmarkSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final surah = QuranDataService.findSurahByTransliteration(
      bookmark.surahName,
    );
    final surahNumber = surah?.number ?? 1;
    final translation = QuranDataService.getVerseTranslation(
      surahNumber,
      bookmark.ayahNumber,
    );

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        onSelected(
          QuranBookmarkSelection(
            surahNumber: surahNumber,
            ayahNumber: bookmark.ayahNumber,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$surahNumber:${bookmark.ayahNumber}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.inkOnLight,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah?.nameTransliteration ?? bookmark.surahName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  translation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
