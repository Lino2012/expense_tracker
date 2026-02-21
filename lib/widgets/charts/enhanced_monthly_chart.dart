import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Add this import
import '../../providers/currency_provider.dart';

class EnhancedMonthlyChart extends StatefulWidget {
  final Map<int, double> expenses;
  final Map<int, double> incomes;
  final int year;

  const EnhancedMonthlyChart({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.year,
  });

  @override
  State<EnhancedMonthlyChart> createState() => _EnhancedMonthlyChartState();
}

class _EnhancedMonthlyChartState extends State<EnhancedMonthlyChart> {
  int? _touchedIndex;
  bool _showExpenses = true;
  bool _showIncomes = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    // Calculate max value for scaling
    final allValues = [
      ...widget.expenses.values,
      ...widget.incomes.values,
    ];
    final maxValue = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0;

    if (maxValue == 0) {
      return _buildEmptyState(colorScheme);
    }

    return Column(
      children: [
        // Legend and Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: Colors.green,
                label: 'Income',
                isSelected: _showIncomes,
                onTap: () {
                  setState(() {
                    _showIncomes = !_showIncomes;
                  });
                },
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: Colors.red,
                label: 'Expense',
                isSelected: _showExpenses,
                onTap: () {
                  setState(() {
                    _showExpenses = !_showExpenses;
                  });
                },
              ),
            ],
          ),
        ),
        
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: colorScheme.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = groupIndex + 1;
                    final monthName = DateFormat('MMM').format(DateTime(widget.year, month));
                    final isIncome = rodIndex == 0 && _showIncomes;
                    final value = rod.toY;
                    
                    return BarTooltipItem(
                      '$monthName\n${isIncome ? 'Income' : 'Expense'}\n${currencyProvider.formatAmount(value)}',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.spot?.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      if (value.toInt() >= 0 && value.toInt() < months.length) {
                        final isSelected = _touchedIndex == value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              color: isSelected 
                                  ? colorScheme.primary 
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          currencyProvider.formatAmount(value).split('.')[0],
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                    interval: maxValue / 5,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              barGroups: List.generate(12, (index) {
                final month = index + 1;
                final expense = widget.expenses[month] ?? 0;
                final income = widget.incomes[month] ?? 0;
                
                List<BarChartRodData> rods = [];
                
                if (_showIncomes && income > 0) {
                  rods.add(
                    BarChartRodData(
                      toY: income,
                      color: Colors.green,
                      width: _showExpenses && expense > 0 ? 10 : 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  );
                }
                
                if (_showExpenses && expense > 0) {
                  rods.add(
                    BarChartRodData(
                      toY: expense,
                      color: Colors.red,
                      width: _showIncomes && income > 0 ? 10 : 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  );
                }
                
                return BarChartGroupData(
                  x: index,
                  barRods: rods,
                  barsSpace: 2,
                );
              }),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available for ${widget.year}',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see analytics',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}