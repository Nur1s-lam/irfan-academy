import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/video_lesson.dart';
import 'cloudinary_video_service.dart';

class AdminService {
  AdminService({
    FirebaseFirestore? firestore,
    CloudinaryVideoService? videoStorage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       videoStorage = videoStorage ?? CloudinaryVideoService();

  static const allStudents = '__all_students__';
  final FirebaseFirestore _db;
  final CloudinaryVideoService videoStorage;

  Stream<List<UserProfile>> watchStudents() =>
      _db.collection('users').snapshots().map((snapshot) {
        final users =
            snapshot.docs
                .map(UserProfile.fromFirestore)
                .where((user) => !user.isAdmin)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        return users;
      });

  Stream<List<VideoLesson>> watchVideos() => _db
      .collection('videoLessons')
      .orderBy('number')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(VideoLesson.fromFirestore).toList());

  Future<void> saveVideo({
    required String title,
    required int number,
    required int totalSeconds,
    required String videoUrl,
    required String videoPath,
    required String fileName,
    required int fileSize,
    required String contentType,
    String description = '',
  }) async {
    await _db.collection('videoLessons').add({
      'title': title.trim(),
      'number': number,
      'totalSeconds': totalSeconds,
      'duration': _duration(totalSeconds),
      'videoUrl': videoUrl.trim(),
      'videoPath': videoPath.trim(),
      'fileName': fileName.trim(),
      'fileSize': fileSize,
      'contentType': contentType,
      'storageProvider': 'cloudinary',
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _notifyStudents(
      title: 'Новый видеоурок',
      message: 'Урок $number · ${title.trim()}',
      type: 'video',
    );
  }

  Future<void> deleteVideo(VideoLesson video) =>
      _db.collection('videoLessons').doc(video.id).delete();

  Future<void> addHomework({
    required String uid,
    required String task,
    required String subject,
    required String deadline,
  }) async {
    final targets = await _targetStudents(uid);
    await _writeForTargets(targets, (batch, user) {
      batch.set(user.collection('homework').doc(), {
        'task': task.trim(),
        'subject': subject.trim(),
        'deadline': deadline.trim(),
        'status': 'не_начато',
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _addNotification(
        batch,
        user,
        title: 'Новое домашнее задание',
        message: '${task.trim()} · срок: ${deadline.trim()}',
        type: 'homework',
      );
    });
  }

  Future<void> addLesson({
    required String uid,
    required String day,
    required String time,
    required int durationMin,
    required String type,
    required String topic,
    required String teacher,
  }) async {
    final targets = await _targetStudents(uid);
    await _writeForTargets(targets, (batch, user) {
      batch.set(user.collection('lessons').doc(), {
        'day': day.trim(),
        'time': time.trim(),
        'durationMin': durationMin,
        'type': type.trim(),
        'topic': topic.trim(),
        'teacher': teacher.trim(),
        'isSoon': false,
        'sortOrder': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _addNotification(
        batch,
        user,
        title: 'Назначен новый урок',
        message: '${day.trim()}, ${time.trim()} · ${topic.trim()}',
        type: 'lesson',
      );
    });
  }

  Future<void> publishAnnouncement({
    required String title,
    required String body,
  }) => _db.collection('announcements').add({
    'title': title.trim(),
    'body': body.trim(),
    'isPublished': true,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<List<DocumentReference<Map<String, dynamic>>>> _targetStudents(
    String uid,
  ) async {
    if (uid != allStudents) return [_db.collection('users').doc(uid)];
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .where((doc) => !UserProfile.fromFirestore(doc).isAdmin)
        .map((doc) => doc.reference)
        .toList();
  }

  Future<void> _notifyStudents({
    required String title,
    required String message,
    required String type,
  }) async {
    final targets = await _targetStudents(allStudents);
    await _writeForTargets(
      targets,
      (batch, user) => _addNotification(
        batch,
        user,
        title: title,
        message: message,
        type: type,
      ),
    );
  }

  void _addNotification(
    WriteBatch batch,
    DocumentReference<Map<String, dynamic>> user, {
    required String title,
    required String message,
    required String type,
  }) {
    batch.set(user.collection('notifications').doc(), {
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _writeForTargets(
    List<DocumentReference<Map<String, dynamic>>> targets,
    void Function(WriteBatch, DocumentReference<Map<String, dynamic>>) write,
  ) async {
    for (var start = 0; start < targets.length; start += 200) {
      final batch = _db.batch();
      for (final user in targets.skip(start).take(200)) {
        write(batch, user);
      }
      await batch.commit();
    }
  }

  String _duration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
