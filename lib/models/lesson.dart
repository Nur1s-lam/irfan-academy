import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  const Lesson({
    this.id = '',
    this.day = '',
    required this.time,
    required this.durationMin,
    required this.type,
    required this.topic,
    required this.teacher,
    required this.isSoon,
  });

  final String id;
  final String day;
  final String time;
  final int durationMin;
  final String type;
  final String topic;
  final String teacher;
  final bool isSoon;

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Lesson(
      id: doc.id,
      day: data['day'] ?? '',
      time: data['time'] ?? '',
      durationMin: data['durationMin'] ?? 0,
      type: data['type'] ?? '',
      topic: data['topic'] ?? '',
      teacher: data['teacher'] ?? '',
      isSoon: data['isSoon'] ?? false,
    );
  }
}
