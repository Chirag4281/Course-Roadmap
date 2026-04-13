import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/onboarding_screen.dart';
import '../features/courses/screens/course_discovery_screen.dart';
import '../features/courses/screens/video_player_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/profile/screens/course_detail_screen.dart';
import '../features/profile/screens/profile_setup_screen.dart';
import '../providers.dart';

class AppRouter {
  final WidgetRef _ref; // 👈 Use WidgetRef, not Ref<Object?>

  AppRouter(this._ref);

  late final GoRouter config = GoRouter(
    initialLocation: '/',
    routes: [
      // Your existing routes...
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const CourseDiscoveryScreen(),
        routes: [
          GoRoute(
            path: 'detail/:courseId',
            name: 'course-detail',
            builder: (context, state) => CourseDetailScreen(
              courseId: state.pathParameters['courseId']!,
            ),
            routes: [
              GoRoute(
                path: 'video/:lectureNumber',
                name: 'video-player',
                builder: (context, state) => VideoPlayerScreen(
                  courseId: state.pathParameters['courseId']!,
                  lectureNumber: int.parse(state.pathParameters['lectureNumber']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) async { // 👈 MAKE THIS ASYNC
      // 👇 AWAIT THE FUTURE AND GET THE BOOL VALUE
      final bool isProfileComplete = await _ref.read(storageServiceProvider).isProfileComplete();

      final String currentPath = state.uri.toString();

      // Now you can safely use isProfileComplete (which is bool) with &&
      if (currentPath == '/' && isProfileComplete) {
        return '/dashboard';
      }

      if (!isProfileComplete &&
          currentPath != '/' &&
          !currentPath.startsWith('/profile-setup')) {
        return '/profile-setup';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.error}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}