import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/calendar_event.dart';

class NextcloudCalendarService {
  final String calendarUrl;
  final String username;
  final String appPassword;

  const NextcloudCalendarService({
    required this.calendarUrl,
    required this.username,
    required this.appPassword,
  });

  Map<String, String> get _headers => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}',
    'Content-Type': 'application/xml; charset=utf-8',
    'Depth': '1',
  };

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return getEventsForRange(start, end);
  }

  Future<List<CalendarEvent>> getEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final body =
        '''
<?xml version="1.0" encoding="utf-8" ?>
<c:calendar-query
    xmlns:d="DAV:"
    xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:getetag />
    <c:calendar-data />
  </d:prop>
  <c:filter>
    <c:comp-filter name="VCALENDAR">
      <c:comp-filter name="VEVENT">
        <c:time-range
            start="${_calDavDate(start.toUtc())}"
            end="${_calDavDate(end.toUtc())}" />
      </c:comp-filter>
    </c:comp-filter>
  </c:filter>
</c:calendar-query>
''';

    final request = http.Request('REPORT', Uri.parse(calendarUrl));

    request.headers.addAll(_headers);
    request.body = body;

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 10),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 207) {
      throw Exception('CalDAV HTTP ${response.statusCode}: ${response.body}');
    }

    return _parseEvents(response.body);
  }

  String _calDavDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}'
        '${two(date.month)}'
        '${two(date.day)}'
        'T'
        '${two(date.hour)}'
        '${two(date.minute)}'
        '${two(date.second)}'
        'Z';
  }

  List<CalendarEvent> _parseEvents(String xml) {
    final events = <CalendarEvent>[];

    final calendarDataPattern = RegExp(
      r'<(?:\w+:)?calendar-data[^>]*>(.*?)</(?:\w+:)?calendar-data>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in calendarDataPattern.allMatches(xml)) {
      var ics = match.group(1) ?? '';

      ics = ics
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");

      final summary = _icsValue(ics, 'SUMMARY');
      final description = _icsValue(ics, 'DESCRIPTION');
      final dtStart = _icsValue(ics, 'DTSTART');

      final start = dtStart == null ? null : _parseIcsDateTime(dtStart);

      if (summary != null && start != null) {
        events.add(
          CalendarEvent(
            summary: summary,
            description: description ?? '',
            start: start,
          ),
        );
      }
    }

    return events;
  }

  DateTime? _parseIcsDateTime(String value) {
    try {
      if (value.length == 8) {
        return DateTime(
          int.parse(value.substring(0, 4)),
          int.parse(value.substring(4, 6)),
          int.parse(value.substring(6, 8)),
        );
      }

      final isUtc = value.endsWith('Z');
      final raw = isUtc ? value.substring(0, value.length - 1) : value;

      if (raw.length < 15) {
        return null;
      }

      final date = DateTime(
        int.parse(raw.substring(0, 4)),
        int.parse(raw.substring(4, 6)),
        int.parse(raw.substring(6, 8)),
        int.parse(raw.substring(9, 11)),
        int.parse(raw.substring(11, 13)),
        int.parse(raw.substring(13, 15)),
      );

      return isUtc
          ? DateTime.utc(
              date.year,
              date.month,
              date.day,
              date.hour,
              date.minute,
              date.second,
            ).toLocal()
          : date;
    } catch (_) {
      return null;
    }
  }

  String? _icsValue(String ics, String property) {
    final unfolded = ics.replaceAll(RegExp(r'\r?\n[ \t]'), '');

    final match = RegExp(
      '^$property(?:;[^:]*)?:(.*)\$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(unfolded);

    if (match == null) {
      return null;
    }

    return match
        .group(1)!
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', r'\');
  }
}
