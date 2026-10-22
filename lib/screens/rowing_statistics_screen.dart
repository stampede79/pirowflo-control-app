import 'package:flutter/material.dart';

import '../models/endurain_activity.dart';
import '../models/endurain_summary.dart';
import 'rowing_activities_screen.dart';
import 'statistics_screen.dart';

enum RowingStatisticsView { development, activities }

class RowingStatisticsScreen extends StatefulWidget {
  final EndurainSummary? summary;
  final List<EndurainActivity> activities;
  final bool loading;
  final String? error;
  final EndurainSummaryPeriod period;
  final ValueChanged<EndurainSummaryPeriod> onPeriodChanged;
  final VoidCallback onRefresh;
  final String endurainServer;

  const RowingStatisticsScreen({
    super.key,
    required this.summary,
    required this.activities,
    required this.loading,
    required this.error,
    required this.period,
    required this.onPeriodChanged,
    required this.onRefresh,
    required this.endurainServer,
  });

  @override
  State<RowingStatisticsScreen> createState() => _RowingStatisticsScreenState();
}

class _RowingStatisticsScreenState extends State<RowingStatisticsScreen> {
  RowingStatisticsView view = RowingStatisticsView.development;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<RowingStatisticsView>(
              segments: const [
                ButtonSegment(
                  value: RowingStatisticsView.development,
                  icon: Icon(Icons.insights),
                  label: Text('Entwicklung'),
                ),
                ButtonSegment(
                  value: RowingStatisticsView.activities,
                  icon: Icon(Icons.history),
                  label: Text('Aktivitäten'),
                ),
              ],
              selected: {view},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  view = selection.first;
                });
              },
            ),
          ),
        ),
        Expanded(
          child: switch (view) {
            RowingStatisticsView.development => StatisticsScreen(
              summary: widget.summary,
              loading: widget.loading,
              error: widget.error,
              onRefresh: widget.onRefresh,
              period: widget.period,
              onPeriodChanged: widget.onPeriodChanged,
            ),

            RowingStatisticsView.activities => RowingActivitiesScreen(
              activities: widget.activities,
              loading: widget.loading,
              error: widget.error,
              onRefresh: widget.onRefresh,
              endurainServer: widget.endurainServer,
            ),
          },
        ),
      ],
    );
  }
}
