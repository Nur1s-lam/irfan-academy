import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<UserCredential?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      final uid = cred.user?.uid;
      if (uid != null) {
        final firestoreService = FirestoreService(uid);
        await firestoreService.createUserProfile(name: name, email: email);
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Пароль слишком простой (мин. 6 символов)';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка: $code';
    }
  }
}
