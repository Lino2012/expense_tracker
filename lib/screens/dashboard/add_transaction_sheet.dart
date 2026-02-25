import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_models.dart' as models; 
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final models.Transaction? transactionToEdit; // Use models.Transaction

  const AddTransactionSheet({super.key, this.transactionToEdit});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  models.TransactionType _selectedType = models.TransactionType.expense; // Use models.TransactionType
  models.Category _selectedCategory = models.Category.food; // Use models.Category
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // If editing existing transaction
    if (widget.transactionToEdit != null) {
      _titleController.text = widget.transactionToEdit!.title;
      _amountController.text = widget.transactionToEdit!.amount.toString();
      _selectedType = widget.transactionToEdit!.type;
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = widget.transactionToEdit!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      debugPrint('✅ Form validated, creating transaction...');
      
      final transaction = models.Transaction(
        id: widget.transactionToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory,
      );
      
      debugPrint('✅ Transaction created: ${transaction.title}, ${transaction.amount}');
      debugPrint('✅ Transaction type: ${transaction.type}');
      debugPrint('✅ Transaction category: ${transaction.category}');

      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      debugPrint('✅ TransactionProvider obtained');
      
      try {
        if (widget.transactionToEdit != null) {
          debugPrint('📝 Updating existing transaction...');
          await transactionProvider.updateTransaction(transaction);
        } else {
          debugPrint('➕ Adding new transaction...');
          await transactionProvider.addTransaction(transaction);
        }
        
        debugPrint('✅ Transaction saved successfully');
        
        if (mounted) {
          // Close the bottom sheet first
          Navigator.pop(context, true); // Return true to indicate success
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.transactionToEdit != null 
                  ? 'Transaction updated successfully' 
                  : 'Transaction added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error saving transaction: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      debugPrint('❌ Form validation failed');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title with edit indicator
                        Row(
                          children: [
                            Text(
                              widget.transactionToEdit != null 
                                  ? 'Edit Transaction' 
                                  : 'Add Transaction',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              color: colorScheme.onSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Type Toggle with animation
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeToggle(
                                  models.TransactionType.income,
                                  'Income',
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildTypeToggle(
                                  models.TransactionType.expense,
                                  'Expense',
                                  Icons.trending_down,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Title Field
                              TextFormField(
                                controller: _titleController,
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Transaction Title',
                                  labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                  prefixIcon: Icon(Icons.title, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                  filled: true,
                                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Amount Field with Currency
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Amount (${currencyProvider.currentCurrency.code})',
                                  labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                  prefixIcon: Icon(Icons.attach_money, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                  suffixText: currencyProvider.currentCurrency.symbol,
                                  suffixStyle: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Category Dropdown with better styling
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<models.Category>(
                                  initialValue: _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: Icon(Icons.category),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  items: models.Category.values.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: category.color.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              category.icon,
                                              size: 16,
                                              color: category.color,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            category.displayName,
                                            style: TextStyle(color: colorScheme.onSurface),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Date Picker with better styling
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Date',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Recurring toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Recurring Transaction',
                                      style: TextStyle(color: colorScheme.onSurface),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _isRecurring,
                                      onChanged: (value) {
                                        setState(() {
                                          _isRecurring = value;
                                        });
                                      },
                                      activeThumbColor: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.onSurface,
                                  side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedType == models.TransactionType.income 
                                      ? Colors.green 
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  widget.transactionToEdit != null ? 'Update' : 'Save',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTypeToggle(models.TransactionType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}