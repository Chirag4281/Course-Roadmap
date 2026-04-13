import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers.dart';
import '../../../core/themes/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../features/courses/models/course_suggestion.dart';
import '../../dashboard/screens/app_drawer.dart';
import '../../profile/models/user_profile.dart';

class CourseDiscoveryScreen extends ConsumerStatefulWidget {
  const CourseDiscoveryScreen({super.key});

  @override
  ConsumerState<CourseDiscoveryScreen> createState() => _CourseDiscoveryScreenState();
}

class _CourseDiscoveryScreenState extends ConsumerState<CourseDiscoveryScreen> {
  bool _isGenerating = false;

  Future<void> _generateSuggestions() async {
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await ref.read(courseSuggestionsProvider.notifier).generateSuggestions();
    } catch (e) {
      print('Error generating suggestions: $e');
    }

    if (context.mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-generate suggestions if profile is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndGenerateSuggestions();
    });
  }

  Future<void> _checkAndGenerateSuggestions() async {
    try {
      final profile = await ref.read(storageServiceProvider).getProfile();
      if (profile != null && profile.interests.isNotEmpty) {
        _generateSuggestions();
      }
    } catch (e) {
      print('Error checking profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(courseSuggestionsProvider);

    // ✅ CORRECT WAY TO ACCESS USER PROFILE
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.valueOrNull;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: CustomAppBar(
        title: 'Course Suggestions',
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isGenerating ? null : _generateSuggestions,
              tooltip: 'Regenerate suggestions',
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile Summary Banner
          if (profile != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(profile.highestQualification),
                              backgroundColor: Colors.grey.shade200,
                            ),
                            ...profile.interests.map((interest) => Chip(
                              label: Text(interest),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/profile-setup'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Suggestions Content
          Expanded(
            child: suggestionsAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
                  data: (courses) => courses.isEmpty
                  ? _buildEmptyState(profile)
                  : _buildCourseList(courses),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: profile == null
            ? () => context.go('/profile-setup')
            : _isGenerating ? null : _generateSuggestions,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: _isGenerating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 20, color: Colors.white),
            const SizedBox(height: 12),
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 180, height: 16, color: Colors.white),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 40, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to generate suggestions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generateSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/profile-setup'),
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(UserProfile? profile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              profile == null
                  ? 'Complete Your Profile'
                  : 'Get Personalized Course Suggestions',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              profile == null
                  ? 'Tell us about your qualifications and interests to get AI-powered course recommendations'
                  : 'Tap the magic wand button below to discover courses perfect for your career path',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: profile == null
                    ? () => context.go('/profile-setup')
                    : _generateSuggestions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  profile == null ? 'Create Profile' : 'Generate Suggestions',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(List<CourseSuggestion> courses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(context, course, index);
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseSuggestion course, int index) {
    final colors = [
      [Colors.blue, Colors.indigo],
      [Colors.green, Colors.teal],
      [Colors.orange, Colors.deepOrange],
      [Colors.purple, Colors.pink],
      [Colors.cyan, Colors.lightBlue],
    ];

    final gradientColors = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/courses/detail/${course.title}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.difficulty,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${course.durationWeeks} weeks',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 5))
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.description,
                    style: const TextStyle(height: 1.5, color: Colors.grey),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Salary Range
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Potential Salary: ${course.estimatedSalary}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/courses/detail/${course.title}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradientColors[0],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'View Course Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}