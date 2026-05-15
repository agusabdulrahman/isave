part of 'package:isaveup/view/app.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bankAccounts =
        state.accounts.where((acc) => acc.kind == AccountKind.bank).toList();
    final cashAccounts =
        state.accounts.where((acc) => acc.kind == AccountKind.cash).toList();
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
              trend: state.weeklyBalanceTrend(state.selectedCurrency),
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
      required this.trend});

  final double totalBalance;
  final String currency;
  final List<double> trend;

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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2E34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              formatMoney(totalBalance, currency),
              key: ValueKey(totalBalance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: AnimatedBalanceChart(values: trend),
          ),
        ],
      ),
    );
  }
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

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - values[i]) * 0.85 + size.height * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
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
