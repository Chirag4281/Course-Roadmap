import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../providers.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/enrollment/models/enrollment.dart';
import 'package:go_router/go_router.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String courseId;
  final int lectureNumber;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    required this.lectureNumber,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isInitialized = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerAndProgress();
  }

  // ✅ CORRECTED: Make initialization async
  Future<void> _initializeVideoPlayerAndProgress() async {
    try {
      // 👇 AWAIT the Future to get actual List<Enrollment>
      final enrollments = await ref.read(storageServiceProvider).getEnrollments();
      final enrollment = enrollments.firstWhere(
            (e) => e.courseId == widget.courseId,
        orElse: () => Enrollment.empty(widget.courseId, 10),
      );

      setState(() {
        _isCompleted = enrollment.lecturesProgress[widget.lectureNumber - 1];
      });

      // Initialize video player
      await _initializeVideoPlayer();
    } catch (e) {
      print('Error initializing video player: $e');
      // Handle error appropriately
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lecture: $e')),
        );
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    // In production, fetch actual video URL from backend
    // For demo, use placeholder videos
    final placeholderVideos = [
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',


      
    ];

    final videoUrl = placeholderVideos[widget.lectureNumber % placeholderVideos.length];

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControlsOnInitialize: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        bufferedColor: Colors.grey.shade300,
        handleColor: Theme.of(context).colorScheme.primary,
      ),
    );

    // Listen for completion
    _videoController.addListener(() {
      if (_videoController.value.duration == _videoController.value.position && !_isCompleted) {
        _markAsCompleted();
      }
    });

    if (context.mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _markAsCompleted() async {
    // Update progress in storage FIRST
    await ref.read(enrollmentProvider.notifier).updateLectureProgress(
      widget.courseId,
      widget.lectureNumber,
      true,
    );

    // Then update local state
    if (mounted) {
      setState(() {
        _isCompleted = true;
      });
    }

    // Show completion celebration
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text('Lecture ${widget.lectureNumber} completed!'),
            ],
          ),
          action: SnackBarAction(
            label: 'Next',
            onPressed: () async {
              final enrollments = await ref.read(storageServiceProvider).getEnrollments();
              final enrollment = enrollments.firstWhere(
                    (e) => e.courseId == widget.courseId,
                orElse: () => Enrollment.empty(widget.courseId, 10),
              );

              if (widget.lectureNumber < enrollment.totalLectures) {
                // ✅ Update the NEXT lecture's completion status
                await ref.read(enrollmentProvider.notifier).updateLectureProgress(
                  widget.courseId,
                  widget.lectureNumber + 1,
                  false, // Set next lecture as NOT completed
                );

                // Then navigate
                context.go('/courses/detail/${widget.courseId}/video/${widget.lectureNumber + 1}');
              } else {
                // Return to course detail screen
                context.go('/courses/detail/${widget.courseId}');
              }
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch enrollment changes to update completion status
    final enrollmentAsync = ref.watch(enrollmentProvider);

    return Consumer(
      builder: (context, ref, child) {
        // Get current enrollment status
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (enrollmentAsync.hasValue && mounted) {
            final enrollments = enrollmentAsync.value!;
            final enrollment = enrollments.firstWhere(
                  (e) => e.courseId == widget.courseId,
              orElse: () => Enrollment.empty(widget.courseId, 10),
            );

            final newCompletedStatus = enrollment.lecturesProgress[widget.lectureNumber - 1];
            if (newCompletedStatus != _isCompleted) {
              setState(() {
                _isCompleted = newCompletedStatus;
              });
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('Lecture ${widget.lectureNumber}'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              if (_isInitialized)
                IconButton(
                  icon: Icon(
                    _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: _isCompleted ? null : _markAsCompleted,
                  tooltip: _isCompleted ? 'Completed' : 'Mark as completed',
                ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => context.pop(),
                tooltip: 'Lecture List',
              ),
            ],
          ),
          body: _isInitialized
              ? Column(
            children: [
              // Video Player
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Chewie(controller: _chewieController),
                ),
              ),

              // Lecture Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lecture title
                    Text(
                      'Lecture ${widget.lectureNumber}: Introduction to ${widget.courseId}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'This lecture covers fundamental concepts and practical applications to help you master ${widget.courseId}. We\'ll explore real-world examples and best practices.',
                      style: const TextStyle(
                        height: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Row
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _videoController.value.duration.inSeconds > 0
                                ? _videoController.value.position.inSeconds /
                                _videoController.value.duration.inSeconds
                                : 0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_formatDuration(_videoController.value.position)} / ${_formatDuration(_videoController.value.duration)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Completion Button (if not auto-completed)
                    if (!_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _markAsCompleted,
                          icon: const Icon(Icons.check),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                    // Next Lecture Button (if completed)
                    if (_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Refresh enrollment data before checking
                            await ref.refresh(enrollmentProvider);

                            final enrollments = await ref
                                .read(storageServiceProvider)
                                .getEnrollments();
                            final enrollment = enrollments.firstWhere(
                                  (e) => e.courseId == widget.courseId,
                              orElse: () =>
                                  Enrollment.empty(widget.courseId, 10),
                            );

                            if (widget.lectureNumber <
                                enrollment.totalLectures) {
                              context.go(
                                  '/courses/detail/${widget.courseId}/video/${widget.lectureNumber + 1}');
                            } else {
                              _showCourseCompletion();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            widget.lectureNumber < 5
                                ? 'Next Lecture →'
                                : 'Complete Course & Get Certificate',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          )
              : const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: _buildLectureNavigation(),
        );
      },
    );
  }

  Widget _buildLectureNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          if (widget.lectureNumber > 1)
            _buildNavButton(
              Icons.arrow_back,
              'Previous',
                  () {
                // ✅ FIXED: Use context.go() instead of Navigator.pushNamed
                context.go('/courses/detail/${widget.courseId}/video/${widget.lectureNumber - 1}');
              },
            ),

          // Spacer
          if (widget.lectureNumber > 1) const Spacer(),

          // Next button (if not last lecture)
          if (widget.lectureNumber < 5) // Demo: 5 lectures
            _buildNavButton(
              Icons.arrow_forward,
              'Next',
                  () {
                // ✅ FIXED: Use context.go() instead of Navigator.pushNamed
                context.go('/courses/detail/${widget.courseId}/video/${widget.lectureNumber + 1}');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCourseCompletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Course Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations on completing the course!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You\'ve mastered all concepts and are ready to apply your skills in real-world scenarios.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text(
                    'Certificate of Completion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shareable on LinkedIn & Resume',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // ✅ FIXED: Use context.go() instead of Navigator.pushReplacementNamed
              context.go('/dashboard');
            },
            child: const Text('View Dashboard'),
          ),
        ],
      ),
    );
  }
}