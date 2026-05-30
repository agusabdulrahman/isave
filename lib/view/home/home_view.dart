part of 'package:isaveup/view/app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final recent = state.recentTransactions.take(3).toList();
    final currency = state.selectedCurrency;
    final budget = state.budgetForMonth(currency, DateTime.now());

    return ColoredBox(
      color: const Color(0xFF111214),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _HomeHeader(
                  currency: currency,
                  onCurrencyChanged: state.setCurrency,
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: 0.0,
                  child: BudgetCardLight(
                    progress: state.budgetProgress,
                    remaining: state.remainingBudget,
                    total: budget,
                    currency: currency,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: 0.08,
                  child: ExpensesIncomeCardLight(
                    onExpense: () => showAddTransactionSheet(
                        context, TransactionType.expense),
                    onIncome: () => showAddTransactionSheet(
                        context, TransactionType.income),
                  ),
                ),
                const SizedBox(height: 24),
                const _HomeSectionHeader(
                  title: 'Recent Transactions',
                  subtitle: 'Latest wallet movement',
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: recent.isEmpty
                      ? const _EmptyTransactionsCard()
                      : Column(
                          key: ValueKey(recent.length),
                          children: recent
                              .map(
                                (entry) => TransactionTile(
                                  title: entry.title,
                                  subtitle: entry.category,
                                  amount: (entry.type == TransactionType.expense
                                          ? '-'
                                          : '+') +
                                      formatMoney(entry.amount, entry.currency),
                                  accent: entry.type == TransactionType.expense
                                      ? const Color(0xFFFF7A7A)
                                      : const Color(0xFFB5FF4D),
                                  icon: entry.type == TransactionType.expense
                                      ? Icons.north_east_rounded
                                      : Icons.south_west_rounded,
                                  onTap: () =>
                                      showEditTransactionSheet(context, entry),
                                ),
                              )
                              .toList(),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.currency,
    required this.onCurrencyChanged,
  });

  final String currency;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'iSaveUp',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFB5FF4D),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calm, clear money control',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        _CurrencyToggle(value: currency, onChanged: onCurrencyChanged),
      ],
    );
  }
}

