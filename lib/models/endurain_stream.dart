enum EndurainStreamType {
  heartRate(1),
  power(2),
  cadence(3);

  final int id;

  const EndurainStreamType(this.id);

  static EndurainStreamType? fromId(int id) {
    for (final type in values) {
      if (type.id == id) {
        return type;
      }
    }

    return null;
  }
}

class EndurainStreamPoint {
  final DateTime time;
  final double value;

  const EndurainStreamPoint({required this.time, required this.value});
}

class EndurainStream {
  final EndurainStreamType type;
  final List<EndurainStreamPoint> points;

  const EndurainStream({required this.type, required this.points});

  factory EndurainStream.fromJson(Map<String, dynamic> json) {
    final streamTypeId = (json['stream_type'] as num).toInt();
    final type = EndurainStreamType.fromId(streamTypeId);

    if (type == null) {
      throw FormatException('Unbekannter Endurain Stream-Typ: $streamTypeId');
    }

    final rawWaypoints = json['stream_waypoints'];

    if (rawWaypoints is! List) {
      throw const FormatException('Ungültige Endurain Stream-Waypoints');
    }

    final points = <EndurainStreamPoint>[];

    for (final raw in rawWaypoints) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final rawTime = raw['time'];

      if (rawTime == null) {
        continue;
      }

      final rawValue = switch (type) {
        EndurainStreamType.heartRate => raw['hr'],
        EndurainStreamType.power => raw['power'],
        EndurainStreamType.cadence => raw['cad'],
      };

      if (rawValue is! num) {
        continue;
      }

      points.add(
        EndurainStreamPoint(
          time: DateTime.parse(rawTime.toString()),
          value: rawValue.toDouble(),
        ),
      );
    }

    return EndurainStream(type: type, points: points);
  }
}
