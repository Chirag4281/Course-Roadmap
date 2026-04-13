import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../features/enrollment/models/enrollment.dart';
import '../../../providers.dart';
import '../../../widgets/custom_app_bar.dart';
import 'app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentProvider);

    // 🔴 DEBUG: Add this
    if (enrollmentsAsync is AsyncData) {
      if (enrollmentsAsync.valueOrNull is! List) {
        print('🚨 CRITICAL: enrollments is NOT a list! It is: ${enrollmentsAsync.valueOrNull.runtimeType}');
        print('Value: ${enrollmentsAsync.valueOrNull}');
        // Force error so you see it
        throw Exception('enrollments must be List<Enrollment>, got ${enrollmentsAsync.valueOrNull.runtimeType}');
      }
    }


    return Scaffold(
      drawer: const AppDrawer(),
      appBar: CustomAppBar(title: 'My Learning Dashboard'),
      body: enrollmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(enrollmentProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
            data: (enrollments) {
          return _DashboardContent(enrollments: enrollments);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/courses'),
        child: const Icon(Icons.explore),
      ),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  final List<Enrollment> enrollments;

  const _DashboardContent({required this.enrollments});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  late Future<double> _overallProgressFuture;
  late Future<double> _totalSpentFuture;

  @override
  void initState() {
    super.initState();
    _overallProgressFuture =
        ref.read(storageServiceProvider).getOverallProgress();
    _totalSpentFuture = ref.read(storageServiceProvider).getTotalSpent();
  }

  // New: Cancel enrollment with 50% refund
  Future<void> _cancelEnrollment(Enrollment enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Enrollment?'),
        content: Text(
          'You will receive a 100% refund of ₹${(enrollment.courseFee * 0.5).toStringAsFixed(0)} '
              'for "${enrollment.courseTitle}".\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final refundAmount = enrollment.courseFee;

        // Cancel enrollment (now fixed to use proper JSON string handling)
        await ref.read(storageServiceProvider).cancelEnrollment(
          enrollment.courseId,
          refundAmount,
        );

        // ✅ Refresh ALL data manually via setState — keeping your lines exactly as-is
        setState(() {
          ref.refresh(enrollmentProvider);
          // These two lines stay unchanged 👇
          _overallProgressFuture = ref.read(storageServiceProvider).getOverallProgress();
          _totalSpentFuture = ref.read(storageServiceProvider).getTotalSpent();

          // But you MUST also refresh enrollments, or the canceled item stays visible!
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refund of ₹${refundAmount.toStringAsFixed(0)} processed!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          print('Cancellation error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cancellation failed: ${e.toString().substring(0, 50)}...')),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(enrollmentProvider);
        setState(() {
          _overallProgressFuture =
              ref.read(storageServiceProvider).getOverallProgress();
          _totalSpentFuture = ref.read(storageServiceProvider).getTotalSpent();
        });
      },
      child: FutureBuilder<double>(
        future: _overallProgressFuture,
        builder: (context, progressSnapshot) {
          return FutureBuilder<double>(
            future: _totalSpentFuture,
            builder: (context, spentSnapshot) {
              if (progressSnapshot.connectionState == ConnectionState.waiting ||
                  spentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (progressSnapshot.hasError || spentSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${progressSnapshot.error ??
                      spentSnapshot.error}'),
                );
              }

              final overallProgress = progressSnapshot.data ?? 0.0;
              final totalSpent = spentSnapshot.data ?? 0.0;

              // ✅ Build sections safely
              final List<Widget> sections = [];

              // 1. Progress Summary
              sections.add(
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme
                            .of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        Theme
                            .of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Overall Progress',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircularPercentIndicator(
                        radius: 80,
                        lineWidth: 12,
                        percent: overallProgress / 100,
                        center: Text(
                          '${overallProgress.toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        progressColor: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                        backgroundColor: Colors.grey.shade200,
                        animation: false, // Prevent layout crash
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total Investment: ₹${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              // 2. Student Info Card (NEW)
              final profile = ref
                  .watch(userProfileProvider)
                  .valueOrNull;
              sections.add(
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme
                              .of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.name ?? 'Student Name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.email ?? 'student@example.com',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qualification: ${profile
                                    ?.highestQualification ?? 'Not set'}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // 3. Quick Actions
              sections.add(
                Row(
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.school,
                      title: 'Continue Learning',
                      onTap: () {
                        if (widget.enrollments.isNotEmpty) {
                          final course = widget.enrollments.first;
                          context.go('/courses/detail/${course.courseId}');
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      context,
                      icon: Icons.analytics,
                      title: 'Career Paths',
                      onTap: () => context.go('/courses'),
                    ),
                  ],
                ),
              );

              // 4. My Courses Header
              sections.add(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Courses',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.go('/courses'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              );

              // 5. Course List or Empty State
              if (widget.enrollments.isEmpty) {
                sections.add(
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey
                            .shade400),
                        const SizedBox(height: 24),
                        const Text('No courses enrolled yet', style: TextStyle(
                            fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/courses'),
                          child: const Text('Discover Courses'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                for (final enrollment in widget.enrollments) {
                  sections.add(_buildCourseCard(context, enrollment, ref));
                }
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) => sections[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Theme
                    .of(context)
                    .colorScheme
                    .primary),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Enrollment enrollment,
      WidgetRef ref) {
    // Safe title
    final displayTitle = enrollment.courseTitle
        .trim()
        .isNotEmpty
        ? enrollment.courseTitle
        : enrollment.courseId
        .trim()
        .isNotEmpty
        ? enrollment.courseId
        : 'Untitled Course';

    // Safe date
    final dateString = enrollment.enrolledAt != null
        ? '${enrollment.enrolledAt!.day}/${enrollment.enrolledAt!
        .month}/${enrollment.enrolledAt!.year}'
        : 'Date unknown';

    final totalLectures = enrollment.totalLectures > 0 ? enrollment
        .totalLectures : 1;
    final completedLectures = enrollment.completedLectures.clamp(
        0, totalLectures);
    final progress = completedLectures / totalLectures;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onLongPress: () {
          _cancelEnrollment(enrollment); // Reuse your existing cancel logic
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/courses/detail/${enrollment.courseId}'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\u{20B9}${enrollment.courseFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enrolled on $dateString',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}% completed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                      Text(
                        '$completedLectures/$totalLectures lectures',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}