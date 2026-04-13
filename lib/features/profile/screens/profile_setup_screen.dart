import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers.dart';
import '../../../core/themes/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../dashboard/screens/app_drawer.dart';
import '../models/user_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _interestsController = TextEditingController();
  List<String> selectedInterests = [];
  final List<String> interestOptions = [
    'Data Science', 'Web Development', 'Mobile Development', 'AI/ML',
    'Cloud Computing', 'Cybersecurity', 'UI/UX Design', 'DevOps',
    'Blockchain', 'Digital Marketing', 'Finance', 'Project Management'
  ];

  @override
  void initState() {
    super.initState();
    // Load existing profile data asynchronously
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _qualificationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  // ✅ CORRECTED: Async method to load profile
  Future<void> _loadExistingProfile() async {
    try {
      // 👇 AWAIT the Future to get actual UserProfile?
      final profile = await ref.read(storageServiceProvider).getProfile();

      if (profile != null) {
        // Update controllers on the main thread
        if (mounted) {
          setState(() {
            _nameController.text = profile.name;
            _emailController.text = profile.email;
            _qualificationController.text = profile.highestQualification;
            selectedInterests = List<String>.from(profile.interests);
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Handle error appropriately (optional)
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && selectedInterests.isNotEmpty) {
      final profile = UserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        highestQualification: _qualificationController.text.trim(),
        interests: selectedInterests,
      );

      await ref.read(userProfileProvider.notifier).saveProfile(profile);

      if (context.mounted) {
        // ✅ CORRECTED - Use GoRouter navigation instead of Flutter Navigator
        context.go('/dashboard');
      }
    } else {
      if (selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one interest')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: CustomAppBar(title: 'Complete Your Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildQualificationSection(),
              const SizedBox(height: 24),
              _buildInterestsSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Profile & Get Course Suggestions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQualificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Highest Qualification',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _qualificationController,
          decoration: InputDecoration(
            labelText: 'e.g., B.Tech Computer Science, MBA, etc.',
            prefixIcon: const Icon(Icons.school),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Qualification is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Interests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select areas you\'re passionate about learning',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interestOptions.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            return ChoiceChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) => _toggleInterest(interest),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[200],
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}