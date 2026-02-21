import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/app_models.dart';
import '../../widgets/charts/enhanced_monthly_chart.dart';
import '../../widgets/charts/weekly_expandable_chart.dart';
import '../../widgets/currency_selector.dart'; // Add this import

class YearlyAnalyticsScreen extends StatefulWidget {
  const YearlyAnalyticsScreen({super.key});

  @override
  State<YearlyAnalyticsScreen> createState() => _YearlyAnalyticsScreenState();
}

class _YearlyAnalyticsScreenState extends State<YearlyAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    // Get yearly data
    final yearlyIncome = transactionProvider.getYearlyIncome(_selectedYear);
    final yearlyExpense = transactionProvider.getYearlyExpense(_selectedYear);
    final yearlySavings = transactionProvider.getYearlySavings(_selectedYear);
    final monthlyAverage = transactionProvider.getMonthlyAverage(_selectedYear);
    final highestExpenseMonth = transactionProvider.getHighestExpenseMonth(_selectedYear);
    final highestExpenseMonthName = transactionProvider.getHighestExpenseMonthName(_selectedYear);
    final monthlyExpenses = transactionProvider.getMonthlyExpenses(_selectedYear);
    final monthlyIncomes = transactionProvider.getMonthlyIncome(_selectedYear);
    
    // Check if there's any data
    final hasData = yearlyIncome > 0 || yearlyExpense > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yearly Analytics'),
        actions: [
          const CurrencySelector(),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(themeProvider.isDarkMode),
              ),
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Monthly', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Categories', icon: Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          _buildOverviewTab(
            context, 
            hasData, 
            yearlyIncome, 
            yearlyExpense, 
            yearlySavings,
            monthlyAverage,
            highestExpenseMonth,
            highestExpenseMonthName,
            currencyProvider,
          ),

          // Monthly Breakdown Tab
          _buildMonthlyTab(
            context,
            hasData,
            monthlyExpenses,
            monthlyIncomes,
            transactionProvider,
            currencyProvider,
          ),

          // Categories Tab - Fix: Pass the correct provider
          _buildCategoriesTab(
            context,
            hasData,
            transactionProvider, // This is the correct parameter name
            currencyProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    bool hasData,
    double yearlyIncome,
    double yearlyExpense,
    double yearlySavings,
    double monthlyAverage,
    double highestExpenseMonth,
    String highestExpenseMonthName,
    CurrencyProvider currencyProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Selector
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedYear--;
                      });
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      _selectedYear.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedYear++;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!hasData)
            // Empty state
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics,
                      size: 50,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No data for $_selectedYear',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some transactions to see analytics',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Summary Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildSummaryCard(
                      context,
                      'Total Income',
                      yearlyIncome,
                      Colors.green,
                      Icons.trending_up,
                      currencyProvider,
                    ),
                    _buildSummaryCard(
                      context,
                      'Total Expense',
                      yearlyExpense,
                      Colors.red,
                      Icons.trending_down,
                      currencyProvider,
                    ),
                    _buildSummaryCard(
                      context,
                      'Total Savings',
                      yearlySavings,
                      Colors.blue,
                      Icons.savings,
                      currencyProvider,
                    ),
                    _buildSummaryCard(
                      context,
                      'Monthly Avg',
                      monthlyAverage,
                      Colors.orange,
                      Icons.calendar_month,
                      currencyProvider,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Additional Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Highest Expense Month',
                                highestExpenseMonthName,
                                currencyProvider.formatAmount(highestExpenseMonth),
                                Icons.arrow_upward,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Savings Rate',
                                '${((yearlySavings / yearlyIncome) * 100).toStringAsFixed(1)}%',
                                'of income',
                                Icons.percent,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Transaction Count',
                                _getTransactionCount().toString(),
                                'total',
                                Icons.receipt,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  int _getTransactionCount() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    return transactionProvider.transactions
        .where((t) => t.date.year == _selectedYear)
        .length;
  }

  Widget _buildMonthlyTab(
    BuildContext context,
    bool hasData,
    Map<int, double> monthlyExpenses,
    Map<int, double> monthlyIncomes,
    TransactionProvider transactionProvider,
    CurrencyProvider currencyProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Year selector for monthly tab
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedYear--;
                      });
                    },
                  ),
                  Text(
                    _selectedYear.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedYear++;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          if (!hasData)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bar_chart,
                      size: 50,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No monthly data for $_selectedYear',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Enhanced Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EnhancedMonthlyChart(
                      expenses: monthlyExpenses,
                      incomes: monthlyIncomes,
                      year: _selectedYear,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Weekly Breakdown List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthName = DateFormat('MMMM').format(DateTime(2024, month));
                    final monthlyExpense = monthlyExpenses[month] ?? 0;
                    
                    // Skip months with no data
                    if (monthlyExpense == 0) return const SizedBox.shrink();
                    
                    return WeeklyExpandableChart(
                      month: monthName,
                      monthNumber: month,
                      year: _selectedYear,
                      totalExpense: monthlyExpense,
                      weeklyExpenses: transactionProvider.getWeeklyExpenses(_selectedYear, month),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(
    BuildContext context,
    bool hasData,
    TransactionProvider transactionProvider, // Fixed parameter name
    CurrencyProvider currencyProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryData = transactionProvider.getCategoryBreakdown(_selectedYear, null);
    final totalExpense = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Year selector
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedYear--;
                      });
                    },
                  ),
                  Text(
                    _selectedYear.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedYear++;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (categoryData.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pie_chart,
                      size: 50,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No category data for $_selectedYear',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Category Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...categoryData.entries.map((entry) {
                      final percentage = (entry.value / totalExpense) * 100;
                      final category = Category.values.firstWhere(
                        (c) => c.displayName == entry.key,
                        orElse: () => Category.other,
                      );
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyProvider.formatAmount(entry.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
    CurrencyProvider currencyProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
            Text(
              currencyProvider.formatAmount(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String subValue,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subValue,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}