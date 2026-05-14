part of 'package:isaveup/view/app.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final budget = state.budgetForMonth(state.selectedCurrency, DateTime.now());
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
              expenses: state.totalExpenseThisMonth,
              income: state.totalIncomeThisMonth,
              currency: state.selectedCurrency,
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: 0.16,
            child: ProfitLossCard(
              profit: state.totalIncomeThisMonth - state.totalExpenseThisMonth,
              currency: state.selectedCurrency,
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
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFF2D3036),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFB5FF4D)),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Budget',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 0.6,
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onConfigure,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2E34),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Set Budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Available out of ${formatMoney(total, currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        formatMoney(remaining, currency),
                        key: ValueKey(remaining),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currency,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
      required this.currency});

  final double expenses;
  final double income;
  final String currency;

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
            'Expenses & Income',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: const [
              _FilterChip(label: '1M', selected: true),
              _FilterChip(label: '3M', selected: false),
              _FilterChip(label: '6M', selected: false),
              _FilterChip(label: '1Y', selected: false),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                icon: Icons.arrow_upward_rounded,
                label: 'Expenses for this month',
                amount: '-${formatMoney(expenses, currency)}',
                accent: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.arrow_downward_rounded,
                label: 'Income for this month',
                amount: formatMoney(income, currency),
                accent: const Color(0xFFB5FF4D),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2B2E34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfitLossCard extends StatelessWidget {
  const ProfitLossCard(
      {super.key, required this.profit, required this.currency});

  final double profit;
  final String currency;

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
            children: const [
              _FilterChip(label: '1M', selected: true),
              _FilterChip(label: '3M', selected: false),
              _FilterChip(label: '6M', selected: false),
              _FilterChip(label: '1Y', selected: false),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: SizedBox(
                  height: 110,
                  child: AnimatedProfitBars(),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit for this month',
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
  const AnimatedProfitBars({super.key});

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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ProfitBarsPainter(progress: _controller.value),
        );
      },
    );
  }
}

class ProfitBarsPainter extends CustomPainter {
  ProfitBarsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..style = PaintingStyle.fill;
    final bars = [0.4, 0.6, 0.85, 0.35, 0.7];
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
      oldDelegate.progress != progress;
}
