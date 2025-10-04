import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekindle/auth/auth_gate.dart';
import 'package:rekindle/pages/auth/login_page.dart';
import 'package:rekindle/pages/auth/register_page.dart';
import 'package:rekindle/pages/auth/reset_password_page.dart';
import 'package:rekindle/pages/home/home_page.dart';
import 'package:rekindle/pages/topics_page.dart';
import 'package:rekindle/pages/due_assessments_page.dart';
import 'package:rekindle/pages/assessment_page.dart';
import 'package:rekindle/pages/assessment_results_page.dart';

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
          path: 'topics', // Will be /home/topics
          builder: (BuildContext context, GoRouterState state) {
            return const TopicsPage();
          },
        ),
        
        GoRoute(
          path: 'due-assessments', // Will be /home/due-assessments
          builder: (context, state) => const DueAssessmentsPage(),
        ),

        GoRoute(
          path: 'assessment/:assessmentId', // Assessment Page
          builder: (context, state) {
            final assessmentId = state.pathParameters['assessmentId']!;
            return AssessmentPage(assessmentId: assessmentId);
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'results/:attemptId',
              builder: (context, state) {
                final attemptId = state.pathParameters['attemptId']!;
                // This is the correct way to build the page now
                return AssessmentResultsPage(attemptId: attemptId);
              },
            ),
          ],
        ),
      ]
    ),
  ],
);
