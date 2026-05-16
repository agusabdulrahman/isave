part of 'package:isaveup/view/app.dart';

enum _BalanceRange { d1, w1, m1, m6, y1 }

extension on _BalanceRange {
  String get label {
    switch (this) {
      case _BalanceRange.d1:
        return '1D';
      case _BalanceRange.w1:
        return '1W';
      case _BalanceRange.m1:
        return '1M';
      case _BalanceRange.m6:
        return '6M';
      case _BalanceRange.y1:
        return '1Y';
    }
  }
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  _BalanceRange _selectedRange = _BalanceRange.m1;
  bool _hideBalance = false;

  _BalanceTrendData _trendForRange(AppState state, _BalanceRange range) {
    final now = DateTime.now();
    late final DateTime start;
    late final int bucketCount;

    switch (range) {
      case _BalanceRange.d1:
        start = now.subtract(const Duration(hours: 24));
        bucketCount = 8;
      case _BalanceRange.w1:
        start = now.subtract(const Duration(days: 7));
        bucketCount = 7;
      case _BalanceRange.m1:
        start = DateTime(now.year, now.month - 1, now.day, now.hour, now.minute);
        bucketCount = 8;
      case _BalanceRange.m6:
        start = DateTime(now.year, now.month - 6, now.day, now.hour, now.minute);
        bucketCount = 6;
      case _BalanceRange.y1:
        start = DateTime(now.year - 1, now.month, now.day, now.hour, now.minute);
        bucketCount = 12;
    }

    final totalMs = now.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    if (totalMs <= 0) {
      final value = state.totalBalanceForCurrency(state.selectedCurrency);
      return _BalanceTrendData(
        normalized: const [0.5],
        minValue: value,
        maxValue: value,
      );
    }
    final bucketMs = totalMs / bucketCount;
    final buckets = List<double>.filled(bucketCount, 0);
    final currency = state.selectedCurrency;

    for (final entry in state.transactions.where((t) => t.currency == currency)) {
      final t = entry.date.millisecondsSinceEpoch;
      if (t < start.millisecondsSinceEpoch || t > now.millisecondsSinceEpoch) {
        continue;
      }
      final idx =
          ((t - start.millisecondsSinceEpoch) / bucketMs).floor().clamp(0, bucketCount - 1);
      final delta =
          entry.type == TransactionType.income ? entry.amount : -entry.amount;
      buckets[idx] += delta;
    }

    var running = state.totalBalanceForCurrency(currency) -
        buckets.fold<double>(0, (sum, v) => sum + v);
    final series = <double>[];
    for (final delta in buckets) {
      running += delta;
      series.add(running);
    }

    final minValue = series.reduce(min);
    final maxValue = series.reduce(max);
    final span = max(1, maxValue - minValue);
    return _BalanceTrendData(
      normalized: series.map((value) => (value - minValue) / span).toList(),
      minValue: minValue,
      maxValue: maxValue,
    );
  }

  List<String> _xAxisLabelsForRange(_BalanceRange range) {
    final now = DateTime.now();
    String hourLabel(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final suffix = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour $suffix';
    }

    switch (range) {
      case _BalanceRange.d1:
        return [
          hourLabel(now.subtract(const Duration(hours: 18))),
          hourLabel(now.subtract(const Duration(hours: 12))),
          hourLabel(now.subtract(const Duration(hours: 6))),
          hourLabel(now),
        ];
      case _BalanceRange.w1:
        return const ['6D', '4D', '2D', 'Today'];
      case _BalanceRange.m1:
        return const ['4W', '3W', '2W', 'Now'];
      case _BalanceRange.m6:
        return const ['6M', '4M', '2M', 'Now'];
      case _BalanceRange.y1:
        return const ['12M', '8M', '4M', 'Now'];
    }
  }

  String _compactMoney(double value) {
    final abs = value.abs();
    String short;
    if (abs >= 1000000000) {
      short = '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (abs >= 1000000) {
      short = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      short = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      short = value.toStringAsFixed(0);
    }
    return short;
  }

