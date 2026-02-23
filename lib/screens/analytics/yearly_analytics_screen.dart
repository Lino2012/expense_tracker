import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/app_models.dart';
import '../../widgets/charts/enhanced_monthly_chart.dart';
import '../../widgets/charts/weekly_expandable_chart.dart';
import '../../widgets/charts/mini_pie_chart.dart';
import '../../widgets/currency_selector.dart';

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
    final categoryData = transactionProvider.getCategoryBreakdown(_selectedYear, null);
    
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
            categoryData,
            currencyProvider,
            transactionProvider,
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

          // Categories Tab
          _buildCategoriesTab(
            context,
            hasData,
            transactionProvider,
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
    Map<String, double> categoryData,
    CurrencyProvider currencyProvider,
    TransactionProvider transactionProvider,
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
                    _buildEnhancedSummaryCard(
                      context,
                      'Total Income',
                      yearlyIncome,
                      Colors.green,
                      Icons.trending_up,
                      currencyProvider,
                      '↑ ${((yearlyIncome / (yearlyIncome + yearlyExpense)) * 100).toStringAsFixed(1)}% of total',
                    ),
                    _buildEnhancedSummaryCard(
                      context,
                      'Total Expense',
                      yearlyExpense,
                      Colors.red,
                      Icons.trending_down,
                      currencyProvider,
                      '↓ ${((yearlyExpense / (yearlyIncome + yearlyExpense)) * 100).toStringAsFixed(1)}% of total',
                    ),
                    _buildEnhancedSummaryCard(
                      context,
                      'Total Savings',
                      yearlySavings,
                      Colors.blue,
                      Icons.savings,
                      currencyProvider,
                      '${((yearlySavings / yearlyIncome) * 100).toStringAsFixed(1)}% saved',
                    ),
                    _buildEnhancedSummaryCard(
                      context,
                      'Monthly Avg',
                      monthlyAverage,
                      Colors.orange,
                      Icons.calendar_month,
                      currencyProvider,
                      '${transactionProvider.transactions.length} transactions',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Preview Card with Mini Pie Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spending Categories',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: () {
                                _tabController.animateTo(2); // Switch to categories tab
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Mini Pie Chart
                            Expanded(
                              flex: 2,
                              child: MiniPieChart(
                                data: categoryData,
                                size: 120,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Top 3 Categories
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Categories',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._buildTopCategories(categoryData, yearlyExpense),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Additional Stats Card
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
                                'Highest Month',
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
                                'Transaction Count',
                                transactionProvider.transactions
                                    .where((t) => t.date.year == _selectedYear)
                                    .length
                                    .toString(),
                                'total',
                                Icons.receipt,
                                Colors.purple,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                'Categories Used',
                                categoryData.length.toString(),
                                'of 8',
                                Icons.category,
                                Colors.teal,
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

  // Helper method to build top categories
  List<Widget> _buildTopCategories(Map<String, double> categoryData, double totalExpense) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(3).map((entry) {
      final category = Category.values.firstWhere(
        (c) => c.displayName == entry.key,
        orElse: () => Category.other,
      );
      final percentage = (entry.value / totalExpense) * 100;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEnhancedSummaryCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
    CurrencyProvider currencyProvider,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyProvider.formatAmount(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: Column(
                      children: [
                        const Text(
                          'Monthly Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: EnhancedMonthlyChart(
                            expenses: monthlyExpenses,
                            incomes: monthlyIncomes,
                            year: _selectedYear,
                          ),
                        ),
                      ],
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
    TransactionProvider transactionProvider,
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
            Column(
              children: [
                // Category Breakdown Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Category Distribution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: MiniPieChart(
                            data: categoryData,
                            size: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Category List
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
                        ..._buildCategoryList(categoryData, totalExpense, currencyProvider),
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

  // Helper method to build category list
  List<Widget> _buildCategoryList(
    Map<String, double> categoryData, 
    double totalExpense,
    CurrencyProvider currencyProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return categoryData.entries.map((entry) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyProvider.formatAmount(entry.value),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
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