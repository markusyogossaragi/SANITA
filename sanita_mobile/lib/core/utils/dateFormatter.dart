class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String toIndonesian(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String toShort(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String toTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  static String toIndonesianDateTime(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}, ${toTime(date)} WIB';

  /// Converts ISO-8601 string to friendly human-readable format
  static String toHumanReadable(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return toIndonesian(date);
    } catch (_) {
      return isoString;
    }
  }
}