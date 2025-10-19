import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/api_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/permission_request_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize notification service
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SalesPulse',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavigation(),
      },
    );
  }
}

// Auth wrapper to check authentication state
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsOnce();
  }

  Future<void> _checkPermissionsOnce() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasChecked = prefs.getBool('permissions_requested') ?? false;

    setState(() {
      _permissionsChecked = hasChecked;
    });
  }

  void _onPermissionsComplete() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('permissions_requested', true);
    setState(() {
      _permissionsChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Show loading while checking auth
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show permission request screen if not checked yet and authenticated
    if (authState.isAuthenticated && !_permissionsChecked) {
      return PermissionRequestScreen(
        onComplete: _onPermissionsComplete,
      );
    }

    // Show main navigation if authenticated, otherwise show welcome screen
    if (authState.isAuthenticated) {
      return const MainNavigation();
    } else {
      return const WelcomeScreen();
    }
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 3; // Start with Dashboard

  // Track if data has been loaded for each screen to avoid redundant loads
  final Set<int> _loadedScreens = {};

  @override
  void initState() {
    super.initState();
    // Pre-load data for initial screen (Dashboard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForScreen(3);
    });
  }

  void _loadDataForScreen(int index) {
    // Only load if not already loaded
    if (_loadedScreens.contains(index)) return;

    _loadedScreens.add(index);

    // Load data based on screen
    switch (index) {
      case 0: // Sales screen
        ref.read(salesNotifierProvider.notifier).loadSales();
        break;
      case 1: // Expenses screen
        ref.read(expensesNotifierProvider.notifier).loadExpenses();
        break;
      case 2: // Suppliers screen
        ref.read(suppliersNotifierProvider.notifier).loadSuppliers();
        break;
      case 3: // Dashboard screen (loads all data)
        ref.read(salesNotifierProvider.notifier).loadSales();
        ref.read(expensesNotifierProvider.notifier).loadExpenses();
        ref.read(suppliersNotifierProvider.notifier).loadSuppliers();
        break;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Load data for the selected screen only once
    _loadDataForScreen(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          SalesScreen(),
          ExpensesScreen(),
          SuppliersScreen(),
          DashboardScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        items: const [
          NavItem(
            icon: Icons.trending_up_outlined,
            selectedIcon: Icons.trending_up,
            label: 'Sales',
          ),
          NavItem(
            icon: Icons.trending_down_outlined,
            selectedIcon: Icons.trending_down,
            label: 'Expenses',
          ),
          NavItem(
            icon: Icons.business_outlined,
            selectedIcon: Icons.business,
            label: 'Suppliers',
          ),
          NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
