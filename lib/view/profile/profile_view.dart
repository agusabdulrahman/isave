part of 'package:finoov/view/app.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _DarkShell(
      title: 'More',
      child: Column(
        children: [
          _CurrencySettingCard(
            value: state.selectedCurrency,
            onChanged: state.setCurrency,
          ),
          const SizedBox(height: 16),
          const _SettingsCard(),
          const SizedBox(height: 16),
          const _SettingsCardSecondary(),
        ],
      ),
    );
  }
}

class _CurrencySettingCard extends StatelessWidget {
  const _CurrencySettingCard({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set default currency used in Home, Accounts, and Reports. Default: IDR.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 12),
          _CurrencyToggle(value: value, onChanged: onChanged),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: const [
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Accounts',
            subtitle: 'Customize sections',
          ),
          // SizedBox(height: 12),
          // _SettingsTile(
          //   icon: Icons.grid_view_rounded,
          //   title: 'Categories',
          //   subtitle: 'Customize sections',
          // ),
          // SizedBox(height: 12),
          // _SettingsTile(
          //   icon: Icons.group_outlined,
          //   title: 'Shared Access',
          //   subtitle: 'Customize sections',
          // ),
        ],
      ),
    );
  }
}

class _SettingsCardSecondary extends StatelessWidget {
  const _SettingsCardSecondary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: const [
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Additional settings',
          ),
          // SizedBox(height: 12),
          // _SettingsTile(
          //   icon: Icons.language_outlined,
          //   title: 'Language',
          //   subtitle: 'Additional settings',
          // ),
          // SizedBox(height: 12),
          // _SettingsTile(
          //   icon: Icons.lock_outline_rounded,
          //   title: 'Security',
          //   subtitle: 'Additional settings',
          // ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2E34),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFB5FF4D), size: 22),
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
        const Icon(Icons.chevron_right_rounded, color: Colors.white54),
      ],
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
