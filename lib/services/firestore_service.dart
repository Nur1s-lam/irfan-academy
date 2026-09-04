import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson.dart';
import '../models/user_profile.dart';
import '../models/video_lesson.dart';

class QuranBookmark {
  const QuranBookmark({required this.ayahNumber, required this.surahName});

  final int ayahNumber;
  final String surahName;
}

class AcademyNotification {
  const AcademyNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  factory AcademyNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AcademyNotification(
      id: doc.id,
      title: data['title']?.toString() ?? 'Уведомление',
      message: data['message']?.toString() ?? '',
      type: data['type']?.toString() ?? 'info',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] == true,
    );
  }
}

class FirestoreService {
  FirestoreService(this.uid);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  Future<void> createUserProfile({
    required String name,
    required String email,
  }) async {
    await _userDoc.set({
      'name': name.trim(),
      'email': email.trim(),
      'group': 'Группа Хифз-2',
      'role': 'Ученик',
      'attendance': 0,
      'lessonsCount': 0,
      'streakDays': 0,
      'quranProgress': 0.0,
      'currentSura': 'Аль-Фатиха',
      'currentAyah': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserProfile?> getUserProfile() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserProfile.fromFirestore(doc);
    });
  }

  Stream<List<AcademyNotification>> getNotifications() {
    return _userDoc
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AcademyNotification.fromFirestore).toList(),
        );
  }

  Stream<List<VideoLesson>> getVideoLessons() => _db
      .collection('videoLessons')
      .orderBy('number')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(VideoLesson.fromFirestore).toList());

  Future<void> markNotificationsRead() async {
    final unread = await _userDoc
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> updateQuranProgress(double progress, String sura, int ayah) {
    return _userDoc.update({
      'quranProgress': progress,
      'currentSura': sura,
      'currentAyah': ayah,
    });
  }

  CollectionReference<Map<String, dynamic>> get _homeworkCol =>
      _userDoc.collection('homework');

  Stream<List<HomeworkItem>> getHomework() {
    const legacyDemoTasks = {
      'Повторить Суру Аль-Фатиха наизусть',
      'Прописать буквы с харакятами (с. 12–14)',
      'Прослушать урок №12 «Правила Мадд»',
    };
    return _homeworkCol
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(HomeworkItem.fromFirestore)
              .where((item) => !legacyDemoTasks.contains(item.task))
              .toList(),
        );
  }

  Future<void> updateHomeworkStatus(String docId, bool isDone) {
    return _homeworkCol.doc(docId).update({
      'isDone': isDone,
      'status': isDone ? 'выполнено' : 'в_процессе',
    });
  }

  Future<void> initDefaultHomework() async {
    final snap = await _homeworkCol.limit(1).get();
    if (snap.docs.isNotEmpty) {
      return;
    }

    final defaults = [
      {
        'task': 'Повторить Суру Аль-Фатиха наизусть',
        'subject': 'Хифз',
        'deadline': 'сегодня',
        'status': 'в_процессе',
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'task': 'Прописать буквы с харакятами (с. 12–14)',
        'subject': 'Письмо',
        'deadline': 'завтра',
        'status': 'не_начато',
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'task': 'Прослушать урок №12 «Правила Мадд»',
        'subject': 'Видео',
        'deadline': 'выполнено',
        'status': 'выполнено',
        'isDone': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final hw in defaults) {
      await _homeworkCol.add(hw);
    }
  }

  CollectionReference<Map<String, dynamic>> get _lessonsCol =>
      _userDoc.collection('lessons');

  Stream<List<Lesson>> getLessons() {
    return _lessonsCol.orderBy('sortOrder').snapshots().map((snap) {
      final seen = <String>{};
      final lessons = <Lesson>[];

      for (final doc in snap.docs) {
        if (doc.id.startsWith('default-')) continue;
        final lesson = Lesson.fromFirestore(doc);
        final key = [
          lesson.day,
          lesson.time,
          lesson.durationMin,
          lesson.type,
          lesson.topic,
          lesson.teacher,
        ].join('|');

        if (seen.add(key)) {
          lessons.add(lesson);
        }
      }

      return lessons;
    });
  }

  Future<void> ensureDefaultLessons() async {}

  Future<void> initDefaultLessons() async {
    final snap = await _lessonsCol.limit(1).get();
    if (snap.docs.isNotEmpty) {
      return;
    }

    final defaults = [
      {
        'day': 'Вторник, 3 июня',
        'time': '15:00',
        'durationMin': 60,
        'type': 'Таджвид',
        'topic': 'Правила Нун сакина и танвин',
        'teacher': 'устаз Ибрагим',
        'isSoon': true,
        'sortOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'day': 'Вторник, 3 июня',
        'time': '17:30',
        'durationMin': 45,
        'type': 'Хифз',
        'topic': 'Сура Аль-Мульк · аяты 1–10',
        'teacher': 'устаза Аиша',
        'isSoon': false,
        'sortOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'day': 'Вторник, 3 июня',
        'time': '19:00',
        'durationMin': 30,
        'type': 'Чтение',
        'topic': 'Тиляуат с разбором ошибок',
        'teacher': 'устаз Ибрагим',
        'isSoon': false,
        'sortOrder': 3,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var index = 0; index < defaults.length; index++) {
      await _lessonsCol
          .doc('default-${index + 1}')
          .set(defaults[index], SetOptions(merge: true));
    }
  }

  CollectionReference<Map<String, dynamic>> get _bookmarksCol =>
      _userDoc.collection('quranBookmarks');

  Future<void> addBookmark(int ayahNumber, String surahName) {
    return _bookmarksCol.add({
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeBookmark(int ayahNumber) async {
    final snap = await _bookmarksCol
        .where('ayahNumber', isEqualTo: ayahNumber)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> removeBookmarkFromSurah(int ayahNumber, String surahName) async {
    final snap = await _bookmarksCol
        .where('ayahNumber', isEqualTo: ayahNumber)
        .where('surahName', isEqualTo: surahName)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Stream<Set<int>> getBookmarks() {
    return _bookmarksCol.snapshots().map(
      (snap) =>
          snap.docs.map((d) => (d.data()['ayahNumber'] as num).toInt()).toSet(),
    );
  }

  Stream<Set<int>> getBookmarksForSurah(String surahName) {
    return _bookmarksCol
        .where('surahName', isEqualTo: surahName)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => (doc.data()['ayahNumber'] as num).toInt())
              .toSet(),
        );
  }

  Stream<List<QuranBookmark>> getQuranBookmarks() {
    return _bookmarksCol.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return QuranBookmark(
          ayahNumber: (data['ayahNumber'] as num?)?.toInt() ?? 1,
          surahName: data['surahName']?.toString() ?? '',
        );
      }).toList();
    });
  }
}
