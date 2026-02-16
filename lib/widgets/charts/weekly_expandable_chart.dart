import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyExpandableChart extends StatefulWidget {
  final String month;
  final int monthNumber;
  final int year;
  final double totalExpense;
  final Map<int, double> weeklyExpenses;

  const WeeklyExpandableChart({
    super.key,
    required this.month,
    required this.monthNumber,
    required this.year,
    required this.totalExpense,
    required this.weeklyExpenses,
  });

  @override
  State<WeeklyExpandableChart> createState() => _WeeklyExpandableChartState();
}

class _WeeklyExpandableChartState extends State<WeeklyExpandableChart> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                widget.month.substring(0, 3),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(widget.month),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'en_PH',
                    symbol: '₱',
                    decimalDigits: 2,
                  ).format(widget.totalExpense),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...List.generate(5, (index) {
                    final week = index + 1;
                    final weekExpense = widget.weeklyExpenses[week] ?? 0;
                    
                    if (weekExpense == 0) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'W$week',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Week $week',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: weekExpense / widget.totalExpense,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                  minHeight: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            NumberFormat.currency(
                              locale: 'en_PH',
                              symbol: '₱',
                              decimalDigits: 2,
                            ).format(weekExpense),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}