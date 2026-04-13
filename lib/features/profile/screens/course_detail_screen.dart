import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers.dart';
import '../../../core/themes/app_theme.dart';
import '../../../widgets/roadmap_visualizer.dart';
import '../../../features/courses/models/course_suggestion.dart';
import '../../../features/enrollment/models/enrollment.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  late Future<List<dynamic>> _lecturesFuture;
  bool _isEnrolled = false;
  double _courseFee = 0.0;
  final Map<String, Color> _courseColors = {
    'advanced': const Color(0xFF6A11CB),
    'professional': const Color(0xFF2575FC),
    'excel': const Color(0xFF009245),
    'basic': const Color(0xFFFDC830),
    'default': const Color(0xFF667EEA),
  };
  late ScrollController _scrollController;
  bool _showTabs = true;
  double _lastOffset = 0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // Calculate dynamic fee
    _calculateCourseFee();

    // Fetch lectures
    _lecturesFuture = ref.read(courseServiceProvider).getCourseLectures(
      widget.courseId,
      ref.read(userProfileProvider).valueOrNull?.interests ?? [],
    );

    // Check enrollment status asynchronously
    _checkEnrollmentStatus();
  }
  Future<void> _shareCourse(String method, CourseSuggestion course) async {
    final courseUrl = 'https://course_road_map.com/courses/${Uri.encodeComponent(widget.courseId)}';

    // Create share text with less formatting for better compatibility
    final shareText = '''
Check out this amazing course!

*${course.title}*

${course.description}

📅 Duration: ${course.durationWeeks} weeks
📊 Level: ${course.difficulty}
💰 Salary: ${course.estimatedSalary}

Key Benefits:
${course.pros.take(3).map((pro) => '• $pro').join('\n')}

Course Link: $courseUrl

Happy Learning! 🚀
  ''';

    switch (method) {
      case 'whatsapp':
        await _shareToWhatsApp(shareText);
        break;
      case 'copy':
        await _copyToClipboard(shareText);
        break;
    }
  }

  Future<void> _shareToWhatsApp(String text) async {
    try {
      // Clean the text - remove asterisks that might cause issues
      final cleanText = text.replaceAll('*', '');

      // Try different WhatsApp URLs
      final urls = [
        'https://wa.me/?text=${Uri.encodeComponent(cleanText)}',
        'whatsapp://send?text=${Uri.encodeComponent(cleanText)}',
        'https://api.whatsapp.com/send?text=${Uri.encodeComponent(cleanText)}',
      ];

      bool whatsappInstalled = false;

      for (final url in urls) {
        if (await canLaunchUrl(Uri.parse(url))) {
          whatsappInstalled = true;
          try {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            return; // Success, exit function
          } catch (e) {
            print('Failed to launch URL $url: $e');
            continue; // Try next URL
          }
        }
      }

      if (!whatsappInstalled) {
        // WhatsApp not installed, show dialog
        _showWhatsAppNotInstalledDialog(cleanText);
      }

    } catch (e) {
      print('Error in _shareToWhatsApp: $e');
      // Fallback to clipboard
      await _copyToClipboard(text);
      _showMessage('Error sharing. Text copied to clipboard!');
    }
  }

  void _showWhatsAppNotInstalledDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Not Found'),
        content: const Text('WhatsApp is not installed on your device. Would you like to copy the course details to clipboard instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _copyToClipboard(text);
              _showMessage('Course details copied to clipboard!');
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('Copied to clipboard!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;

      // Show tabs when scrolling up, hide when scrolling down
      if (currentOffset > _lastOffset + 50) {
        // Scrolling down
        if (_showTabs) {
          setState(() {
            _showTabs = false;
          });
        }
        _lastOffset = currentOffset;
      } else if (currentOffset < _lastOffset - 30) {
        // Scrolling up
        if (!_showTabs) {
          setState(() {
            _showTabs = true;
          });
        }
        _lastOffset = currentOffset;
      }

      // Always show tabs at top
      if (currentOffset <= 100) {
        if (!_showTabs) {
          setState(() {
            _showTabs = true;
          });
        }
      }
    }
  }
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _checkEnrollmentStatus() async {
    try {
      final enrollments = await ref.read(storageServiceProvider).getEnrollments();
      final isEnrolled = enrollments.any((e) => e.courseId == widget.courseId);

      if (mounted) {
        setState(() {
          _isEnrolled = isEnrolled;
        });
      }
    } catch (e) {
      print('Error checking enrollment status: $e');
    }
  }

  void _calculateCourseFee() {
    final lowerCaseId = widget.courseId.toLowerCase();

    // More dynamic and varied fee calculation
    if (lowerCaseId.contains('advanced')) {
      _courseFee = 7499.0;
    } else if (lowerCaseId.contains('professional') || lowerCaseId.contains('pro')) {
      _courseFee = 6499.0;
    } else if (lowerCaseId.contains('master') || lowerCaseId.contains('expert')) {
      _courseFee = 8999.0;
    } else if (lowerCaseId.contains('intermediate')) {
      _courseFee = 4499.0;
    } else if (lowerCaseId.contains('beginner') || lowerCaseId.contains('basic')) {
      _courseFee = 2999.0;
    } else if (lowerCaseId.contains('excel') || lowerCaseId.contains('spreadsheet')) {
      _courseFee = 3999.0;
    } else if (lowerCaseId.contains('data') && lowerCaseId.contains('science')) {
      _courseFee = 9999.0;
    } else if (lowerCaseId.contains('ai') || lowerCaseId.contains('machine learning')) {
      _courseFee = 11999.0;
    } else if (lowerCaseId.contains('web') || lowerCaseId.contains('development')) {
      _courseFee = 5499.0;
    } else if (lowerCaseId.contains('mobile') || lowerCaseId.contains('app')) {
      _courseFee = 5999.0;
    } else if (lowerCaseId.contains('design') || lowerCaseId.contains('ui/ux')) {
      _courseFee = 4999.0;
    } else if (lowerCaseId.contains('finance') || lowerCaseId.contains('accounting')) {
      _courseFee = 6999.0;
    } else if (lowerCaseId.contains('marketing') || lowerCaseId.contains('digital')) {
      _courseFee = 4499.0;
    } else if (lowerCaseId.contains('language') || lowerCaseId.contains('english')) {
      _courseFee = 2499.0;
    } else if (lowerCaseId.contains('business') || lowerCaseId.contains('management')) {
      _courseFee = 7999.0;
    } else {
      // Default tiered pricing based on course length and complexity
      final randomBase = (widget.courseId.hashCode % 5000).abs() + 1999.0;
      _courseFee = randomBase + (widget.courseId.length * 100);
    }

    // Round to nearest 99
    _courseFee = (_courseFee ~/ 100) * 100 - 1;
  }

  Color _getCourseColor() {
    final lowerCaseId = widget.courseId.toLowerCase();
    if (lowerCaseId.contains('advanced')) return _courseColors['advanced']!;
    if (lowerCaseId.contains('professional')) return _courseColors['professional']!;
    if (lowerCaseId.contains('excel')) return _courseColors['excel']!;
    if (lowerCaseId.contains('basic')) return _courseColors['basic']!;
    return _courseColors['default']!;
  }

  String _getCourseLevel() {
    final lowerCaseId = widget.courseId.toLowerCase();
    if (lowerCaseId.contains('advanced') || lowerCaseId.contains('expert')) return 'Advanced';
    if (lowerCaseId.contains('professional') || lowerCaseId.contains('pro')) return 'Professional';
    if (lowerCaseId.contains('intermediate')) return 'Intermediate';
    if (lowerCaseId.contains('beginner') || lowerCaseId.contains('basic')) return 'Beginner';
    return 'All Levels';
  }

  Future<void> _enrollInCourse() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;

    final lectures = await _lecturesFuture;

    final enrollment = Enrollment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: widget.courseId,
      courseTitle: widget.courseId,
      courseFee: _courseFee,
      enrolledAt: DateTime.now(),
      totalLectures: lectures.length,
      completedLectures: 0,
      lecturesProgress: List.filled(lectures.length, false),
    );

    await ref.read(enrollmentProvider.notifier).enrollInCourse(enrollment);

    if (context.mounted) {
      setState(() {
        _isEnrolled = true;
      });

      // Show success animation
      _showEnrollmentSuccess();
    }
  }

  void _showEnrollmentSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _getCourseColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 Enrolled Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getCourseColor(),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'You now have full access to ${widget.courseId}. Start learning immediately!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue Browsing'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.go('/courses/detail/${widget.courseId}/video/1');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCourseColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Learning', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseColor = _getCourseColor();
    final courseLevel = _getCourseLevel();

    final course = CourseSuggestion(
      title: widget.courseId,
      description: 'Master ${widget.courseId} with industry experts. Learn practical skills that employers value through hands-on projects and real-world applications.',
      durationWeeks: 6,
      difficulty: courseLevel,
      estimatedSalary: '\$60,000 - \$120,000',
      pros: [
        'High demand in job market',
        'Transferable skills across industries',
        'Strong earning potential',
        'Remote work opportunities',
        'Continuous learning path',
        'Global recognition'
      ],
      cons: [
        'Requires consistent practice',
        'Rapidly evolving field',
        'Initial learning curve',
        'Time commitment required'
      ],
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: NestedScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 350, // Increased height for better visibility
                collapsedHeight: 80,
                pinned: true,
                floating: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: courseColor),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.share, color: courseColor),
                      onSelected: (value) => _shareCourse(value, course),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'whatsapp',
                          child: Row(
                            children: [
                              Icon(Icons.chat, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Share via WhatsApp'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Share via...'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Text('Copy Link'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final expandedHeight = MediaQuery.of(context).size.width > 600 ? 350 : 320;
                    final visible = top > kToolbarHeight * 1.5;

                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      titlePadding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: visible ? 12 : 0,
                      ),
                      title: visible
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.title.length > 25
                              ? '${course.title.substring(0, 25)}...'
                              : course.title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          : null,
                      background: Container(
                        height: 350,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              courseColor.withOpacity(0.9),
                              courseColor.withOpacity(0.7),
                              courseColor.withOpacity(0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background pattern
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: const NetworkImage(
                                        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Main content
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Course level badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        courseLevel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Course title - Larger and more prominent
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Course description
                                    Text(
                                      'Master ${widget.courseId} with expert guidance',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.4,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Stats row
                                    Row(
                                      children: [
                                        // Duration
                                        Expanded(
                                          child: _InfoChip(
                                            icon: Icons.schedule,
                                            text: '${course.durationWeeks} weeks',
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Salary
                                        Expanded(
                                          child: _InfoChip(
                                            icon: Icons.attach_money,
                                            text: course.estimatedSalary,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Difficulty
                                        Expanded(
                                          child: _InfoChip(
                                            icon: Icons.school,
                                            text: course.difficulty,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Enrollment status
                                    if (_isEnrolled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.green),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Enrolled',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                bottom: _showTabs
                    ? PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicatorColor: courseColor,
                      labelColor: courseColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
                      splashBorderRadius: BorderRadius.circular(10),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.info_outline, size: 20),
                          text: 'Overview',
                        ),
                        Tab(
                          icon: Icon(Icons.play_circle_outline, size: 20),
                          text: 'Lectures',
                        ),
                        Tab(
                          icon: Icon(Icons.timeline_outlined, size: 20),
                          text: 'Roadmap',
                        ),
                      ],
                    ),
                  ),
                )
                    : null,
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildOverviewTab(course, courseColor),
                FutureBuilder<List<dynamic>>(
                  future: _lecturesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerLectures();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    final lectures = snapshot.data!;
                    return _buildLecturesTab(lectures, courseColor);
                  },
                ),
                RoadmapVisualizer(course: course),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _isEnrolled
            ? null
            : _buildEnrollmentBottomBar(courseColor),
      ),
    );
  }
  Widget _buildOverviewTab(CourseSuggestion course, Color courseColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 32),
          _buildStatsSection(course),
          const SizedBox(height: 32),
          _buildProsConsSection(course, courseColor),
          const SizedBox(height: 32),
          _buildCareerOutlook(courseColor),
          const SizedBox(height: 32),
          _buildInstructorSection(courseColor),
          const SizedBox(height: 32),
          _buildCourseHighlights(),
          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildStatsSection(CourseSuggestion course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              value: '${course.durationWeeks}',
              label: 'Weeks',
              icon: Icons.calendar_today,
            ),
            const SizedBox(width: 24),
            _StatItem(
              value: '45+',
              label: 'Hours',
              icon: Icons.timer,
            ),
            const SizedBox(width: 24),
            _StatItem(
              value: '24/7',
              label: 'Support',
              icon: Icons.support_agent,
            ),
            const SizedBox(width: 24),
            _StatItem(
              value: 'Certificate',
              label: 'Included',
              icon: Icons.verified,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProsConsSection(CourseSuggestion course, Color courseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Breakdown',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Desktop/Tablet layout
              return Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Strengths',
                      items: course.pros,
                      icon: Icons.thumb_up,
                      color: Colors.green,
                      iconColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Considerations',
                      items: course.cons,
                      icon: Icons.lightbulb,
                      color: Colors.amber,
                      iconColor: Colors.amber[700]!,
                    ),
                  ),
                ],
              );
            } else {
              // Mobile layout
              return Column(
                children: [
                  _buildFeatureCard(
                    title: 'Strengths',
                    items: course.pros,
                    icon: Icons.thumb_up,
                    color: Colors.green,
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    title: 'Considerations',
                    items: course.cons,
                    icon: Icons.lightbulb,
                    color: Colors.amber,
                    iconColor: Colors.amber[700]!,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, color: iconColor, size: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCareerOutlook(Color courseColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            courseColor.withOpacity(0.08),
            courseColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: courseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: courseColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Career Outlook',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This field is projected to grow 25% faster than average over the next decade. Companies are actively seeking professionals with these skills, especially in fintech, e-commerce, and SaaS industries.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _CareerTag(text: 'High Demand', emoji: '🔥'),
              _CareerTag(text: 'Remote Friendly', emoji: '🏠'),
              _CareerTag(text: 'Fast Growing', emoji: '📈'),
              _CareerTag(text: 'Global Opportunities', emoji: '🌎'),
              _CareerTag(text: 'High Salary', emoji: '💰'),
              _CareerTag(text: 'Future Proof', emoji: '🛡️'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorSection(Color courseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet Your Instructor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: courseColor, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1560250097-0b93528c311a?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=400&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dr. Sarah Johnson',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Senior ${widget.courseId} Expert',
                      style: TextStyle(
                        fontSize: 14,
                        color: courseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '10+ years industry experience. Former lead at Google. Passionate about teaching practical skills.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star_half, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          '4.8 • 2,450 reviews',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Highlights',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _HighlightCard(
                  icon: Icons.video_library,
                  title: '50+ Video Lectures',
                  subtitle: 'HD Quality',
                  color: Colors.blue,
                ),
                _HighlightCard(
                  icon: Icons.assignment,
                  title: '25+ Assignments',
                  subtitle: 'Hands-on Practice',
                  color: Colors.green,
                ),
                _HighlightCard(
                  icon: Icons.forum,
                  title: 'Community Access',
                  subtitle: 'Peer Support',
                  color: Colors.purple,
                ),
                _HighlightCard(
                  icon: Icons.download,
                  title: 'Resources',
                  subtitle: 'Downloadable Materials',
                  color: Colors.orange,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildShimmerLectures() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 50, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() {
                _lecturesFuture = ref.read(courseServiceProvider).getCourseLectures(
                  widget.courseId,
                  ref.read(userProfileProvider).valueOrNull?.interests ?? [],
                );
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCourseColor(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturesTab(List<dynamic> lectures, Color courseColor) {
    final enrollment = ref.watch(enrollmentProvider).valueOrNull?.firstWhere(
          (e) => e.courseId == widget.courseId,
      orElse: () => Enrollment.empty(widget.courseId, lectures.length),
    );

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        final isCompleted = enrollment?.lecturesProgress[index] ?? false;
        final isPreview = lecture['is_preview'] ?? false;
        final duration = lecture['duration_minutes'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : courseColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Colors.green, size: 24)
                  : Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: courseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              lecture['title'] ?? 'Lecture ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isCompleted ? Colors.green : Colors.black,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture['description'] ?? 'Comprehensive lecture content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$duration min',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      if (isPreview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Preview',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            trailing: _isEnrolled || isPreview
                ? IconButton(
              icon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: courseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.play_arrow,
                  color: isCompleted ? Colors.green : courseColor,
                  size: 24,
                ),
              ),
              onPressed: () {
                if (isPreview || _isEnrolled) {
                  context.go('/courses/detail/${widget.courseId}/video/${index + 1}');
                }
              },
            )
                : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.grey, size: 20),
            ),
            onTap: _isEnrolled || isPreview
                ? () {
              context.go('/courses/detail/${widget.courseId}/video/${index + 1}');
            }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentBottomBar(Color courseColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\u{20B9}${NumberFormat('#,##0').format(_courseFee)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_courseFee > 3999)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Best Value',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Limited Time Offer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🚀 7-Day Money Back',
                      style: TextStyle(
                        fontSize: 14,
                        color: courseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enrollInCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: courseColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: courseColor.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_checkout, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Enroll Now & Get Lifetime Access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '30-Day Money-Back Guarantee • Certificate Included • 24/7 Support',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _CareerTag extends StatelessWidget {
  final String text;
  final String emoji;

  const _CareerTag({
    required this.text,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}