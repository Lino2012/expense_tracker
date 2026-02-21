import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: const Icon(Icons.attach_money),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Currency'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencyProvider.currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencyProvider.currencies[index];
                  final isSelected = currencyProvider.currentCurrency == currency;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? colorScheme.primary 
                          : Colors.grey.shade200,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      currency.code,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text('${currency.symbol} - ${currency.locale}'),
                    selected: isSelected,
                    onTap: () async {
                      await currencyProvider.setCurrency(currency);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency changed to ${currency.code}'),
                            backgroundColor: colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}