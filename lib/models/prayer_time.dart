enum PrayerStatus { done, next, upcoming, faint }

class PrayerTime {
  const PrayerTime({
    required this.nameRu,
    required this.nameAr,
    required this.time,
    required this.dateTime,
    required this.status,
    this.isFaint = false,
  });

  final String nameRu;
  final String nameAr;
  final String time;
  final DateTime dateTime;
  final PrayerStatus status;
  final bool isFaint;

  PrayerTime copyWith({PrayerStatus? status}) {
    return PrayerTime(
      nameRu: nameRu,
      nameAr: nameAr,
      time: time,
      dateTime: dateTime,
      status: status ?? this.status,
      isFaint: isFaint,
    );
  }
}
