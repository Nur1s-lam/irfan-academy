import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../models/video_lesson.dart';
import '../../services/admin_service.dart';
import '../../services/cloudinary_video_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class AdminScreen extends StatelessWidget {
  AdminScreen({super.key});

  final AdminService _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Панель администратора')),
      body: StreamBuilder<List<UserProfile>>(
        stream: _admin.watchStudents(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? const <UserProfile>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Управление академией',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Добавляйте материалы и назначайте обучение конкретным ученикам.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 2 : 1;
                  final tiles = [
                    _ActionTile(
                      icon: Icons.video_library_rounded,
                      title: 'Видеоуроки',
                      subtitle: 'Загрузка и управление видео',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _VideosAdminPage(admin: _admin),
                        ),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.event_note_rounded,
                      title: 'Расписание и уроки',
                      subtitle: 'Назначить урок ученику',
                      onTap: users.isEmpty
                          ? null
                          : () => _showLessonForm(context, users),
                    ),
                    _ActionTile(
                      icon: Icons.assignment_rounded,
                      title: 'Домашние задания',
                      subtitle: 'Создать задание ученику',
                      onTap: users.isEmpty
                          ? null
                          : () => _showHomeworkForm(context, users),
                    ),
                    _ActionTile(
                      icon: Icons.campaign_rounded,
                      title: 'Объявления',
                      subtitle: 'Опубликовать новость',
                      onTap: () => _showAnnouncementForm(context),
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 3.2 : 3.0,
                    children: tiles,
                  );
                },
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: AppTheme.palette(context).primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Пользователей: ${users.length}')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showHomeworkForm(
    BuildContext context,
    List<UserProfile> users,
  ) {
    return _showForm(
      context,
      title: 'Новое задание',
      users: users,
      fields: const [
        _Field('Задание', 'task'),
        _Field('Предмет', 'subject'),
        _Field('Срок выполнения', 'deadline'),
      ],
      onSave: (values, uid) => _admin.addHomework(
        uid: uid!,
        task: values['task']!,
        subject: values['subject']!,
        deadline: values['deadline']!,
      ),
    );
  }

  Future<void> _showLessonForm(BuildContext context, List<UserProfile> users) {
    return _showForm(
      context,
      title: 'Новый урок в расписании',
      users: users,
      fields: const [
        _Field('День или дата', 'day'),
        _Field('Время, например 15:00', 'time'),
        _Field('Длительность в минутах', 'duration', number: true),
        _Field('Тип урока', 'type'),
        _Field('Тема', 'topic'),
        _Field('Преподаватель', 'teacher'),
      ],
      onSave: (values, uid) => _admin.addLesson(
        uid: uid!,
        day: values['day']!,
        time: values['time']!,
        durationMin: int.parse(values['duration']!),
        type: values['type']!,
        topic: values['topic']!,
        teacher: values['teacher']!,
      ),
    );
  }

  Future<void> _showAnnouncementForm(BuildContext context) {
    return _showForm(
      context,
      title: 'Новое объявление',
      fields: const [
        _Field('Заголовок', 'title'),
        _Field('Текст', 'body', lines: 4),
      ],
      onSave: (values, _) => _admin.publishAnnouncement(
        title: values['title']!,
        body: values['body']!,
      ),
    );
  }
}

