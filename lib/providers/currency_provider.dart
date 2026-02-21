import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Currency {
  usd('USD', '\$', 'en_US'),
  eur('EUR', '€', 'de_DE'),
  gbp('GBP', '£', 'en_GB'),
  jpy('JPY', '¥', 'ja_JP'),
  inr('INR', '₹', 'en_IN'),
  php('PHP', '₱', 'en_PH'),
  aud('AUD', 'A\$', 'en_AU'),
  cad('CAD', 'C\$', 'en_CA'),
  chf('CHF', 'Fr', 'de_CH'),
  cny('CNY', '¥', 'zh_CN');

  final String code;
  final String symbol;
  final String locale;
  const Currency(this.code, this.symbol, this.locale);
}

class CurrencyProvider extends ChangeNotifier {
  Currency _currentCurrency = Currency.php; // Default to PHP
  static const String _currencyKey = 'selected_currency';

  Currency get currentCurrency => _currentCurrency;

  CurrencyProvider() {
    loadCurrency();
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyIndex = prefs.getInt(_currencyKey) ?? 5; // Default to PHP (index 5)
    _currentCurrency = Currency.values[currencyIndex];
    notifyListeners();
  }

  Future<void> setCurrency(Currency currency) async {
    _currentCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currencyKey, currency.index);
    notifyListeners();
  }

  String formatAmount(double amount) {
    final numberFormat = NumberFormat.currency(
      locale: _currentCurrency.locale,
      symbol: _currentCurrency.symbol,
      decimalDigits: _currentCurrency == Currency.jpy ? 0 : 2,
    );
    return numberFormat.format(amount);
  }

  List<Currency> get currencies => Currency.values;
}