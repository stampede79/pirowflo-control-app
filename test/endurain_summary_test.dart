import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/endurain_summary.dart';

void main() {
  test('parst Endurain Indoor-Rowing-Wochenstatistik', () {
    final summary = EndurainSummary.fromJson({
      'total_distance': 7162.0,
      'total_duration': 2129.93,
      'total_elevation_gain': 0.0,
      'activity_count': 1,
      'total_calories': 342.0,
      'breakdown': [
        {
          'total_distance': 0.0,
          'total_duration': 0.0,
          'activity_count': 0,
          'total_calories': 0.0,
          'day_of_week': 0,
        },
        {
          'total_distance': 7162.0,
          'total_duration': 2129.93,
          'activity_count': 1,
          'total_calories': 342.0,
          'day_of_week': 1,
        },
      ],
    });

    expect(summary.distance, 7162);
    expect(summary.activityCount, 1);
    expect(summary.duration, 2129.93);
    expect(summary.calories, 342);

    expect(summary.breakdown.length, 2);
    expect(summary.breakdown[1].period, 1);
    expect(summary.breakdown[1].distance, 7162);
  });

  test('parst Endurain Jahres-Breakdown', () {
    final summary = EndurainSummary.fromJson({
      'total_distance': 66088.0,
      'total_duration': 19376.886,
      'activity_count': 15,
      'total_calories': 3082.0,
      'breakdown': [
        {
          'total_distance': 10000.0,
          'total_duration': 3000.0,
          'activity_count': 2,
          'total_calories': 500.0,
          'month_number': 9,
        },
      ],
    });

    expect(summary.activityCount, 15);
    expect(summary.breakdown.length, 1);
    expect(summary.breakdown.first.period, 9);
    expect(summary.breakdown.first.distance, 10000);
  });
}
