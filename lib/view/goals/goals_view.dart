part of 'package:isaveup/view/app.dart';

enum _ReportRange { m1, m3, m6, y1 }

extension on _ReportRange {
  String get label {
    switch (this) {
      case _ReportRange.m1:
        return '1M';
      case _ReportRange.m3:
        return '3M';
      case _ReportRange.m6:
        return '6M';
      case _ReportRange.y1:
        return '1Y';
    }
  }

  int get months {
    switch (this) {
      case _ReportRange.m1:
        return 1;
      case _ReportRange.m3:
        return 3;
      case _ReportRange.m6:
        return 6;
      case _ReportRange.y1:
        return 12;
    }
  }

  String get summaryLabel {
    switch (this) {
      case _ReportRange.m1:
        return 'this month';
      case _ReportRange.m3:
        return 'last 3 months';
      case _ReportRange.m6:
        return 'last 6 months';
      case _ReportRange.y1:
        return 'last 1 year';
    }
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportRange _incomeExpenseRange = _ReportRange.m1;
  _ReportRange _profitLossRange = _ReportRange.m1;

  DateTime _rangeStart(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - (months - 1), 1);
  }

  double _sumByTypeForRange(
      AppState state, TransactionType type, _ReportRange range) {
    final start = _rangeStart(range.months);
    final currency = state.selectedCurrency;
    return state.transactions.where((entry) {
      return entry.currency == currency &&
          entry.type == type &&
          !entry.date.isBefore(start);
    }).fold(0, (sum, entry) => sum + entry.amount);
  }

