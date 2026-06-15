import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.group,
    required this.role,
    required this.attendance,
    required this.lessonsCount,
    required this.streakDays,
    required this.quranProgress,
    required this.currentSura,
    required this.currentAyah,
  });

  final String uid;
  final String name;
  final String email;
  final String group;
  final String role;
  final int attendance;
  final int lessonsCount;
  final int streakDays;
  final double quranProgress;
  final String currentSura;
  final int currentAyah;

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      group: data['group'] ?? '',
      role: data['role'] ?? '',
      attendance: data['attendance'] ?? 0,
      lessonsCount: data['lessonsCount'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      quranProgress: (data['quranProgress'] ?? 0.0).toDouble(),
      currentSura: data['currentSura'] ?? 'Аль-Фатиха',
      currentAyah: data['currentAyah'] ?? 1,
    );
  }
}

class HomeworkItem {
  HomeworkItem({
    required this.id,
    required this.task,
    required this.subject,
    required this.deadline,
    required this.status,
    required this.isDone,
  });

  final String id;
  final String task;
  final String subject;
  final String deadline;
  final String status;
  bool isDone;

  factory HomeworkItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkItem(
      id: doc.id,
      task: data['task'] ?? '',
      subject: data['subject'] ?? '',
      deadline: data['deadline'] ?? '',
      status: data['status'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }
}
