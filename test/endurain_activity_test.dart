import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';

void main() {
  test('parst Endurain Indoor-Rowing-Aktivität', () {
    final activity = EndurainActivity.fromJson({
      'id': 1093,
      'name': 'Indoor-Rudern',
      'activity_type': 13,
      'start_time': '2026-10-20T11:14:00',
      'distance': 7162,
      'total_timer_time': 2129.93,
      'average_power': 107,
      'max_power': 165,
      'average_hr': 128,
      'max_hr': 155,
      'average_cad': 17,
      'max_cad': 46,
      'calories': 342,
      'normalized_power': 117,
      'total_cycles': 662,
    });

    expect(activity.id, 1093);
    expect(activity.activityType, 13);
    expect(activity.distance, 7162);
    expect(activity.duration, 2129.93);
    expect(activity.averagePower, 107);
    expect(activity.maxPower, 165);
    expect(activity.averageHeartRate, 128);
    expect(activity.averageCadence, 17);
    expect(activity.calories, 342);
    expect(activity.normalizedPower, 117);
    expect(activity.totalCycles, 662);

    expect(activity.pace500mSeconds, closeTo(148.7, 0.1));

    expect(activity.distanceKm, closeTo(7.162, 0.001));
  });
}
