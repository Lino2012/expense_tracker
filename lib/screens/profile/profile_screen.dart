import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/profile_avatar.dart'; // Add this import
import '../../models/app_models.dart' as models;
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool _isSaving = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    debugPrint('📱 ProfileScreen - initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    debugPrint('📱 ProfileScreen - User: ${authProvider.currentUser?.fullName ?? 'No user'}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Update user functionality
  Future<void> _updateUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = models.User(
        id: user.id,
        fullName: _nameController.text.trim(),
        email: user.email,
        password: user.password,
        monthlySalary: user.monthlySalary,
        currency: user.currency,
        themeMode: user.themeMode,
        profileImagePath: user.profileImagePath,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _db.updateUser(updatedUser);
      await authProvider.updateUserProfile(_nameController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
      }
    }
  }

  // Export data functionality
  Future<void> _exportData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final exportData = {
        'user': {
          'id': user.id,
          'fullName': user.fullName,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
        },
        'transactions': transactionProvider.transactions.map((t) => {
          'id': t.id,
          'title': t.title,
          'amount': t.amount,
          'date': t.date.toIso8601String(),
          'type': t.type.toString(),
          'category': t.category.displayName,
          'note': t.note,
        }).toList(),
        'statistics': {
          'totalIncome': transactionProvider.totalIncome,
          'totalExpense': transactionProvider.totalExpense,
          'balance': transactionProvider.balance,
          'transactionCount': transactionProvider.transactions.length,
        },
        'exportDate': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(exportData);
      
      await Share.share(
        jsonString,
        subject: 'Expensio Data Export',
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error exporting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Account deletion
  Future<void> _deleteAccount() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you absolutely sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final db = await _db.database;
      await db.delete('transactions', where: 'userId = ?', whereArgs: [user.id]);
      await db.delete('budgets', where: 'userId = ?', whereArgs: [user.id]);
      await db.delete('categories', where: 'userId = ?', whereArgs: [user.id]);
      await db.delete('users', where: 'id = ?', whereArgs: [user.id]);

      await authProvider.logout(transactionProvider);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/login');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProvider.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'User not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in again',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    _nameController.text = user.fullName;
    _emailController.text = user.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          const CurrencySelector(),
          if (!_isSaving)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _isEditing ? _updateUserProfile : () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal Info', icon: Icon(Icons.person)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Personal Info Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.7),
                        colorScheme.secondary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        imagePath: user.profileImagePath,
                        userName: user.fullName,
                        radius: 50,
                        onImageChanged: () {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInfoField(
                          context,
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: user.fullName,
                          controller: _nameController,
                          isEditing: _isEditing,
                        ),
                        const Divider(height: 24),
                        
                        _buildInfoField(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                          controller: _emailController,
                          isEditing: false,
                          enabled: false,
                        ),
                        const Divider(height: 24),
                        
                        _buildInfoDisplay(
                          icon: Icons.calendar_today,
                          label: 'Member Since',
                          value: DateFormat('MMMM dd, yyyy').format(user.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              currencyProvider.currentCurrency.symbol,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: const Text('Currency'),
                          subtitle: Text('${currencyProvider.currentCurrency.code} - ${currencyProvider.currentCurrency.symbol}'),
                          trailing: PopupMenuButton<Currency>(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onSelected: (Currency currency) {
                              currencyProvider.setCurrency(currency);
                            },
                            itemBuilder: (context) => currencyProvider.currencies.map((currency) {
                              return PopupMenuItem(
                                value: currency,
                                child: Row(
                                  children: [
                                    Text(
                                      currency.symbol,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(currency.code),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 24),
                        
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: const Text('Theme'),
                          subtitle: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                          trailing: Switch(
                            value: isDark,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeThumbColor: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                context,
                                label: 'Transactions',
                                value: transactionProvider.transactions.length.toString(),
                                icon: Icons.receipt,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatBox(
                                context,
                                label: 'Categories',
                                value: transactionProvider.getCategoryBreakdown(DateTime.now().year, null).length.toString(),
                                icon: Icons.category,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                context,
                                label: 'Total Income',
                                value: currencyProvider.formatAmount(transactionProvider.totalIncome),
                                icon: Icons.trending_up,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatBox(
                                context,
                                label: 'Total Expense',
                                value: currencyProvider.formatAmount(transactionProvider.totalExpense),
                                icon: Icons.trending_down,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Danger Zone
                Card(
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.download, color: Colors.red),
                          ),
                          title: const Text('Export Data'),
                          subtitle: const Text('Download your transaction history'),
                          onTap: _exportData,
                        ),
                        const Divider(height: 24),
                        
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.delete_forever, color: Colors.red),
                          ),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                          subtitle: const Text(
                            'Permanently delete your account and all data',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Statistics Tab
          _buildStatisticsTab(context, transactionProvider, currencyProvider),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isEditing && enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDisplay({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(
    BuildContext context,
    TransactionProvider transactionProvider,
    CurrencyProvider currencyProvider,
  ) {
    final now = DateTime.now();
    final yearlyIncome = transactionProvider.getYearlyIncome(now.year);
    final yearlyExpense = transactionProvider.getYearlyExpense(now.year);
    final yearlySavings = yearlyIncome - yearlyExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Yearly Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Income',
                          value: currencyProvider.formatAmount(yearlyIncome),
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Expense',
                          value: currencyProvider.formatAmount(yearlyExpense),
                          icon: Icons.trending_down,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Savings',
                          value: currencyProvider.formatAmount(yearlySavings),
                          icon: Icons.savings,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Transactions',
                          value: transactionProvider.transactions.length.toString(),
                          icon: Icons.receipt,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Current Month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Income',
                          value: currencyProvider.formatAmount(
                            transactionProvider.getMonthlyIncome(now.year)[now.month] ?? 0,
                          ),
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          context,
                          label: 'Expense',
                          value: currencyProvider.formatAmount(
                            transactionProvider.getMonthlyExpenses(now.year)[now.month] ?? 0,
                          ),
                          icon: Icons.trending_down,
                          color: Colors.red,
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
    );
  }
}