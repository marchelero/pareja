/// Utilidades de fecha para monetizacion.
///
/// El reset diario usa **medianoche local** (no UTC, no servidor) — el cap se
/// resetea cuando arranca un nuevo dia en el dispositivo del usuario.
class DateUtils {
  DateUtils._();

  /// String "YYYY-MM-DD" en zona horaria local, usado como key en LocalStorage
  /// para detectar rollover de medianoche.
  static String dayKey(DateTime when) {
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// True si dos fechas caen en el mismo dia local.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// True si la fecha "stored" representa un dia anterior a "now" (rollover
  /// detectado). Retorna true tambien si stored es null (primer arranque).
  static bool isDayRollover(DateTime? stored, DateTime now) {
    if (stored == null) return true;
    return !isSameDay(stored, now);
  }
}
