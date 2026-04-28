String formatRecordDate(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
}

String formatElapsedSeconds(int seconds) {
  if (seconds < 60) return '$seconds초';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m분' : '$m분 $s초';
}
