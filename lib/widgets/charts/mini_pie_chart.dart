import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniPieChart extends StatelessWidget {
  final Map<String, double> data;
  final double size;

  const MiniPieChart({
    super.key,
    required this.data,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (data.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pie_chart_outline,
          size: size * 0.4,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }

    final total = data.values.fold(0.0, (sum, value) => sum + value);
    final List<PieChartSectionData> sections = [];
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];

    int colorIndex = 0;
    data.forEach((category, amount) {
      final percentage = (amount / total) * 100;
      if (percentage > 0.5) { // Only show sections that are at least 0.5%
        sections.add(
          PieChartSectionData(
            value: amount,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: size * 0.3,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            color: colors[colorIndex % colors.length],
          ),
        );
        colorIndex++;
      }
    });

    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: size * 0.2,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {},
          ),
        ),
      ),
    );
  }
}