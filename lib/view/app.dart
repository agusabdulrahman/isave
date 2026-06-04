import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

part 'core/app_shell.dart';
part 'home/home_view.dart';
part 'wallet/wallet_view.dart';
part 'goals/goals_view.dart';
part 'profile/profile_view.dart';

enum TransactionType { income, expense }

enum TransactionMode { expense, income, transfer }

enum AccountKind { bank, cash }

enum IntervalUnit { day, week, month, year }

enum BudgetResetMode { autoMonthly, manualMonthly }

class Account {
  Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.currency,
    required this.balance,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final String currency;
  double balance;

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: map['kind'] == 'bank' ? AccountKind.bank : AccountKind.cash,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final TransactionType type;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}

class TransactionEntry {
  TransactionEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.type,
    required this.accountId,
    this.note,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final TransactionType type;
  final String accountId;
  final String? note;

  factory TransactionEntry.fromMap(
      Map<String, dynamic> map, String categoryName) {
    return TransactionEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      category: categoryName,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      date: DateTime.parse(map['occurred_at'] as String),
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      accountId: map['account_id'] as String,
      note: map['note'] as String?,
    );
  }
}

class RecurringTransaction {
  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.intervalUnit,
    required this.intervalCount,
    required this.nextRun,
    required this.isActive,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final String currency;
  final TransactionType type;
  final String accountId;
  final String? categoryId;
  final IntervalUnit intervalUnit;
  final int intervalCount;
  DateTime nextRun;
  final bool isActive;
  final String? note;

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String?,
      intervalUnit: IntervalUnit.values.firstWhere(
        (unit) => unit.name == map['interval_unit'],
        orElse: () => IntervalUnit.month,
      ),
      intervalCount: map['interval_count'] as int,
      nextRun: DateTime.parse(map['next_run'] as String),
      isActive: map['is_active'] as bool,
      note: map['note'] as String?,
    );
  }
}

class AppState extends ChangeNotifier {
  AppState({required this.userId});

  final String userId;
  bool _loaded = false;
  bool _busyRecurring = false;

  final Map<String, double> monthlyBudgets = {
    'USD': 654,
    'IDR': 2500000,
  };
  final Map<String, double> manualMonthlyBudgets = {};
  BudgetResetMode budgetResetMode = BudgetResetMode.autoMonthly;

  String selectedCurrency = 'IDR';

  List<Account> accounts = [];
  List<Category> categories = [];
  List<TransactionEntry> transactions = [];
  List<RecurringTransaction> recurring = [];

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final accountRows = await supabase
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    accounts =
        (accountRows as List).map((row) => Account.fromMap(row)).toList();

    if (accounts.isEmpty) {
      await supabase.from('accounts').insert([
        {
          'user_id': userId,
          'name': 'Cash Wallet USD',
          'kind': 'cash',
          'currency': 'USD',
          'balance': 0,
        },
        {
          'user_id': userId,
          'name': 'Cash Wallet IDR',
          'kind': 'cash',
          'currency': 'IDR',
          'balance': 0,
        },
      ]);
      final refreshed = await supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      accounts =
          (refreshed as List).map((row) => Account.fromMap(row)).toList();
    }

    final categoryRows = await supabase
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    categories =
        (categoryRows as List).map((row) => Category.fromMap(row)).toList();

    if (categories.isEmpty) {
      await supabase.from('categories').insert([
        {'user_id': userId, 'name': 'Daily expenses', 'type': 'expense'},
        {'user_id': userId, 'name': 'Transport', 'type': 'expense'},
        {'user_id': userId, 'name': 'Food', 'type': 'expense'},
        {'user_id': userId, 'name': 'Clothing', 'type': 'expense'},
        {'user_id': userId, 'name': 'Utilities', 'type': 'expense'},
        {'user_id': userId, 'name': 'Entertainment', 'type': 'expense'},
        {'user_id': userId, 'name': 'Salary', 'type': 'income'},
        {'user_id': userId, 'name': 'Gift', 'type': 'income'},
        {'user_id': userId, 'name': 'Bonus', 'type': 'income'},
        {'user_id': userId, 'name': 'Refund', 'type': 'income'},
      ]);
      final refreshed = await supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      categories =
          (refreshed as List).map((row) => Category.fromMap(row)).toList();
    }

    final transactionRows = await supabase
        .from('transactions')
        .select(
            'id,title,amount,currency,occurred_at,type,account_id,note,category_id')
        .eq('user_id', userId)
        .order('occurred_at', ascending: false);

    final categoryMap = {for (final cat in categories) cat.id: cat.name};
    transactions = (transactionRows as List)
        .map((row) => TransactionEntry.fromMap(
            row, categoryMap[row['category_id']] ?? 'Uncategorized'))
        .toList();

