import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<double> weeklyData;

  const WeeklyTrendChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    // If we have no data at all (sum is 0), we might want to show a placeholder or just empty chart
    // But requirement says "Visualize ... (dummy data if no data)".
    // The provider fills 0s if no data.
    // If all are 0, we can show a "No data" message or simpler chart.
    // We'll show the chart anyway.

    // Calculate dynamic max Y for scaling
    double maxY = weeklyData.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 10000; // Default max if empty
    maxY = maxY * 1.2; // Add some headroom

    const limeColor = Color(0xFFD4FF00);

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  NumberFormat('#,###').format(rod.toY),
                  const TextStyle(
                    color: limeColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= 7) return const SizedBox.shrink();

                  // Calculate day label: 6 is Today, 5 is Yesterday...
                  // data is [Day-6, ..., Today]
                  // So index 6 is Today.
                  final now = DateTime.now();
                  final date = now.subtract(Duration(days: 6 - index));
                  final dayName = DateFormat('E').format(date); // Mon, Tue...

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ), // Hide Y axis labels for cleaner look
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) => value % (maxY / 4) == 0,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white10, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.asMap().entries.map((e) {
            final index = e.key;
            final val = e.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: val > 0 ? limeColor : Colors.white10,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
