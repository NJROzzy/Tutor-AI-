import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

import 'pages/child/child_home_page.dart';
import 'pages/child/math_modules_page.dart';
import 'pages/child/english_modules_page.dart';
import 'pages/child/lesson_player_page.dart';
import 'pages/child/reward_page.dart';

import 'pages/parent/parent_home_page.dart';
import 'pages/parent/progress_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpParentPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),

    // Child wireframe + MVP
    GoRoute(path: '/child', builder: (_, __) => const ChildHomePage()),
    GoRoute(path: '/child/math', builder: (_, __) => const MathModulesPage()),
    GoRoute(
        path: '/child/english', builder: (_, __) => const EnglishModulesPage()),
    GoRoute(
        path: '/child/lesson',
        builder: (ctx, st) => LessonPlayerPage(
              subject: st.uri.queryParameters['subject'] ?? 'math',
              module: st.uri.queryParameters['module'] ?? 'counting',
            )),
    GoRoute(
        path: '/child/reward',
        builder: (ctx, st) =>
            RewardPage(score: (st.extra as int?) ?? 0, total: 5)),

    // Parent wireframe
    GoRoute(path: '/parent', builder: (_, __) => const ParentHomePage()),
    GoRoute(path: '/parent/progress', builder: (_, __) => const ProgressPage()),
  ],
);
