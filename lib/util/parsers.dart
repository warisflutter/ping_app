import "package:intl/intl.dart";

String parseDate(DateTime date) => DateFormat.yMMMd().format(date);

String parseTime(DateTime time) => DateFormat.jm().format(time);

String parseDateTime(DateTime dateTime) =>
    '${parseDate(dateTime)} ${parseTime(dateTime)}';

String parseDateForServer(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