  List<String> _yAxisLabels(double minValue, double maxValue, String currency) {
    final steps = 4;
    final span = maxValue - minValue;
    return List<String>.generate(steps, (i) {
      final t = 1 - (i / (steps - 1));
      final value = minValue + (span * t);
      return _compactMoney(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bankAccounts =
        state.accounts.where((acc) => acc.kind == AccountKind.bank).toList();
    final cashAccounts =
        state.accounts.where((acc) => acc.kind == AccountKind.cash).toList();
    final trendData = _trendForRange(state, _selectedRange);
    final labels = _xAxisLabelsForRange(_selectedRange);
    final yAxisLabels = _yAxisLabels(
      trendData.minValue,
      trendData.maxValue,
      state.selectedCurrency,
    );

    return Container(
      color: const Color(0xFF111214),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  'Accounts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () => supabase.auth.signOut(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BalanceCard(
              totalBalance:
                  state.totalBalanceForCurrency(state.selectedCurrency),
              currency: state.selectedCurrency,
              trend: trendData.normalized,
              xAxisLabels: labels,
              yAxisLabels: yAxisLabels,
              selectedRange: _selectedRange,
              hideBalance: _hideBalance,
              onToggleHide: () {
                setState(() => _hideBalance = !_hideBalance);
              },
              onRangeChanged: (value) {
                setState(() => _selectedRange = value);
              },
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Bank Accounts',
              trailing: formatMoney(
                bankAccounts
                    .where((acc) => acc.currency == state.selectedCurrency)
                    .fold(0, (sum, acc) => sum + acc.balance),
                state.selectedCurrency,
              ),
            ),
            const SizedBox(height: 10),
            ...bankAccounts.map(
              (account) => AccountTile(
                title: account.name,
                subtitle:
                    '${account.kind.name.toUpperCase()} - ${account.currency}',
                amount: formatMoney(account.balance, account.currency),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Cash', trailing: ''),
            const SizedBox(height: 10),
            ...cashAccounts.map(
              (account) => AccountTile(
                title: account.name,
                subtitle: 'On hand - ${account.currency}',
                amount: formatMoney(account.balance, account.currency),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard(
      {super.key,
      required this.totalBalance,
      required this.currency,
      required this.trend,
      required this.xAxisLabels,
      required this.yAxisLabels,
      required this.selectedRange,
      required this.hideBalance,
      required this.onToggleHide,
      required this.onRangeChanged});

  final double totalBalance;
  final String currency;
  final List<double> trend;
  final List<String> xAxisLabels;
  final List<String> yAxisLabels;
  final _BalanceRange selectedRange;
  final bool hideBalance;
  final VoidCallback onToggleHide;
  final ValueChanged<_BalanceRange> onRangeChanged;

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
          Row(
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.6,
                      color: Colors.white70,
                    ),
              ),
              const Spacer(),
              InkWell(
                onTap: onToggleHide,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2E34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ImageFiltered(
              key: ValueKey('$totalBalance-$hideBalance'),
              imageFilter: ImageFilter.blur(
                sigmaX: hideBalance ? 6 : 0,
                sigmaY: hideBalance ? 6 : 0,
              ),
              child: Text(
                formatMoney(totalBalance, currency),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
          if (hideBalance) ...[
            const SizedBox(height: 6),
            Text(
              'Balance hidden',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: _BalanceRange.values
                .map((range) => _BalanceFilterChip(
                      label: range.label,
                      selected: range == selectedRange,
                      onTap: () => onRangeChanged(range),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: yAxisLabels
                        .map(
                          (label) => Text(
                            hideBalance ? '••••' : label,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedBalanceChart(values: trend),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xAxisLabels
                .map(
                  (label) => Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BalanceFilterChip extends StatelessWidget {
  const _BalanceFilterChip({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFB5FF4D) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? const Color(0xFF111214) : Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _BalanceTrendData {
  const _BalanceTrendData({
    required this.normalized,
    required this.minValue,
    required this.maxValue,
  });

  final List<double> normalized;
  final double minValue;
  final double maxValue;
}

class AnimatedBalanceChart extends StatefulWidget {
  const AnimatedBalanceChart({super.key, required this.values});

  final List<double> values;

  @override
  State<AnimatedBalanceChart> createState() => _AnimatedBalanceChartState();
}

class _AnimatedBalanceChartState extends State<AnimatedBalanceChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBalanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _controller.forward(from: 0);
    }
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
          painter: BalanceChartPainter(
              values: widget.values, progress: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class BalanceChartPainter extends CustomPainter {
  BalanceChartPainter({required this.values, required this.progress});

  final List<double> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2D3036)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFFB5FF4D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFB5FF4D).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * (i / (values.length - 1));
      final y = size.height * (1 - values[i]) * 0.85 + size.height * 0.1;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx, points.first.dy);
    } else {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cx = (p0.dx + p1.dx) / 2;
        path.cubicTo(
          cx,
          p0.dy,
          cx,
          p1.dy,
          p1.dx,
          p1.dy,
        );
      }
    }

    final metric = path.computeMetrics().first;
    final segment = metric.extractPath(0, metric.length * progress);

    final fillPath = Path.from(segment)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(segment, linePaint);
  }

  @override
  bool shouldRepaint(covariant BalanceChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.progress != progress;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
        ),
        const Spacer(),
        if (trailing.isNotEmpty)
          Text(
            trailing,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
      ],
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2E34),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              size: 22,
              color: Colors.white70,
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
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
