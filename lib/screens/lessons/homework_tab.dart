import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tag_widget.dart';

class HomeworkTab extends StatelessWidget {
  const HomeworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = FirestoreService(uid);

    return StreamBuilder<List<HomeworkItem>>(
      stream: firestoreService.getHomework(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          );
        }

        final homework = snapshot.data ?? [];
        if (homework.isEmpty) {
          return AppCard(
            child: Text(
              'Заданий пока нет',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: homework.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = homework[index];
            return _HomeworkCard(
              item: item,
              onToggle: () {
                firestoreService.updateHomeworkStatus(item.id, !item.isDone);
              },
            );
          },
        );
      },
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.item, required this.onToggle});

  final HomeworkItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final statusText = _statusText(item);
    final statusColor = item.isDone || item.status == 'в_процессе'
        ? AppTheme.goldDeep
        : AppTheme.inkFaint;
    final textColor = item.isDone ? AppTheme.inkFaint : AppTheme.ink;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeworkCheckbox(done: item.isDone, onTap: onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.task,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              decoration: item.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: AppTheme.inkFaint,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TagWidget(label: item.subject),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$statusText · ${item.deadline}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(HomeworkItem item) {
    if (item.isDone || item.status == 'выполнено') {
      return 'Выполнено';
    }
    if (item.status == 'в_процессе') {
      return 'В процессе';
    }
    return 'Не начато';
  }
}

class _HomeworkCheckbox extends StatelessWidget {
  const _HomeworkCheckbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface.withValues(alpha: 0),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: AppTheme.motion,
          curve: AppTheme.motionCurve,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 1.8),
            color: done ? AppTheme.goldSoft : AppTheme.surface,
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  color: AppTheme.goldDeep,
                  size: 24,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
