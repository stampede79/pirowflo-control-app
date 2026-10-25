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

  String _replaceIcsDescription(String ics, String description) {
    final escapedDescription = _escapeIcsText(description);

    // Folded ICS lines first need to be unfolded so DESCRIPTION can be
    // replaced as one logical property.
    final unfolded = ics.replaceAll(RegExp(r'\r?\n[ \t]'), '');

    final descriptionPattern = RegExp(
      r'^DESCRIPTION(?:;[^:]*)?:.*$',
      caseSensitive: false,
      multiLine: true,
    );

    if (descriptionPattern.hasMatch(unfolded)) {
      return unfolded.replaceFirst(
        descriptionPattern,
        'DESCRIPTION:$escapedDescription',
      );
    }

    // Some events do not have a DESCRIPTION yet.
    return unfolded.replaceFirst(
      'END:VEVENT',
      'DESCRIPTION:$escapedDescription\r\nEND:VEVENT',
    );
  }

  String _escapeIcsText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }

  String _decodeXml(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  String? _xmlValue(String xml, String property) {
    final match = RegExp(
      '<(?:\\w+:)?$property[^>]*>(.*?)</(?:\\w+:)?$property>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(xml);

    return match?.group(1)?.trim();
  }

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

  Future<void> updateEventDescription(
    CalendarEvent event,
    String newDescription,
  ) async {
    if (event.etag == null || event.etag!.isEmpty) {
      throw Exception('CalDAV-Termin besitzt keinen ETag.');
    }

    final updatedIcs = _replaceIcsDescription(event.rawIcs, newDescription);

    final calendarUri = Uri.parse(calendarUrl);
    final eventUri = calendarUri.resolve(event.href);

    final request = http.Request('PUT', eventUri);

    request.headers.addAll({
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}',
      'Content-Type': 'text/calendar; charset=utf-8',
      'If-Match': event.etag!,
    });

    request.body = updatedIcs;

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 10),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'CalDAV PUT HTTP ${response.statusCode}: ${response.body}',
      );
    }
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

    final responsePattern = RegExp(
      r'<(?:\w+:)?response[^>]*>(.*?)</(?:\w+:)?response>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final responseMatch in responsePattern.allMatches(xml)) {
      final responseXml = responseMatch.group(1) ?? '';

      final href = _xmlValue(responseXml, 'href');
      final etag = _xmlValue(responseXml, 'getetag');

      final calendarDataMatch = RegExp(
        r'<(?:\w+:)?calendar-data[^>]*>(.*?)</(?:\w+:)?calendar-data>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(responseXml);

      if (href == null || calendarDataMatch == null) {
        continue;
      }

      var ics = calendarDataMatch.group(1) ?? '';

      ics = _decodeXml(ics);

      final summary = _icsValue(ics, 'SUMMARY');
      final description = _icsValue(ics, 'DESCRIPTION');
      final dtStart = _icsValue(ics, 'DTSTART');
      final uid = _icsValue(ics, 'UID');

      final start = dtStart == null ? null : _parseIcsDateTime(dtStart);
      final allDay = dtStart != null && dtStart.length == 8;

      if (summary == null || start == null) {
        continue;
      }

      events.add(
        CalendarEvent(
          summary: summary,
          description: description ?? '',
          start: start,
          allDay: allDay,
          href: _decodeXml(href),
          etag: etag == null ? null : _decodeXml(etag),
          uid: uid,
          rawIcs: ics,
        ),
      );
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
