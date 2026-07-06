class BillingCyclePolicy {
  const BillingCyclePolicy._();

  static DateTime nextBillingDate({
    required DateTime currentCycleDate,
    required int billingDay,
  }) {
    final nextMonth = currentCycleDate.month == 12
        ? DateTime(currentCycleDate.year + 1, 1)
        : DateTime(currentCycleDate.year, currentCycleDate.month + 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final day = billingDay > lastDay ? lastDay : billingDay;
    return DateTime(nextMonth.year, nextMonth.month, day);
  }

  static DateTime currentPeriodEnd({
    required DateTime paidAt,
    required int billingDay,
  }) {
    return nextBillingDate(
      currentCycleDate: DateTime(paidAt.year, paidAt.month, paidAt.day),
      billingDay: billingDay,
    );
  }
}
