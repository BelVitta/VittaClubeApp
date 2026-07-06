class DependentCycleService {
  String currentCycleReference({
    required DateTime adhesionDate,
    required DateTime now,
  }) {
    final cycleStart = currentCycleStart(adhesionDate: adhesionDate, now: now);
    return _formatDate(cycleStart);
  }

  DateTime currentCycleStart({
    required DateTime adhesionDate,
    required DateTime now,
  }) {
    var candidate = DateTime(
      now.year,
      now.month,
      _safeDay(now.year, now.month, adhesionDate.day),
    );

    if (candidate.isAfter(now)) {
      final previousMonth = DateTime(now.year, now.month - 1);
      candidate = DateTime(
        previousMonth.year,
        previousMonth.month,
        _safeDay(previousMonth.year, previousMonth.month, adhesionDate.day),
      );
    }

    return DateTime(candidate.year, candidate.month, candidate.day);
  }

  int _safeDay(int year, int month, int preferredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return preferredDay > lastDay ? lastDay : preferredDay;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
