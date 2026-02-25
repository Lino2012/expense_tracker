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
    
    debugPrint('📊 MiniPieChart - Building with data: $data');
    debugPrint('📊 MiniPieChart - Data entries count: ${data.length}');
    
    if (data.isEmpty) {
      debugPrint('📊 MiniPieChart - No data, showing empty state');
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
    debugPrint('📊 MiniPieChart - Total amount: $total');
    
    final List<PieChartSectionData> sections = [];
    
    // Sort entries by value (highest first) for better visual order
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    debugPrint('📊 MiniPieChart - Sorted entries: ${sortedEntries.map((e) => "${e.key}: ${e.value}")}');

    // Pre-defined colors for categories that might not be found
    final fallbackColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    int fallbackIndex = 0;

    for (var entry in sortedEntries) {
      final percentage = (entry.value / total) * 100;
      debugPrint('📊 MiniPieChart - Category: ${entry.key}, Percentage: $percentage%');
      
      if (percentage > 0.5) { // Only show sections that are at least 0.5%
        
        // Find the matching category to get its color
        Color sectionColor;
        try {
          final category = models.Category.values.firstWhere(
            (c) => c.displayName == entry.key,
          );
          sectionColor = category.color;
          debugPrint('📊 MiniPieChart - Found category: ${entry.key}, Color: $sectionColor');
        } catch (e) {
          debugPrint('📊 MiniPieChart - Category not found: ${entry.key}, using fallback color');
          sectionColor = fallbackColors[fallbackIndex % fallbackColors.length];
          fallbackIndex++;
        }
        
        sections.add(
          PieChartSectionData(
            value: entry.value,
            title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '', // Only show % if >5%
            titleStyle: TextStyle(
              fontSize: percentage > 10 ? 10 : 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            color: sectionColor,
            radius: size * 0.3,
            titlePositionPercentageOffset: 0.6,
          ),
        );
      }
    }

    debugPrint('📊 MiniPieChart - Created ${sections.length} sections');

    // If we have no sections but have data, add all sections without percentages
    if (sections.isEmpty && sortedEntries.isNotEmpty) {
      debugPrint('📊 MiniPieChart - No sections with >0.5%, adding all sections without titles');
      for (var entry in sortedEntries) {
        Color sectionColor;
        try {
          final category = models.Category.values.firstWhere(
            (c) => c.displayName == entry.key,
          );
          sectionColor = category.color;
        } catch (e) {
          sectionColor = fallbackColors[fallbackIndex % fallbackColors.length];
          fallbackIndex++;
        }
        
        sections.add(
          PieChartSectionData(
            value: entry.value,
            title: '',
            color: sectionColor,
            radius: size * 0.3,
          ),
        );
      }
    }

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
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}