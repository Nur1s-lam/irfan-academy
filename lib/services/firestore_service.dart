import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson.dart';
import '../models/user_profile.dart';

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
    return _homeworkCol
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(HomeworkItem.fromFirestore).toList());
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
    return _lessonsCol
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(Lesson.fromFirestore).toList());
  }

  Future<void> ensureDefaultLessons() => initDefaultLessons();

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

    for (final lesson in defaults) {
      await _lessonsCol.add(lesson);
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

  Stream<Set<int>> getBookmarks() {
    return _bookmarksCol.snapshots().map(
      (snap) =>
          snap.docs.map((d) => (d.data()['ayahNumber'] as num).toInt()).toSet(),
    );
  }
}
