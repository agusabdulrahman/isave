part of 'package:isaveup/view/app.dart';

class ISaveUpApp extends StatelessWidget {
  const ISaveUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.dmSansTextTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iSaveUp',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1C1B1F),
          secondary: Color(0xFF4C7DFF),
          surface: Color(0xFFF6F6F7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F7),
        textTheme: baseTextTheme,
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text(
              'iSaveUp',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Automatic budgeting for busy people.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (!_isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Full name', border: OutlineInputBorder()),
              ),
            if (!_isLogin) const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1B1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_isLogin ? 'Sign in' : 'Create account'),
              ),
            ),
            const SizedBox(height: 12),
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
                  'We sent a verification link to $email. Open that link first, then come back here and sign in to iSaveUp.',
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