class _BalanceOverviewCard extends StatelessWidget {
  const _BalanceOverviewCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currency,
  });

  final double balance;
  final double income;
  final double expense;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return _HomeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  formatMoney(balance, currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  currency,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Income',
                  value: formatMoney(income, currency),
                  icon: Icons.south_west_rounded,
                  accent: const Color(0xFFB5FF4D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewMetric(
                  label: 'Expense',
                  value: formatMoney(expense, currency),
                  icon: Icons.north_east_rounded,
                  accent: const Color(0xFFFF7A7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NetBadge(net: net, currency: currency),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E36)),
      ),
      child: child,
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2E34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _NetBadge extends StatelessWidget {
  const _NetBadge({required this.net, required this.currency});

  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    final color = positive ? const Color(0xFFB5FF4D) : const Color(0xFFFF7A7A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            '${positive ? 'Net gain' : 'Net spend'} ${formatMoney(net.abs(), currency)} this month',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'USD', label: Text('USD')),
        ButtonSegment(value: 'IDR', label: Text('IDR')),
      ],
      selected: {value},
      style: SegmentedButton.styleFrom(
        backgroundColor: const Color(0xFF2B2E34),
        foregroundColor: Colors.white60,
        selectedBackgroundColor: const Color(0xFFB5FF4D),
        selectedForegroundColor: const Color(0xFF111214),
        side: const BorderSide(color: Color(0xFF2A2E36)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class BudgetCardLight extends StatelessWidget {
  const BudgetCardLight({
    super.key,
    required this.progress,
    required this.remaining,
    required this.total,
    required this.currency,
  });

  final double progress;
  final double remaining;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final spent = max(0.0, total - remaining);
    final spentPercent = (progress * 100).clamp(0, 999).round();
    final remainingPercent =
        total <= 0 ? 0 : ((remaining / total) * 100).clamp(0, 100).round();
    final isLow = total > 0 && remaining / total <= 0.2;

    return _HomeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE9F2D0),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'AVAILABLE OUT OF ${formatMoney(total, currency)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BudgetDonut(
                progress: progress,
                label: '$spentPercent%',
                size: 66,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            currency,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isLow
                              ? Icons.trending_down_rounded
                              : Icons.check_circle_outline_rounded,
                          color: const Color(0xFFB5FF4D),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isLow
                                ? 'Low balance remaining'
                                : '$remainingPercent% budget still available',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFB5FF4D),
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
              const SizedBox(width: 12),
              Expanded(
                child: _BudgetMetric(
                  label: 'Remaining',
                  value: '$remainingPercent%',
                  color: const Color(0xFFB5FF4D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetDonut extends StatelessWidget {
  const _BudgetDonut({
    required this.progress,
    required this.label,
    this.size = 76,
  });

  final double progress;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _BudgetDonutPainter(progress: value),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFB5FF4D),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetDonutPainter extends CustomPainter {
  const _BudgetDonutPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = const Color(0xFF2D3036)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = const Color(0xFFB5FF4D)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, -pi / 2, pi * 2, false, track);
    canvas.drawArc(rect, -pi / 2, pi * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _BudgetDonutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2E34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2E36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class ExpensesIncomeCardLight extends StatelessWidget {
  const ExpensesIncomeCardLight({
    super.key,
    required this.onExpense,
    required this.onIncome,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expenses & Income',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE9F2D0),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a quick and easy way to add changes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  label: 'Expenses',
                  icon: Icons.arrow_upward_rounded,
                  onTap: onExpense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionPill(
                  label: 'Income',
                  icon: Icons.arrow_downward_rounded,
                  onTap: onIncome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: label == 'Income'
              ? const Color(0xFFB5FF4D)
              : const Color(0xFF2B2E34),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: label == 'Income'
                ? const Color(0xFFB5FF4D)
                : const Color(0xFF2A2E36),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: label == 'Income'
                  ? const Color(0xFF111214)
                  : const Color(0xFFE9F2D0),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: label == 'Income'
                        ? const Color(0xFF111214)
                        : const Color(0xFFE9F2D0),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFE9F2D0),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.more_horiz_rounded,
          color: Colors.white54,
        ),
      ],
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2E34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No recent transactions yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2E36)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(
                icon,
                size: 22,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE9F2D0),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditTransactionSheet(BuildContext context, TransactionEntry entry) {
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
      child: _EditTransactionSheet(entry: entry),
    ),
  );
}

class _EditTransactionSheet extends StatefulWidget {
  const _EditTransactionSheet({required this.entry});

  final TransactionEntry entry;

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _amountController =
        TextEditingController(text: widget.entry.amount.round().toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save(AppState state) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    await state.updateTransactionBasic(
      transactionId: widget.entry.id,
      title: _titleController.text.trim().isEmpty
          ? widget.entry.title
          : _titleController.text.trim(),
      amount: amount,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete(AppState state) async {
    setState(() => _saving = true);
    await state.deleteTransaction(transactionId: widget.entry.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Transaction',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: Colors.white70),
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
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                suffixText: widget.entry.currency,
                labelStyle: const TextStyle(color: Colors.white70),
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
                onPressed: _saving ? null : () => _save(state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5FF4D),
                  foregroundColor: const Color(0xFF111214),
                ),
                child: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving ? null : () => _delete(state),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7A7A),
                  side: const BorderSide(color: Color(0xFFFF7A7A)),
                ),
                child: const Text('Delete Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAddTransactionSheet(BuildContext context, TransactionType type) {
  final state = AppStateScope.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AppStateScope(
      notifier: state,
      child: AddTransactionSheet(initialType: type),
    ),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, required this.initialType});

  final TransactionType initialType;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _type;
  late TransactionMode _mode;
  String? _fromAccountId;
  String? _toAccountId;
  String? _categoryId;
  String? _currency;
  DateTime _selectedDate = DateTime.now();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _autoFill = false;
  bool _recurring = false;
  IntervalUnit _intervalUnit = IntervalUnit.month;
  int _intervalCount = 1;
  bool _savingCategory = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _mode = widget.initialType == TransactionType.income
        ? TransactionMode.income
        : TransactionMode.expense;
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatHeaderDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final label = '${months[date.month - 1]} ${date.day}';
    return '$label, Today';
  }

  String _previewAmount(String currency) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return '--';
    final signed = _type == TransactionType.expense ? -amount : amount;
    final prefix = signed < 0 ? '-' : '+';
    return '$prefix${formatMoney(signed.abs(), currency)}';
  }

  Future<void> _createCategory(AppState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New ${_type.name} category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Category name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    setState(() => _savingCategory = true);
    await supabase.from('categories').insert({
      'user_id': state.userId,
      'name': result,
      'type': _type == TransactionType.income ? 'income' : 'expense',
    });
    await state.loadFresh();
    setState(() {
      _savingCategory = false;
      final matching =
          state.categories.where((cat) => cat.type == _type).toList();
      _categoryId = matching.isNotEmpty ? matching.last.id : null;
    });
  }

  Future<void> _save(AppState state) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    if (_mode == TransactionMode.transfer) {
      if (_fromAccountId == null ||
          _toAccountId == null ||
          _fromAccountId == _toAccountId) return;
      await state.addTransfer(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: amount,
        occurredAt: _selectedDate,
      );
    } else {
      if (_fromAccountId == null || _categoryId == null) return;
      await state.addTransaction(
        title: _titleController.text.isEmpty
            ? 'New transaction'
            : _titleController.text,
        categoryId: _categoryId,
        accountId: _fromAccountId!,
        amount: amount,
        type: _type,
        autoRecorded: _autoFill,
        createRecurring: _recurring,
        intervalUnit: _intervalUnit,
        intervalCount: _intervalCount,
        occurredAt: _selectedDate,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final allAccounts = state.accounts;
    _currency ??= state.selectedCurrency;
    final availableCurrencies =
        allAccounts.map((acc) => acc.currency).toSet().toList()..sort();
    final filteredAccounts =
        allAccounts.where((acc) => acc.currency == _currency).toList();
    final accounts =
        filteredAccounts.isNotEmpty ? filteredAccounts : allAccounts;
    if (accounts.isNotEmpty &&
        (_fromAccountId == null ||
            accounts.every((acc) => acc.id != _fromAccountId))) {
      _fromAccountId = accounts.first.id;
    }
    if (_mode == TransactionMode.transfer) {
      if (_toAccountId == null ||
          accounts.every((acc) => acc.id != _toAccountId) ||
          _toAccountId == _fromAccountId) {
        final fallback = accounts.firstWhere(
          (acc) => acc.id != _fromAccountId,
          orElse: () => accounts.first,
        );
        _toAccountId = fallback.id;
      }
    } else {
      _toAccountId = null;
    }
    final selectedAccount = _fromAccountId == null
        ? null
        : accounts.firstWhere((acc) => acc.id == _fromAccountId,
            orElse: () => accounts.first);
    var activeCurrency =
        selectedAccount?.currency ?? _currency ?? state.selectedCurrency;
    if (availableCurrencies.isNotEmpty &&
        !availableCurrencies.contains(activeCurrency)) {
      activeCurrency = availableCurrencies.first;
      _currency = activeCurrency;
    }

    final categories = _mode == TransactionMode.transfer
        ? <Category>[]
        : state.categories.where((cat) => cat.type == _type).toList();
    if (categories.isNotEmpty &&
        (_categoryId == null ||
            categories.every((cat) => cat.id != _categoryId))) {
      _categoryId = categories.first.id;
    }
    final amountValue = double.tryParse(_amountController.text.trim()) ?? 0;
    final canSave = amountValue > 0 &&
        _fromAccountId != null &&
        (_mode == TransactionMode.transfer
            ? _toAccountId != null && _toAccountId != _fromAccountId
            : _categoryId != null);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151618),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        _mode == TransactionMode.transfer
                            ? 'Transfer'
                            : _type == TransactionType.expense
                                ? 'Expenses'
                                : 'Income',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon:
                          const Icon(Icons.tune_rounded, color: Colors.white70),
                      color: const Color(0xFF1C1E22),
                      onSelected: (value) {
                        if (value == 'income' &&
                            _mode != TransactionMode.income) {
                          setState(() {
                            _mode = TransactionMode.income;
                            _type = TransactionType.income;
                            _categoryId = null;
                          });
                        } else if (value == 'expense' &&
                            _mode != TransactionMode.expense) {
                          setState(() {
                            _mode = TransactionMode.expense;
                            _type = TransactionType.expense;
                            _categoryId = null;
                          });
                        } else if (value == 'transfer' &&
                            _mode != TransactionMode.transfer) {
                          setState(() {
                            _mode = TransactionMode.transfer;
                            _categoryId = null;
                            _recurring = false;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'expense', child: Text('Add Expenses')),
                        const PopupMenuItem(
                            value: 'income', child: Text('Add Income')),
                        const PopupMenuItem(
                            value: 'transfer', child: Text('Transfer')),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _formatHeaderDate(_selectedDate),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: _mode == TransactionMode.transfer
                      ? 'TRANSFER'
                      : _type == TransactionType.expense
                          ? 'EXPENSES'
                          : 'INCOME',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                prefixText: _mode == TransactionMode.transfer
                                    ? ''
                                    : _type == TransactionType.expense
                                        ? '-'
                                        : '+',
                                prefixStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700),
                                suffixText: activeCurrency,
                                suffixStyle: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600),
                                hintText: '0.00',
                                hintStyle:
                                    const TextStyle(color: Colors.white24),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (availableCurrencies.isNotEmpty)
                            DropdownButton<String>(
                              value: activeCurrency,
                              dropdownColor: const Color(0xFF1F2124),
                              underline: const SizedBox(),
                              items: availableCurrencies
                                  .map((currency) => DropdownMenuItem(
                                      value: currency, child: Text(currency)))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _currency = value;
                                  final byCurrency = allAccounts
                                      .where((acc) => acc.currency == value)
                                      .toList();
                                  _fromAccountId = byCurrency.isNotEmpty
                                      ? byCurrency.first.id
                                      : null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'T-shirt and pants',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_mode == TransactionMode.transfer) ...[
                  _SectionCard(
                    title: 'FROM ACCOUNT',
                    child: Column(
                      children: [
                        if (accounts.isEmpty)
                          const Text('No accounts available yet.',
                              style: TextStyle(color: Colors.white70))
                        else
                          ...accounts.map(
                            (account) => _SelectableTile(
                              title: account.name,
                              subtitle: account.kind == AccountKind.bank
                                  ? 'Bank account'
                                  : 'Cash',
                              trailing: formatMoney(
                                  account.balance, account.currency),
                              selected: _fromAccountId == account.id,
                              onTap: () {
                                setState(() {
                                  _fromAccountId = account.id;
                                  _currency = account.currency;
                                  if (_toAccountId == _fromAccountId) {
                                    _toAccountId = accounts
                                        .firstWhere(
                                          (acc) => acc.id != _fromAccountId,
                                          orElse: () => account,
                                        )
                                        .id;
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'TO ACCOUNT',
                    child: Column(
                      children: [
                        if (accounts.isEmpty)
                          const Text('No accounts available yet.',
                              style: TextStyle(color: Colors.white70))
                        else
                          ...accounts.map(
                            (account) => _SelectableTile(
                              title: account.name,
                              subtitle: account.kind == AccountKind.bank
                                  ? 'Bank account'
                                  : 'Cash',
                              trailing: formatMoney(
                                  account.balance, account.currency),
                              selected: _toAccountId == account.id,
                              onTap: () {
                                setState(() {
                                  _toAccountId = account.id;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else
                  _SectionCard(
                    title: _type == TransactionType.expense
                        ? 'FROM ACCOUNTS'
                        : 'TO ACCOUNTS',
                    child: Column(
                      children: [
                        if (accounts.isEmpty)
                          const Text('No accounts available yet.',
                              style: TextStyle(color: Colors.white70))
                        else
                          ...accounts.map(
                            (account) => _SelectableTile(
                              title: account.name,
                              subtitle: account.kind == AccountKind.bank
                                  ? 'Bank account'
                                  : 'Cash',
                              trailing: formatMoney(
                                  account.balance, account.currency),
                              selected: _fromAccountId == account.id,
                              onTap: () {
                                setState(() {
                                  _fromAccountId = account.id;
                                  _currency = account.currency;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (_mode != TransactionMode.transfer)
                  _SectionCard(
                    title: _type == TransactionType.expense
                        ? 'TO CATEGORY'
                        : 'FROM CATEGORY',
                    action: TextButton.icon(
                      onPressed:
                          _savingCategory ? null : () => _createCategory(state),
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color(0xFFB5FF4D)),
                      label: const Text('Add category',
                          style: TextStyle(color: Color(0xFFB5FF4D))),
                    ),
                    child: Column(
                      children: [
                        if (categories.isEmpty)
                          const Text('No categories yet. Add one to continue.',
                              style: TextStyle(color: Colors.white70))
                        else
                          ...categories.map(
                            (category) => _SelectableTile(
                              title: category.name,
                              subtitle: category.type == TransactionType.income
                                  ? 'Income'
                                  : 'Expense',
                              trailing: _previewAmount(activeCurrency),
                              selected: _categoryId == category.id,
                              onTap: () =>
                                  setState(() => _categoryId = category.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_mode != TransactionMode.transfer)
                  const SizedBox(height: 12),
                if (_mode != TransactionMode.transfer)
                  SwitchListTile.adaptive(
                    value: _recurring,
                    onChanged: (value) => setState(() => _recurring = value),
                    title: const Text('Make this recurring',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Auto create this transaction again',
                        style: TextStyle(color: Colors.white54)),
                  ),
                if (_mode != TransactionMode.transfer && _recurring) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<IntervalUnit>(
                          value: _intervalUnit,
                          dropdownColor: const Color(0xFF1F2124),
                          items: const [
                            DropdownMenuItem(
                                value: IntervalUnit.day, child: Text('Day')),
                            DropdownMenuItem(
                                value: IntervalUnit.week, child: Text('Week')),
                            DropdownMenuItem(
                                value: IntervalUnit.month,
                                child: Text('Month')),
                            DropdownMenuItem(
                                value: IntervalUnit.year, child: Text('Year')),
                          ],
                          onChanged: (value) => setState(
                              () => _intervalUnit = value ?? _intervalUnit),
                          decoration: const InputDecoration(
                              labelText: 'Interval unit',
                              border: OutlineInputBorder()),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'Every', border: OutlineInputBorder()),
                          onChanged: (value) =>
                              _intervalCount = int.tryParse(value) ?? 1,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSave ? () => _save(state) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB5FF4D),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save'),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.4,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFF151618),
                hintStyle: TextStyle(color: Colors.white38),
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2C2F36)),
                ),
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? const Color(0xFFB5FF4D) : const Color(0xFF2C2F36);
    final background =
        selected ? const Color(0xFF1A1F12) : const Color(0xFF151618);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2E34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.circle_outlined,
                  color: const Color(0xFFB5FF4D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22242A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailing,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.delay, required this.child});

  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Interval(delay, 1, curve: Curves.easeOut),
      builder: (context, value, child) {
        final translate = 12 * (1 - value);
        return Opacity(
          opacity: value,
          child:
              Transform.translate(offset: Offset(0, translate), child: child),
        );
      },
      child: child,
    );
  }
}
