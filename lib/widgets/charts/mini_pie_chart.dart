import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_models.dart' as models;

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
    
    debugPrint('🎯 MiniPieChart - Building with data: $data');
    debugPrint('🎯 MiniPieChart - Data entries count: ${data.length}');
    
    if (data.isEmpty) {
      debugPrint('🎯 MiniPieChart - No data, showing empty state');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.pie_chart_outline,
            size: size * 0.4,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    final total = data.values.fold(0.0, (sum, value) => sum + value);
    debugPrint('🎯 MiniPieChart - Total amount: $total');
    
    // Sort entries by value (highest first)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    debugPrint('🎯 MiniPieChart - Sorted entries:');
    for (var entry in sortedEntries) {
      final percentage = (entry.value / total) * 100;
      debugPrint('   - ${entry.key}: ${entry.value} (${percentage.toStringAsFixed(1)}%)');
    }

    // Create sections for pie chart
    final List<PieChartSectionData> sections = [];
    
    for (var entry in sortedEntries) {
      final percentage = (entry.value / total) * 100;
      
      // Find the matching category to get its color
      Color sectionColor;
      try {
        final category = models.Category.values.firstWhere(
          (c) => c.displayName == entry.key,
          orElse: () => models.Category.other,
        );
        sectionColor = category.color;
        debugPrint('🎯 MiniPieChart - Category ${entry.key} color: $sectionColor');
      } catch (e) {
        // Fallback color based on index
        sectionColor = Colors.primaries[sections.length % Colors.primaries.length];
        debugPrint('🎯 MiniPieChart - Using fallback color for ${entry.key}');
      }
      
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: percentage > 3 ? '${percentage.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: sectionColor,
          radius: size * 0.3,
          titlePositionPercentageOffset: 0.55,
          showTitle: percentage > 3,
        ),
      );
    }

    debugPrint('🎯 MiniPieChart - Created ${sections.length} sections');

    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: size * 0.25,
          sectionsSpace: 1,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}