  List<double> _profitBarsForRange(AppState state, _ReportRange range) {
    final now = DateTime.now();
    final start = _rangeStart(range.months);
    final totalMs = now.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    if (totalMs <= 0) return const [0.55];

    final bucketCount = range.months == 1 ? 4 : 6;
    final bucketWidth = totalMs / bucketCount;
    final buckets = List<double>.filled(bucketCount, 0);
    final currency = state.selectedCurrency;

    for (final entry in state.transactions) {
      if (entry.currency != currency || entry.date.isBefore(start)) continue;
      final offset =
          entry.date.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      final index = (offset / bucketWidth).floor().clamp(0, bucketCount - 1);
      final value =
          entry.type == TransactionType.income ? entry.amount : -entry.amount;
      buckets[index] += value;
    }

    final minBucket = buckets.reduce(min);
    final maxBucket = buckets.reduce(max);
    final span = maxBucket - minBucket;
    if (span == 0) return List<double>.filled(bucketCount, 0.55);

    return buckets.map((v) => 0.2 + (((v - minBucket) / span) * 0.8)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final budget = state.budgetForMonth(state.selectedCurrency, DateTime.now());
    final expenses =
        _sumByTypeForRange(state, TransactionType.expense, _incomeExpenseRange);
    final income =
        _sumByTypeForRange(state, TransactionType.income, _incomeExpenseRange);
    final profitExpenses =
        _sumByTypeForRange(state, TransactionType.expense, _profitLossRange);
    final profitIncome =
        _sumByTypeForRange(state, TransactionType.income, _profitLossRange);
    final profit = profitIncome - profitExpenses;
    final profitBars = _profitBarsForRange(state, _profitLossRange);

    return _DarkShell(
      title: 'Reports',
      child: Column(
        children: [
          FadeSlideIn(
            delay: 0.0,
            child: ReportBudgetCard(
              onConfigure: () => showBudgetSettingSheet(context),
              progress: state.budgetProgress,
              remaining: state.remainingBudget,
              total: budget,
              currency: state.selectedCurrency,
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: 0.08,
            child: ReportIncomeExpenseCard(
              expenses: expenses,
              income: income,
              currency: state.selectedCurrency,
              selectedRange: _incomeExpenseRange,
              periodLabel: _incomeExpenseRange.summaryLabel,
              onRangeChanged: (range) {
                setState(() => _incomeExpenseRange = range);
              },
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: 0.16,
            child: ProfitLossCard(
              profit: profit,
              currency: state.selectedCurrency,
              selectedRange: _profitLossRange,
              periodLabel: _profitLossRange.summaryLabel,
              bars: profitBars,
              onRangeChanged: (range) {
                setState(() => _profitLossRange = range);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkShell extends StatelessWidget {
  const _DarkShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFB5FF4D),
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class ReportBudgetCard extends StatelessWidget {
  const ReportBudgetCard(
      {super.key,
      required this.progress,
      required this.remaining,
      required this.total,
      required this.currency,
      required this.onConfigure});

  final double progress;
  final double remaining;
  final double total;
  final String currency;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final spent = max(0.0, total - remaining);
    final spentPercent = (progress * 100).clamp(0, 999).round();
    final remainingPercent =
        total <= 0 ? 0 : ((remaining / total) * 100).clamp(0, 100).round();
    final isLow = total > 0 && remaining / total <= 0.2;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2E36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BudgetDonut(
                progress: progress,
                label: '$spentPercent%',
                size: 84,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly Budget',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFE9F2D0),
                                ),
                          ),
                        ),
                        FilledButton(
                          onPressed: onConfigure,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB5FF4D),
                            foregroundColor: const Color(0xFF111214),
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                          child: const Text('Set Budget'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available out of ${formatMoney(total, currency)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              formatMoney(remaining, currency),
                              key: ValueKey(remaining),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            currency,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BudgetMetric(
                  label: 'Spent',
                  value: formatMoney(spent, currency),
                  color: const Color(0xFFFFD166),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BudgetMetric(
                  label: 'Available',
                  value: '$remainingPercent%',
                  color: const Color(0xFFB5FF4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isLow
                    ? Icons.trending_down_rounded
                    : Icons.check_circle_outline_rounded,
                color: const Color(0xFFB5FF4D),
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isLow
                      ? 'Low balance remaining'
                      : 'Budget still healthy for this month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB5FF4D),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryStrip extends StatelessWidget {
  const _ReportSummaryStrip({
    required this.expenses,
    required this.income,
    required this.currency,
  });

  final double expenses;
  final double income;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final net = income - expenses;
    final netColor =
        net >= 0 ? const Color(0xFFB5FF4D) : const Color(0xFFFF7A7A);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.south_west_rounded,
            label: 'Income',
            amount: formatMoney(income, currency),
            accent: const Color(0xFFB5FF4D),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.north_east_rounded,
            label: 'Expense',
            amount: formatMoney(expenses, currency),
            accent: const Color(0xFFFFD166),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.show_chart_rounded,
            label: 'Net',
            amount: formatMoney(net.abs(), currency),
            accent: netColor,
          ),
        ),
      ],
    );
  }
}

class _ComparisonBars extends StatelessWidget {
  const _ComparisonBars({
    required this.expenses,
    required this.income,
    required this.currency,
  });

  final double expenses;
  final double income;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final maxValue = max(1.0, max(expenses, income));
    return Column(
      children: [
        _ComparisonBar(
          label: 'Income',
          value: income,
          total: maxValue,
          amount: formatMoney(income, currency),
          color: const Color(0xFFB5FF4D),
        ),
        const SizedBox(height: 12),
        _ComparisonBar(
          label: 'Expenses',
          value: expenses,
          total: maxValue,
          amount: formatMoney(expenses, currency),
          color: const Color(0xFFFFD166),
        ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.total,
    required this.amount,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              amount,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(color: const Color(0xFF30343D)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void showBudgetSettingSheet(BuildContext context) {
  final state = AppStateScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1E22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AppStateScope(
      notifier: state,
      child: const _BudgetSettingSheet(),
    ),
  );
}

class _BudgetSettingSheet extends StatefulWidget {
  const _BudgetSettingSheet();

  @override
  State<_BudgetSettingSheet> createState() => _BudgetSettingSheetState();
}

class _BudgetSettingSheetState extends State<_BudgetSettingSheet> {
  BudgetResetMode? _mode;
  DateTime? _selectedMonth;
  final _amountController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppStateScope.of(context);
    _mode = state.budgetResetMode;
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _amountController.text = state
        .budgetForMonth(state.selectedCurrency, _selectedMonth!)
        .round()
        .toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2100, 12),
      initialDate: _selectedMonth,
      helpText: 'Select budget month',
    );
    if (picked == null) return;
    final selected = DateTime(picked.year, picked.month);
    final state = AppStateScope.of(context);
    setState(() {
      _selectedMonth = selected;
      _amountController.text = state
          .budgetForMonth(state.selectedCurrency, _selectedMonth!)
          .round()
          .toString();
    });
  }

  void _save() {
    final state = AppStateScope.of(context);
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed < 0) return;

    state.setBudgetResetMode(_mode!);
    if (_mode == BudgetResetMode.autoMonthly) {
      state.setDefaultBudgetForCurrency(state.selectedCurrency, parsed);
    } else {
      state.setManualBudgetForMonth(
        currency: state.selectedCurrency,
        month: _selectedMonth!,
        amount: parsed,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final selectedMonth =
        _selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);
    final currentMode = _mode ?? BudgetResetMode.autoMonthly;
    final monthLabel =
        '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Settings (${state.selectedCurrency})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<BudgetResetMode>(
              segments: const [
                ButtonSegment(
                  value: BudgetResetMode.autoMonthly,
                  label: Text('Auto Monthly'),
                ),
                ButtonSegment(
                  value: BudgetResetMode.manualMonthly,
                  label: Text('Manual per Month'),
                ),
              ],
              selected: {currentMode},
              style: SegmentedButton.styleFrom(
                backgroundColor: const Color(0xFF2B2E34),
                foregroundColor: Colors.white70,
                selectedBackgroundColor: const Color(0xFFB5FF4D),
                selectedForegroundColor: const Color(0xFF111214),
              ),
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            if (currentMode == BudgetResetMode.manualMonthly) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _pickMonth,
                child: Text('Month: $monthLabel'),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Budget Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                suffixText: state.selectedCurrency,
                suffixStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D3036)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFB5FF4D)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5FF4D),
                  foregroundColor: const Color(0xFF111214),
                ),
                child: const Text('Save Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportIncomeExpenseCard extends StatelessWidget {
  const ReportIncomeExpenseCard(
      {super.key,
      required this.expenses,
      required this.income,
      required this.currency,
      required this.selectedRange,
      required this.periodLabel,
      required this.onRangeChanged});

  final double expenses;
  final double income;
  final String currency;
  final _ReportRange selectedRange;
  final String periodLabel;
  final ValueChanged<_ReportRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2E36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Expenses & Income',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
              Text(
                periodLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _ReportRange.values
                .map((range) => _FilterChip(
                      label: range.label,
                      selected: range == selectedRange,
                      onTap: () => onRangeChanged(range),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          _ReportSummaryStrip(
            expenses: expenses,
            income: income,
            currency: currency,
          ),
          const SizedBox(height: 18),
          _ComparisonBars(
            expenses: expenses,
            income: income,
            currency: currency,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2C2F36) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2C2F36)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF17191D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2E34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class ProfitLossCard extends StatelessWidget {
  const ProfitLossCard({
    super.key,
    required this.profit,
    required this.currency,
    required this.selectedRange,
    required this.periodLabel,
    required this.bars,
    required this.onRangeChanged,
  });

  final double profit;
  final String currency;
  final _ReportRange selectedRange;
  final String periodLabel;
  final List<double> bars;
  final ValueChanged<_ReportRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit & Loss',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _ReportRange.values
                .map((range) => _FilterChip(
                      label: range.label,
                      selected: range == selectedRange,
                      onTap: () => onRangeChanged(range),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 110,
                  child: AnimatedProfitBars(bars: bars),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit for $periodLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(profit, currency),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedProfitBars extends StatefulWidget {
  const AnimatedProfitBars({super.key, required this.bars});

  final List<double> bars;

  @override
  State<AnimatedProfitBars> createState() => _AnimatedProfitBarsState();
}

class _AnimatedProfitBarsState extends State<AnimatedProfitBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedProfitBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ProfitBarsPainter(
            progress: _controller.value,
            bars: widget.bars,
          ),
        );
      },
    );
  }
}

class ProfitBarsPainter extends CustomPainter {
  ProfitBarsPainter({required this.progress, required this.bars});

  final double progress;
  final List<double> bars;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..style = PaintingStyle.fill;
    final width = size.width / (bars.length * 1.6);
    final gap = width * 0.6;

    for (var i = 0; i < bars.length; i++) {
      final x = i * (width + gap);
      final height = size.height * bars[i] * progress;
      barPaint.color =
          i == 2 ? const Color(0xFFB5FF4D) : const Color(0xFF2F3238);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, width, height),
          const Radius.circular(8),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProfitBarsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bars != bars;
}
