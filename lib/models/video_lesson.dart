import 'package:cloud_firestore/cloud_firestore.dart';

class VideoLesson {
  const VideoLesson({
    this.id = '',
    required this.number,
    required this.title,
    required this.duration,
    required this.totalSeconds,
    this.videoUrl = '',
    this.videoPath = '',
    this.fileName = '',
    this.fileSize = 0,
    this.contentType = 'video/mp4',
    this.description = '',
  });

  final String id;
  final int number;
  final String title;
  final String duration;
  final int totalSeconds;
  final String videoUrl;
  final String videoPath;
  final String fileName;
  final int fileSize;
  final String contentType;
  final String description;

  factory VideoLesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final seconds = (data['totalSeconds'] as num?)?.toInt() ?? 0;
    return VideoLesson(
      id: doc.id,
      number: (data['number'] as num?)?.toInt() ?? 0,
      title: data['title']?.toString() ?? '',
      duration: data['duration']?.toString() ?? _formatDuration(seconds),
      totalSeconds: seconds,
      videoUrl: data['videoUrl']?.toString() ?? '',
      videoPath: data['videoPath']?.toString() ?? '',
      fileName: data['fileName']?.toString() ?? '',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      contentType: data['contentType']?.toString() ?? 'video/mp4',
      description: data['description']?.toString() ?? '',
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
