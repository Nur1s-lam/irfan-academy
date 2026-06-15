import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_time.dart';

class PrayerService {
  Future<PrayerSchedule> getTodayPrayerSchedule() async {
    final position = await _currentPosition();
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
    final qibla = Qibla(coordinates);

    return PrayerSchedule(
      latitude: position.latitude,
      longitude: position.longitude,
      locationLabel: _formatLocation(position),
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

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PrayerLocationException('Включите геолокацию на устройстве');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw PrayerLocationException('Разрешите доступ к местоположению');
    }

    if (permission == LocationPermission.deniedForever) {
      throw PrayerLocationException(
        'Геолокация запрещена. Откройте настройки приложения',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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

  String _formatLocation(Position position) {
    final lat = position.latitude.toStringAsFixed(3);
    final lon = position.longitude.toStringAsFixed(3);
    return '$lat, $lon';
  }
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
  PrayerLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
