class Homework {
  Homework({
    required this.task,
    required this.subject,
    required this.deadline,
    required this.status,
    required this.isDone,
  });

  final String task;
  final String subject;
  final String deadline;
  final String status;
  bool isDone;
}
