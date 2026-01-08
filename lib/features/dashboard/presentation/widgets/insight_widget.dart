import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/i18n.dart';

class InsightWidget extends StatefulWidget {
  final List<double> weeklyTrend;
  final Map<String, double> categoryBreakdown;

  const InsightWidget({
    super.key,
    required this.weeklyTrend,
    required this.categoryBreakdown,
  });

  @override
  State<InsightWidget> createState() => _InsightWidgetState();
}

class _InsightWidgetState extends State<InsightWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFD4FF00);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: limeColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: limeColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: limeColor,
            labelColor: limeColor,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Weekly Trend'),
              Tab(text: 'Top Temptations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CompactTrendChart(data: widget.weeklyTrend),
                _CompactPieChart(data: widget.categoryBreakdown),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTrendChart extends StatelessWidget {
  final List<double> data;

  const _CompactTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.every((v) => v == 0)) {
      return Center(
        child: Text("No data yet", style: TextStyle(color: Colors.white24)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: const Color(0xFFD4FF00),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFD4FF00).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _CompactPieChart extends StatelessWidget {
  final Map<String, double> data;

  const _CompactPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text("No data yet", style: TextStyle(color: Colors.white24)),
      );
    }
    final i18n = I18n.of(context);

    // Limit to top 3 for compact view
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayData = entries.take(3).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 30,
              sections: displayData.map((e) {
                final index = displayData.indexOf(e);
                final color = [
                  Colors.blueAccent,
                  Colors.redAccent,
                  Colors.orangeAccent,
                ][index % 3];
                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  showTitle: false,
                  radius: 15,
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displayData.map((e) {
              final index = displayData.indexOf(e);
              final color = [
                Colors.blueAccent,
                Colors.redAccent,
                Colors.orangeAccent,
              ][index % 3];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${i18n.categoryName(e.key)} (${e.value.toInt()})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}
