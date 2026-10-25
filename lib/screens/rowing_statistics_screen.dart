import 'package:flutter/material.dart';

import '../models/endurain_summary.dart';
import 'statistics_screen.dart';

class RowingStatisticsScreen extends StatelessWidget {
  final EndurainSummary? summary;
  final bool loading;
  final String? error;
  final EndurainSummaryPeriod period;
  final ValueChanged<EndurainSummaryPeriod> onPeriodChanged;
  final VoidCallback onRefresh;

  const RowingStatisticsScreen({
    super.key,
    required this.summary,
    required this.loading,
    required this.error,
    required this.period,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return StatisticsScreen(
      summary: summary,
      loading: loading,
      error: error,
      onRefresh: onRefresh,
      period: period,
      onPeriodChanged: onPeriodChanged,
    );
  }
}
