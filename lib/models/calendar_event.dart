class CalendarEvent {
  final String summary;
  final String description;
  final DateTime start;
  final bool allDay;

  // CalDAV metadata required for updating the original event.
  final String href;
  final String? etag;
  final String? uid;
  final String rawIcs;

  const CalendarEvent({
    required this.summary,
    required this.description,
    required this.start,
    required this.allDay,
    required this.href,
    required this.etag,
    required this.uid,
    required this.rawIcs,
  });
}
