import 'package:flutter_test/flutter_test.dart';
import 'package:irfan_academy/models/user_profile.dart';

void main() {
  UserProfile profileWithRole(String role) => UserProfile(
    uid: 'uid',
    name: 'User',
    email: 'user@example.com',
    group: 'Group',
    role: role,
    attendance: 0,
    lessonsCount: 0,
    streakDays: 0,
    quranProgress: 0,
    currentSura: '',
    currentAyah: 1,
  );

  test('recognizes supported administrator roles', () {
    expect(profileWithRole('admin').isAdmin, isTrue);
    expect(profileWithRole('Администратор').isAdmin, isTrue);
    expect(profileWithRole('Ученик').isAdmin, isFalse);
  });
}
