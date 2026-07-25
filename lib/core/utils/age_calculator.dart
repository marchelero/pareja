/// Pure helpers for age-based gating.
library;

/// Returns true if [dateOfBirth] corresponds to a person aged 18+ on [now].
///
/// Default [now] is `DateTime.now()`. The check uses the calendar-year
/// difference, so a person born on 2000-01-01 is considered adult on
/// 2018-01-01, not 2017-12-31.
bool isAdult(DateTime dateOfBirth, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  var age = reference.year - dateOfBirth.year;
  final hadBirthdayThisYear = (reference.month > dateOfBirth.month) ||
      (reference.month == dateOfBirth.month && reference.day >= dateOfBirth.day);
  if (!hadBirthdayThisYear) age--;
  return age >= 18;
}
