import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekindle/auth/auth_gate.dart';
import 'package:rekindle/pages/auth/login_page.dart';
import 'package:rekindle/pages/auth/register_page.dart';
import 'package:rekindle/pages/auth/reset_password_page.dart';
import 'package:rekindle/pages/home/home_page.dart';
import 'package:rekindle/pages/topics_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/', // start here
  routes: <RouteBase>[
    // ---------- AUTH FLOW ----------
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthGate(); // splash/auth gate
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/login', // /login
          builder: (BuildContext context, GoRouterState state) {
            return const LoginPage();
          },
        ),
        GoRoute(
          path: '/register', // /register
          builder: (BuildContext context, GoRouterState state) {
            return const RegisterPage();
          },
        ),
        GoRoute(
          path: '/reset-password', // /reset-password
          builder: (BuildContext context, GoRouterState state) {
            return const ResetPasswordPage();
          },
        ),
      ],
    ),

    // ---------- HOME FLOW ----------
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'topics', // /login
          builder: (BuildContext context, GoRouterState state) {
            return const TopicsPage();
          },
        ),
      ]
    ),
  ],
);
