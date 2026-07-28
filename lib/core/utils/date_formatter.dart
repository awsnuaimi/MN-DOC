/// تنسيق التاريخ بالعربي: "منذ 5 دقائق"، "منذ يومين"... إلخ.
class DateFormatter {
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} ${_unit(diff.inMinutes, 'دقيقة', 'دقائق')}';
    }
    if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ${_unit(diff.inHours, 'ساعة', 'ساعات')}';
    }
    if (diff.inDays < 30) {
      return 'منذ ${diff.inDays} ${_unit(diff.inDays, 'يوم', 'أيام')}';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months ${_unit(months, 'شهر', 'أشهر')}';
    }
    final years = (diff.inDays / 365).floor();
    return 'منذ $years ${_unit(years, 'سنة', 'سنوات')}';
  }

  static String _unit(int count, String singular, String plural) =>
      count == 1 ? singular : plural;

  static String fullDate(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}