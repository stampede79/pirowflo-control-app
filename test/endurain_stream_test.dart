import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/endurain_stream.dart';

void main() {
  test('parst Endurain Power Stream', () {
    final stream = EndurainStream.fromJson({
      'stream_type': 2,
      'stream_waypoints': [
        {'time': '2026-10-20T09:14:00', 'power': 0},
        {'time': '2026-10-20T09:14:01', 'power': 3},
        {'time': '2026-10-20T09:14:02', 'power': 107},
      ],
    });

    expect(stream.type, EndurainStreamType.power);
    expect(stream.points.length, 3);
    expect(stream.points[0].value, 0);
    expect(stream.points[1].value, 3);
    expect(stream.points[2].value, 107);

    expect(
      stream.points[1].time.difference(stream.points[0].time),
      const Duration(seconds: 1),
    );
  });

  test('parst Endurain HR und Cadence', () {
    final hr = EndurainStream.fromJson({
      'stream_type': 1,
      'stream_waypoints': [
        {'time': '2026-10-20T09:14:00', 'hr': 78},
      ],
    });

    final cadence = EndurainStream.fromJson({
      'stream_type': 3,
      'stream_waypoints': [
        {'time': '2026-10-20T09:14:00', 'cad': 17},
      ],
    });

    expect(hr.type, EndurainStreamType.heartRate);
    expect(hr.points.single.value, 78);

    expect(cadence.type, EndurainStreamType.cadence);
    expect(cadence.points.single.value, 17);
  });
}