    final recurringRows = await supabase
        .from('recurring_transactions')
        .select()
        .eq('user_id', userId)
        .order('next_run');
    recurring = (recurringRows as List)
        .map((row) => RecurringTransaction.fromMap(row))
        .toList();

    await _applyDueRecurring();

    _loaded = true;
    notifyListeners();
  }

  Future<void> _applyDueRecurring() async {
    if (_busyRecurring) return;
    _busyRecurring = true;
    final now = DateTime.now();

    final due = recurring
        .where((entry) => entry.isActive && !entry.nextRun.isAfter(now))
        .toList();
    if (due.isEmpty) {
      _busyRecurring = false;
      return;
    }

    for (final rule in due) {
      final createdAt = rule.nextRun;
      final transactionInsert = {
        'user_id': userId,
        'account_id': rule.accountId,
        'category_id': rule.categoryId,
        'title': rule.title,
        'note': rule.note ?? 'Auto recorded',
        'amount': rule.amount,
        'type': rule.type == TransactionType.income ? 'income' : 'expense',
        'currency': rule.currency,
        'occurred_at': createdAt.toIso8601String(),
      };
      await supabase.from('transactions').insert(transactionInsert);

      final account = accounts.firstWhere((acc) => acc.id == rule.accountId);
      if (rule.type == TransactionType.income) {
        account.balance += rule.amount;
      } else {
        account.balance -= rule.amount;
      }
      await supabase
          .from('accounts')
          .update({'balance': account.balance}).eq('id', account.id);

      var next = rule.nextRun;
      while (!next.isAfter(now)) {
        next = addInterval(next, rule.intervalUnit, rule.intervalCount);
      }
      rule.nextRun = next;
      await supabase
          .from('recurring_transactions')
          .update({'next_run': next.toIso8601String()}).eq('id', rule.id);
    }

    await loadFresh();
    _busyRecurring = false;
  }

  Future<void> loadFresh() async {
    _loaded = false;
    await load();
  }

  void setCurrency(String currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  double totalBalanceForCurrency(String currency) {
    return accounts
        .where((acc) => acc.currency == currency)
        .fold(0, (sum, acc) => sum + acc.balance);
  }

  double get totalIncomeThisMonth =>
      _sumByType(TransactionType.income, selectedCurrency);

  double get totalExpenseThisMonth =>
      _sumByType(TransactionType.expense, selectedCurrency);

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  double budgetForMonth(String currency, DateTime date) {
    final defaultBudget = monthlyBudgets[currency] ?? 0;
    if (budgetResetMode == BudgetResetMode.autoMonthly) {
      return defaultBudget;
    }
    final key = '${_monthKey(date)}|$currency';
    return manualMonthlyBudgets[key] ?? 0;
  }

  void setBudgetResetMode(BudgetResetMode mode) {
    budgetResetMode = mode;
    notifyListeners();
  }

  void setDefaultBudgetForCurrency(String currency, double amount) {
    monthlyBudgets[currency] = amount;
    notifyListeners();
  }

  void setManualBudgetForMonth({
    required String currency,
    required DateTime month,
    required double amount,
  }) {
    final key = '${_monthKey(DateTime(month.year, month.month))}|$currency';
    manualMonthlyBudgets[key] = amount;
    notifyListeners();
  }

  double get remainingBudget {
    final budget = budgetForMonth(selectedCurrency, DateTime.now());
    return max(0, budget - totalExpenseThisMonth);
  }

  double get budgetProgress {
    final budget = budgetForMonth(selectedCurrency, DateTime.now());
    return budget == 0 ? 0 : (totalExpenseThisMonth / budget).clamp(0, 1);
  }

  List<TransactionEntry> get recentTransactions {
    return transactions
        .where((entry) => entry.currency == selectedCurrency)
        .take(6)
        .toList();
  }

  List<double> weeklyBalanceTrend(String currency) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final buckets = List<double>.filled(7, 0);

    for (final entry
        in transactions.where((entry) => entry.currency == currency)) {
      final dayIndex = entry.date.difference(start).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        final value =
            entry.type == TransactionType.income ? entry.amount : -entry.amount;
        buckets[dayIndex] += value;
      }
    }

    double running = totalBalanceForCurrency(currency) -
        buckets.fold(0, (sum, value) => sum + value);
    final trend = <double>[];
    for (final delta in buckets) {
      running += delta;
      trend.add(running);
    }

    final minValue = trend.reduce(min);
    final maxValue = trend.reduce(max);
    final span = max(1, maxValue - minValue);
    return trend.map((value) => (value - minValue) / span).toList();
  }

  Future<void> addTransaction({
    required String title,
    required String? categoryId,
    required String accountId,
    required double amount,
    required TransactionType type,
    required bool autoRecorded,
    bool createRecurring = false,
    IntervalUnit intervalUnit = IntervalUnit.month,
    int intervalCount = 1,
    DateTime? occurredAt,
  }) async {
    final account = accounts.firstWhere((acc) => acc.id == accountId);
    final currency = account.currency;
    final createdAt = occurredAt ?? DateTime.now();

    await supabase.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'title': title,
      'note': autoRecorded ? 'Auto recorded' : null,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'currency': currency,
      'occurred_at': createdAt.toIso8601String(),
    });

    if (type == TransactionType.income) {
      account.balance += amount;
    } else {
      account.balance -= amount;
    }

    await supabase
        .from('accounts')
        .update({'balance': account.balance}).eq('id', accountId);

    if (createRecurring) {
      final nextRun = addInterval(createdAt, intervalUnit, intervalCount);
      await supabase.from('recurring_transactions').insert({
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'title': title,
        'note': autoRecorded ? 'Auto recorded' : null,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'currency': currency,
        'interval_unit': intervalUnit.name,
        'interval_count': intervalCount,
        'next_run': nextRun.toIso8601String(),
        'is_active': true,
      });
    }

    await loadFresh();
  }

  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    DateTime? occurredAt,
  }) async {
    if (fromAccountId == toAccountId) return;
    final from = accounts.firstWhere((acc) => acc.id == fromAccountId);
    final to = accounts.firstWhere((acc) => acc.id == toAccountId);
    if (from.currency != to.currency) return;
    final createdAt = occurredAt ?? DateTime.now();

    await supabase.from('transactions').insert([
      {
        'user_id': userId,
        'account_id': fromAccountId,
        'category_id': null,
        'title': 'Transfer to ${to.name}',
        'note': null,
        'amount': amount,
        'type': 'expense',
        'currency': from.currency,
        'occurred_at': createdAt.toIso8601String(),
      },
      {
        'user_id': userId,
        'account_id': toAccountId,
        'category_id': null,
        'title': 'Transfer from ${from.name}',
        'note': null,
        'amount': amount,
        'type': 'income',
        'currency': to.currency,
        'occurred_at': createdAt.toIso8601String(),
      },
    ]);

    from.balance -= amount;
    to.balance += amount;
    await supabase
        .from('accounts')
        .update({'balance': from.balance}).eq('id', from.id);
    await supabase
        .from('accounts')
        .update({'balance': to.balance}).eq('id', to.id);

    await loadFresh();
  }

  Future<void> updateTransactionBasic({
    required String transactionId,
    required String title,
    required double amount,
  }) async {
    final entry = transactions.firstWhere((item) => item.id == transactionId);
    final account = accounts.firstWhere((acc) => acc.id == entry.accountId);

    final oldEffect =
        entry.type == TransactionType.income ? entry.amount : -entry.amount;
    final newEffect = entry.type == TransactionType.income ? amount : -amount;
    final delta = newEffect - oldEffect;

    await supabase
        .from('transactions')
        .update({
          'title': title,
          'amount': amount,
        })
        .eq('id', transactionId)
        .eq('user_id', userId);

    account.balance += delta;
    await supabase
        .from('accounts')
        .update({'balance': account.balance}).eq('id', account.id);

    await loadFresh();
  }

  Future<void> deleteTransaction({
    required String transactionId,
  }) async {
    final entry = transactions.firstWhere((item) => item.id == transactionId);
    final account = accounts.firstWhere((acc) => acc.id == entry.accountId);
    final effect =
        entry.type == TransactionType.income ? entry.amount : -entry.amount;

    account.balance -= effect;
    await supabase
        .from('accounts')
        .update({'balance': account.balance}).eq('id', account.id);

    await supabase
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);

    await loadFresh();
  }

  double _sumByType(TransactionType type, String currency) {
    final now = DateTime.now();
    return transactions.where((entry) {
      return entry.type == type &&
          entry.currency == currency &&
          entry.date.month == now.month &&
          entry.date.year == now.year;
    }).fold(0, (sum, entry) => sum + entry.amount);
  }
}

DateTime addInterval(DateTime date, IntervalUnit unit, int count) {
  switch (unit) {
    case IntervalUnit.day:
      return date.add(Duration(days: count));
    case IntervalUnit.week:
      return date.add(Duration(days: 7 * count));
    case IntervalUnit.month:
      final newMonth = date.month + count;
      return DateTime(
          date.year, newMonth, date.day, date.hour, date.minute, date.second);
    case IntervalUnit.year:
      return DateTime(date.year + count, date.month, date.day, date.hour,
          date.minute, date.second);
  }
}

String formatMoney(double value, String currency) {
  final rounded = value.round();
  if (currency == 'IDR') {
    final text = rounded
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return 'Rp$text';
  }
  final text = rounded
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  return '\$$text';
}
