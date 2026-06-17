import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/surah.dart';
import '../../services/quran_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class QuranSearchResult {
  const QuranSearchResult({
    required this.surah,
    required this.ayahNumber,
    required this.translation,
  });

  final SurahInfo surah;
  final int ayahNumber;
  final String translation;
}

class QuranSearchSheet extends StatefulWidget {
  const QuranSearchSheet({
    super.key,
    required this.surahs,
    required this.onSelected,
  });

  final List<SurahInfo> surahs;
  final ValueChanged<QuranSearchResult> onSelected;

  @override
  State<QuranSearchSheet> createState() => _QuranSearchSheetState();
}

class _QuranSearchSheetState extends State<QuranSearchSheet> {
  Timer? _debounce;
  String _query = '';
  List<QuranSearchResult> _results = const [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  void _search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    setState(() {
      _query = query;
      _isSearching = query.length >= 2;
    });

    if (query.length < 2) {
      setState(() {
        _results = const [];
        _isSearching = false;
      });
      return;
    }

    final results = <QuranSearchResult>[];
    for (final surah in widget.surahs) {
      final surahMatches =
          surah.nameTransliteration.toLowerCase().contains(query) ||
          surah.nameTranslation.toLowerCase().contains(query) ||
          surah.nameArabic.contains(query) ||
          surah.number.toString() == query;

      for (var ayah = 1; ayah <= surah.versesCount; ayah++) {
        final translation = QuranDataService.getVerseTranslation(
          surah.number,
          ayah,
        );
        if (surahMatches || translation.toLowerCase().contains(query)) {
          results.add(
            QuranSearchResult(
              surah: surah,
              ayahNumber: ayah,
              translation: translation,
            ),
          );
        }
        if (results.length >= 80) {
          break;
        }
      }
      if (results.length >= 80) {
        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _results = results;
      _isSearching = false;
    });
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
                      'Поиск по Корану',
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
              TextField(
                autofocus: true,
                onChanged: _onQueryChanged,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите слово или название суры',
                  prefixIcon: Icon(Icons.search_rounded, color: palette.inkSoft),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _SearchResults(
                  query: _query,
                  results: _results,
                  isSearching: _isSearching,
                  onSelected: widget.onSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.isSearching,
    required this.onSelected,
  });

  final String query;
  final List<QuranSearchResult> results;
  final bool isSearching;
  final ValueChanged<QuranSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    if (isSearching) {
      return Center(child: CircularProgressIndicator(color: palette.primary));
    }

    if (query.length < 2) {
      return Center(
        child: Text(
          'Введите минимум 2 символа',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = results[index];
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: () => onSelected(result),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.surah.number}:${result.ayahNumber} · ${result.surah.nameTransliteration}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.primaryDeep,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _HighlightedText(text: result.translation, query: query),
            ],
          ),
        );
      },
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final source = text;
    final lower = source.toLowerCase();
    final index = lower.indexOf(query.toLowerCase());

    if (index < 0) {
      return Text(source, style: Theme.of(context).textTheme.bodyMedium);
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: source.substring(0, index)),
          TextSpan(
            text: source.substring(index, index + query.length),
            style: TextStyle(
              color: AppTheme.inkOnLight,
              backgroundColor: palette.primarySoft,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: source.substring(index + query.length)),
        ],
      ),
    );
  }
}
