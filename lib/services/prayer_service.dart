import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_time.dart';

class PrayerService {
  static const _bishkekLatitude = 42.8746;
  static const _bishkekLongitude = 74.5698;
  static const _bishkekLabel = 'Бишкек';
  static const _locationTimeout = Duration(seconds: 5);

  Future<PrayerSchedule> getTodayPrayerSchedule() async {
    final location = await _currentLocationOrBishkek();
    final coordinates = Coordinates(location.latitude, location.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
    final qibla = Qibla(coordinates);

    return PrayerSchedule(
      latitude: location.latitude,
      longitude: location.longitude,
      locationLabel: location.label,
      qiblaDirection: qibla.direction,
      prayers: _withStatuses([
        _prayer('Фаджр', 'الفجر', prayerTimes.fajr),
        _prayer('Восход', 'الشروق', prayerTimes.sunrise, isFaint: true),
        _prayer('Зухр', 'الظهر', prayerTimes.dhuhr),
        _prayer('Аср', 'العصر', prayerTimes.asr),
        _prayer('Магриб', 'المغرب', prayerTimes.maghrib),
        _prayer('Иша', 'العشاء', prayerTimes.isha),
      ]),
    );
  }

  List<PrayerTime> updateStatuses(List<PrayerTime> prayers) {
    return _withStatuses(prayers);
  }

  PrayerTime getNextPrayer(List<PrayerTime> allPrayers) {
    final now = DateTime.now();
    for (final prayer in allPrayers) {
      final prayerTime = _parseTimeToday(prayer.time);
      if (!prayer.isFaint && prayerTime.isAfter(now)) {
        return prayer;
      }
    }
    return allPrayers.firstWhere(
      (prayer) => !prayer.isFaint,
      orElse: () => allPrayers.first,
    );
  }

  Duration getTimeUntilNextPrayer(PrayerTime nextPrayer) {
    final now = DateTime.now();
    var prayerDateTime = _parseTimeToday(nextPrayer.time);
    if (!prayerDateTime.isAfter(now)) {
      prayerDateTime = prayerDateTime.add(const Duration(days: 1));
    }
    return prayerDateTime.difference(now);
  }

  Future<_PrayerLocation> _currentLocationOrBishkek() async {
    try {
      return await _currentLocation().timeout(_locationTimeout);
    } catch (_) {
      return const _PrayerLocation(
        latitude: _bishkekLatitude,
        longitude: _bishkekLongitude,
        label: _bishkekLabel,
      );
    }
  }

  Future<_PrayerLocation> _currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
      _locationTimeout,
    );
    if (!serviceEnabled) {
      throw const PrayerLocationException('Геолокация выключена');
    }

    var permission = await Geolocator.checkPermission().timeout(
      _locationTimeout,
    );
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(
        _locationTimeout,
      );
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException('Нет доступа к геолокации');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      ),
    ).timeout(_locationTimeout);

    return _PrayerLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: _formatLocation(position),
    );
  }

  PrayerTime _prayer(
    String nameRu,
    String nameAr,
    DateTime dateTime, {
    bool isFaint = false,
  }) {
    return PrayerTime(
      nameRu: nameRu,
      nameAr: nameAr,
      time: _formatTime(dateTime),
      dateTime: dateTime,
      status: PrayerStatus.upcoming,
      isFaint: isFaint,
    );
  }

  List<PrayerTime> _withStatuses(List<PrayerTime> prayers) {
    final now = DateTime.now();
    final nextIndex = prayers.indexWhere((prayer) {
      return !prayer.isFaint && prayer.dateTime.isAfter(now);
    });

    return [
      for (var index = 0; index < prayers.length; index++)
        prayers[index].copyWith(
          status: _statusFor(prayers[index], index, nextIndex, now),
        ),
    ];
  }

  PrayerStatus _statusFor(
    PrayerTime prayer,
    int index,
    int nextIndex,
    DateTime now,
  ) {
    if (prayer.isFaint) {
      return PrayerStatus.faint;
    }
    if (index == nextIndex) {
      return PrayerStatus.next;
    }
    if (nextIndex == -1 || prayer.dateTime.isBefore(now)) {
      return PrayerStatus.done;
    }
    return PrayerStatus.upcoming;
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime _parseTimeToday(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatLocation(Position position) {
    final lat = position.latitude.toStringAsFixed(3);
    final lon = position.longitude.toStringAsFixed(3);
    return '$lat, $lon';
  }
}

class _PrayerLocation {
  const _PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.qiblaDirection,
    required this.prayers,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;
  final double qiblaDirection;
  final List<PrayerTime> prayers;

  PrayerSchedule copyWith({List<PrayerTime>? prayers}) {
    return PrayerSchedule(
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      qiblaDirection: qiblaDirection,
      prayers: prayers ?? this.prayers,
    );
  }
}

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