class _VideosAdminPage extends StatelessWidget {
  const _VideosAdminPage({required this.admin});
  final AdminService admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Видеоуроки')),
      body: StreamBuilder<List<VideoLesson>>(
        stream: admin.watchVideos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Не удалось загрузить список: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Добавить видеоурок',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Выберите видео — загрузка начнётся автоматически. '
                      'Длительность и размер определятся без ручного ввода.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _pickVideo(context),
                      icon: const Icon(Icons.video_file_rounded),
                      label: const Text('Выбрать видео с устройства'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Загруженные уроки (${videos.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (videos.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Видеоуроков пока нет')),
                  ),
                ),
              for (final video in videos) ...[
                AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_fill_rounded),
                    title: Text('${video.number}. ${video.title}'),
                    subtitle: Text(
                      [
                        video.duration,
                        if (video.fileSize > 0) _formatBytes(video.fileSize),
                        if (video.fileName.isNotEmpty) video.fileName,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Удалить из списка',
                      onPressed: () => _confirmDelete(context, video),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VideoLesson video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить видеоурок?'),
        content: Text('«${video.title}» будет удалён из списка уроков.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await admin.deleteVideo(video);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Видеоурок удалён из списка')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить урок: $error')),
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    final uploaded = await showDialog<_UploadedVideo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VideoUploadDialog(admin: admin, file: file),
    );
    if (uploaded == null || !context.mounted) return;

    await _showForm(
      context,
      title: 'Оформление видеоурока',
      fields: const [
        _Field('Номер урока', 'number', number: true),
        _Field('Название', 'title'),
        _Field('Описание', 'description', lines: 3, required: false),
      ],
      onSave: (values, _) async {
        await admin.saveVideo(
          title: values['title']!,
          number: int.parse(values['number']!),
          totalSeconds: uploaded.upload.durationSeconds,
          videoUrl: uploaded.upload.secureUrl,
          videoPath: uploaded.upload.publicId,
          fileName: uploaded.upload.fileName,
          fileSize: uploaded.upload.fileSize,
          contentType: uploaded.upload.contentType,
          description: values['description'] ?? '',
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    const mb = 1024 * 1024;
    const gb = 1024 * mb;
    return bytes >= gb
        ? '${(bytes / gb).toStringAsFixed(2)} GB'
        : '${(bytes / mb).toStringAsFixed(1)} MB';
  }
}

class _UploadedVideo {
  const _UploadedVideo({required this.upload});
  final CloudinaryUploadResult upload;
}

class _VideoUploadDialog extends StatefulWidget {
  const _VideoUploadDialog({required this.admin, required this.file});
  final AdminService admin;
  final XFile file;

  @override
  State<_VideoUploadDialog> createState() => _VideoUploadDialogState();
}

class _VideoUploadDialogState extends State<_VideoUploadDialog> {
  double _progress = 0;
  String? _error;
  bool _cancelled = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _cancelled = false;
      _error = null;
      _progress = 0;
    });
    try {
      final upload = await widget.admin.videoStorage.uploadVideo(
        widget.file,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        isCancelled: () => _cancelled,
      );
      if (!mounted) return;
      Navigator.pop(context, _UploadedVideo(upload: upload));
    } catch (error) {
      if (mounted && !_cancelled) {
        setState(() {
          _running = false;
          _error = 'Не удалось загрузить видео в Cloudinary: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_error == null ? 'Загрузка видео' : 'Ошибка загрузки'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error == null) ...[
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 14),
              Text(
                _progress == 0
                    ? 'Подготавливаем и начинаем загрузку…'
                    : 'Загружено ${(100 * _progress).round()}%',
              ),
            ] else
              Text(_error!),
          ],
        ),
      ),
      actions: [
        if (_error != null) ...[
          TextButton(onPressed: _start, child: const Text('Повторить')),
        ],
        TextButton(
          onPressed: () {
            _cancelled = true;
            Navigator.pop(context);
          },
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.palette(context).primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _Field {
  const _Field(
    this.label,
    this.key, {
    this.number = false,
    this.lines = 1,
    this.required = true,
  });
  final String label;
  final String key;
  final bool number;
  final int lines;
  final bool required;
}

Future<void> _showForm(
  BuildContext context, {
  required String title,
  required List<_Field> fields,
  required Future<void> Function(Map<String, String> values, String? uid)
  onSave,
  List<UserProfile>? users,
}) async {
  final controllers = {
    for (final field in fields) field.key: TextEditingController(),
  };
  final formKey = GlobalKey<FormState>();
  String? selectedUid = users == null ? null : AdminService.allStudents;
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (users != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUid,
                    decoration: const InputDecoration(labelText: 'Ученик'),
                    items: [
                      const DropdownMenuItem(
                        value: AdminService.allStudents,
                        child: Text('Всем ученикам'),
                      ),
                      ...users.map(
                        (user) => DropdownMenuItem(
                          value: user.uid,
                          child: Text(
                            user.name.isEmpty ? user.email : user.name,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => selectedUid = value,
                  ),
                ],
                for (final field in fields) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controllers[field.key],
                    maxLines: field.lines,
                    keyboardType: field.number
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(labelText: field.label),
                    validator: (value) {
                      if (field.required &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Заполните поле';
                      }
                      if (field.number && int.tryParse(value ?? '') == null) {
                        return 'Введите целое число';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => saving = true);
                          try {
                            final values = {
                              for (final entry in controllers.entries)
                                entry.key: entry.value.text.trim(),
                            };
                            await onSave(values, selectedUid);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          } catch (error) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text('Не удалось сохранить: $error'),
                                ),
                              );
                              setModalState(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Сохранение…' : 'Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  for (final controller in controllers.values) {
    controller.dispose();
  }
}
