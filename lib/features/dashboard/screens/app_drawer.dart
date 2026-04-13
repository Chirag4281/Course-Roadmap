import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Get current route safely
    final currentPath = GoRouterState.of(context).uri.toString();
    final profileAsync = ref.watch(userProfileProvider);

    bool _isSelected(String routePath) {
      if (currentPath == routePath) return true;
      // Handle nested routes: /courses/detail/123 → still matches /courses
      if (routePath != '/' && currentPath.startsWith('$routePath/')) return true;
      return false;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  profileAsync.when(
                    loading: () => 'Welcome!',
                    error: (err, stack) => 'Welcome!',
                        data: (profile) {
                      if (profile?.name != null && profile!.name.trim().isNotEmpty) {
                        return 'Welcome, ${profile.name}';
                      } else {
                        return 'Welcome!';
                      }
                    },
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _isSelected('/dashboard'),
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            onTap: () {
              Navigator.of(context).pop();
              if (!_isSelected('/dashboard')) {
                context.go('/dashboard');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Courses'),
            selected: _isSelected('/courses'),
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            onTap: () {
              Navigator.of(context).pop();
              if (!_isSelected('/courses')) {
                context.go('/courses');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            selected: _isSelected('/profile-setup'),
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            onTap: () {
              Navigator.of(context).pop();
              if (!_isSelected('/profile-setup')) {
                context.go('/profile-setup');
              }
            },
          ),

        ],
      ),
    );
  }
}