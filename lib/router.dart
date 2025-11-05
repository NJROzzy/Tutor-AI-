import 'package:go_router/go_router.dart';

// --- Core Pages ---
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'main.dart' show StartScreen;

// --- Parent Onboarding Flow ---
import 'pages/parent/parent_onboarding_page.dart';
import 'pages/parent/add_child_page.dart';
import 'pages/parent/select_child_page.dart';

// --- Child Pages ---
import 'pages/child/child_home_page.dart';
import 'pages/child/math_modules_page.dart';
import 'pages/child/english_modules_page.dart';
import 'pages/child/lesson_player_page.dart';
import 'pages/child/reward_page.dart';

// --- Parent Pages ---
import 'pages/parent/parent_profiles_page.dart';
import 'pages/parent/parent_home_page.dart';
import 'pages/parent/progress_page.dart';

/// Global router for the entire Tutor AI app
final appRouter = GoRouter(
  // 👇 Start your app from the Start screen
  initialLocation: '/start',

  routes: [
    // --- App Start ---
    GoRoute(
      path: '/start',
      builder: (_, __) => const StartScreen(),
    ),

    // --- Auth Pages ---
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (_, __) => const SignUpParentPage(),
    ),

    // --- Main Home ---
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomePage(),
    ),

    // --- Parent Onboarding Flow ---
    GoRoute(
      path: '/parent/onboarding',
      builder: (_, __) => const ParentOnboardingPage(),
    ),
    GoRoute(
      path: '/parent/add-child',
      builder: (_, __) => const AddChildPage(),
    ),
    GoRoute(
      path: '/parent/select-child',
      builder: (_, __) => const SelectChildPage(),
    ),

    // --- Child Section ---
    GoRoute(
      path: '/child',
      builder: (_, __) => const ChildHomePage(),
    ),
    GoRoute(
      path: '/child/math',
      builder: (_, __) => const MathModulesPage(),
    ),
    GoRoute(
      path: '/child/english',
      builder: (_, __) => const EnglishModulesPage(),
    ),
    GoRoute(
      path: '/child/lesson',
      builder: (ctx, st) => LessonPlayerPage(
        subject: st.uri.queryParameters['subject'] ?? 'math',
        module: st.uri.queryParameters['module'] ?? 'counting',
      ),
    ),
    GoRoute(
      path: '/child/reward',
      builder: (ctx, st) => RewardPage(
        score: (st.extra as int?) ?? 0,
        total: 5,
      ),
    ),

    // --- Parent Main Section ---
    GoRoute(
      path: '/parent',
      builder: (_, __) => const ParentHomePage(),
    ),
    GoRoute(
      path: '/parent/progress',
      builder: (_, __) => const ProgressPage(),
    ),
    GoRoute(
        path: '/parent/profiles',
        builder: (_, __) => const ParentProfilesPage()),
  ],
);
