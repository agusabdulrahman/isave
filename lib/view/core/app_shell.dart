part of 'package:finoov/view/app.dart';

class FinoovApp extends StatelessWidget {
  const FinoovApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.hankenGroteskTextTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'finoov',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1C1B1F),
          secondary: Color(0xFFB5FF4D),
          tertiary: Color(0xFF4C7DFF),
          surface: Color(0xFFF7F8FA),
          error: Color(0xFFB42318),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        textTheme: baseTextTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE3E6EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE3E6EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF1C1B1F), width: 1.4),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6D7380)),
          prefixIconColor: const Color(0xFF6D7380),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C1B1F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1C1B1F),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }

        if (_appState == null || _appState!.userId != session.user.id) {
          _appState = AppState(userId: session.user.id);
        }

        return AppStateScope(
          notifier: _appState!,
          child: FutureBuilder(
            future: _appState!.isLoaded ? null : _appState!.load(),
            builder: (context, loadingSnapshot) {
              if (!_appState!.isLoaded) {
                return const SplashLoading();
              }
              return const MainShell();
            },
          ),
        );
      },
    );
  }
}

class SplashLoading extends StatelessWidget {
  const SplashLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _busy = false;
  bool _showEmailVerification = false;
  String? _error;
  String? _pendingEmail;
  String? _verificationMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
      } else {
        final fullName = _nameController.text.trim();
        final response = await supabase.auth.signUp(
          email: email,
          password: _passwordController.text.trim(),
          data: {
            'full_name': fullName,
          },
        );
        final user = response.user;
        final session = response.session;
        if (user != null && session != null) {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
          });
        } else if (user != null) {
          setState(() {
            _pendingEmail = email;
            _verificationMessage = null;
            _showEmailVerification = true;
            _isLogin = true;
            _passwordController.clear();
          });
        }
      }
    } on AuthApiException catch (e) {
      if (!_isLogin && _isEmailRateLimitError(e)) {
        setState(() {
          _pendingEmail = email;
          _verificationMessage =
              'A verification email was already sent to $email. Please check your inbox, or wait a few minutes before creating the account again.';
          _showEmailVerification = true;
          _isLogin = true;
          _passwordController.clear();
        });
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _busy = false);
  }

  bool _isEmailRateLimitError(AuthApiException error) {
    return error.code == 'over_email_send_rate_limit' ||
        error.statusCode == '429';
  }

  void _returnToSignIn() {
    setState(() {
      _showEmailVerification = false;
      _isLogin = true;
      _error = null;
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmailVerification) {
      return _EmailVerificationScreen(
        email: _pendingEmail ?? _emailController.text.trim(),
        message: _verificationMessage,
        onBackToSignIn: _returnToSignIn,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: wide
                          ? Row(
                              children: [
                                const Expanded(child: _AuthBrandPanel()),
                                const SizedBox(width: 32),
                                SizedBox(
                                  width: 440,
                                  child: _buildAuthCard(context),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _AuthBrandPanel(compact: true),
                                const SizedBox(height: 22),
                                _buildAuthCard(context),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111214),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _BrandMark(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLogin ? 'Welcome back' : 'Create your account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111214),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLogin
                          ? 'Sign in and keep your money on track.'
                          : 'Start tracking your wallet in minutes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6D7380),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Sign in'),
                icon: Icon(Icons.login_rounded),
              ),
              ButtonSegment(
                value: false,
                label: Text('Register'),
                icon: Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
            selected: {_isLogin},
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF1C1B1F);
                }
                return const Color(0xFFF1F3F6);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF4A505A);
              }),
              side: const WidgetStatePropertyAll(BorderSide.none),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            onSelectionChanged: _busy
                ? null
                : (value) {
                    setState(() {
                      _isLogin = value.first;
                      _error = null;
                      _verificationMessage = null;
                      _showEmailVerification = false;
                    });
                  },
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: !_isLogin
                ? Column(
                    key: const ValueKey('name-field'),
                    children: [
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('no-name-field')),
          ),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onSubmitted: (_) {
              if (!_busy) {
                _submit();
              }
            },
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _AuthMessage(
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFB42318),
                      text: _error!,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_isLogin
                    ? Icons.arrow_forward_rounded
                    : Icons.check_rounded),
            label: Text(_isLogin ? 'Sign in' : 'Create account'),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                      _verificationMessage = null;
                      _showEmailVerification = false;
                    });
                  },
            child: Text(_isLogin
                ? 'Create new account'
                : 'Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF8F2),
            Color(0xFFF7F8FA),
            Color(0xFFEAF0FF),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final headline = compact
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.displaySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(size: 58),
        const SizedBox(height: 20),
        Text(
          'finoov',
          style: headline?.copyWith(
            color: const Color(0xFF111214),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Text(
            'A cleaner way to watch your balance, spending rhythm, and monthly goals.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF4A505A),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 28),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FeaturePill(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Wallets',
              ),
              _FeaturePill(
                icon: Icons.trending_up_rounded,
                label: 'Reports',
              ),
              _FeaturePill(
                icon: Icons.flag_rounded,
                label: 'Goals',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C7DFF).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icons/icon_app.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1C1B1F)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1C1B1F),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailVerificationScreen extends StatelessWidget {
  const _EmailVerificationScreen({
    required this.email,
    required this.message,
    required this.onBackToSignIn,
  });

  final String email;
  final String? message;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFB5FF4D),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF1C1B1F),
                size: 36,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Check your email',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  'We sent a verification link to $email. Open that link first, then come back here and sign in to finoov.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1B1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to sign in'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'If you do not see the email, check your spam or promotions folder.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope(
      {super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    return scope!.notifier!;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _tabs = const [
    HomeScreen(),
    AccountsScreen(),
    ReportsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF111214),
        surfaceTintColor: const Color(0xFF111214),
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: const Color(0xFF2B2E34),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFFB5FF4D),
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(color: Colors.white70);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFB5FF4D)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white70),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFFB5FF4D)),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white70),
            selectedIcon:
                Icon(Icons.bar_chart_rounded, color: Color(0xFFB5FF4D)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined, color: Colors.white70),
            selectedIcon:
                Icon(Icons.more_horiz_rounded, color: Color(0xFFB5FF4D)),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
