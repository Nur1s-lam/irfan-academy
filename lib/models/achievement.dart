class Achievement {
  const Achievement({
    required this.title,
    required this.progress,
    required this.isUnlocked,
  });

  final String title;
  final double progress;
  final bool isUnlocked;
}
