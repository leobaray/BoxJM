import 'package:intl/intl.dart';

enum DateBucket {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  older;

  String get label => switch (this) {
        DateBucket.today => 'Hoje',
        DateBucket.yesterday => 'Ontem',
        DateBucket.thisWeek => 'Esta semana',
        DateBucket.thisMonth => 'Este mês',
        DateBucket.older => 'Mais antigos',
      };
}

DateBucket bucketFor(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final d = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(d).inDays;

  if (diffDays == 0) return DateBucket.today;
  if (diffDays == 1) return DateBucket.yesterday;
  if (diffDays < 7) return DateBucket.thisWeek;
  if (d.year == today.year && d.month == today.month) {
    return DateBucket.thisMonth;
  }
  return DateBucket.older;
}

const _weekdaysPt = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String relativeLabel(DateTime date, {DateTime? now}) {
  final b = bucketFor(date, now: now);
  switch (b) {
    case DateBucket.today:
      return 'Hoje, ${DateFormat('HH:mm').format(date)}';
    case DateBucket.yesterday:
      return 'Ontem, ${DateFormat('HH:mm').format(date)}';
    case DateBucket.thisWeek:
      final weekday = _weekdaysPt[date.weekday - 1];
      return '$weekday, ${DateFormat('HH:mm').format(date)}';
    default:
      return DateFormat('dd/MM/yyyy').format(date);
  }
}
