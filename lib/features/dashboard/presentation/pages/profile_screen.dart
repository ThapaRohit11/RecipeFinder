import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/core/services/biometric/biometric_auth_service.dart';
import 'package:recipe_finder/core/services/storage/user_session_service.dart';
import 'package:recipe_finder/app/theme/theme_mode_provider.dart';
import 'package:recipe_finder/features/auth/presentation/pages/login_screen.dart';
import 'package:recipe_finder/features/dashboard/presentation/pages/my_recipes_screen.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'package:dio/dio.dart';

final profilePictureProvider = StateNotifierProvider<ProfilePictureNotifier, _ProfilePictureState>((ref) {
  return ProfilePictureNotifier();
});

class _ProfilePictureState {
  final String? userId;
  final File? file;

  const _ProfilePictureState({this.userId, this.file});
}

class ProfilePictureNotifier extends StateNotifier<_ProfilePictureState> {
  ProfilePictureNotifier() : super(const _ProfilePictureState());

  void setProfilePictureForUser({required String userId, required File picture}) {
    state = _ProfilePictureState(userId: userId, file: picture);
  }

  void clear() {
    state = const _ProfilePictureState();
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  bool _isProfileUpdating = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await ref.read(userSessionServiceProvider).isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _isBiometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (_isBiometricLoading) return;

    setState(() => _isBiometricLoading = true);
    try {
      final biometricService = ref.read(biometricAuthServiceProvider);
      final sessionService = ref.read(userSessionServiceProvider);

      if (enabled) {
        final available = await biometricService.isBiometricAvailable();
        if (!available) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric sensor is not available on this device.')),
          );
          return;
        }

        final verified = await biometricService.authenticate(
          reason: 'Authenticate to enable fingerprint login',
        );

        if (!verified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fingerprint verification failed.')),
          );
          return;
        }
      }

      await sessionService.setBiometricEnabled(enabled);
      if (!mounted) return;
      setState(() {
        _isBiometricEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Biometric login enabled' : 'Biometric login disabled'),
          backgroundColor: enabled ? Colors.green : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();

      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        openAppSettings();
        return;
      }

      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;

      final userId = ref.read(userSessionServiceProvider).getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update picture. Please login again.')),
        );
        return;
      }

      final File imageFile = File(pickedFile.path);
      ref
          .read(profilePictureProvider.notifier)
          .setProfilePictureForUser(userId: userId, picture: imageFile);

      // Upload to backend
      await _uploadProfilePicture(imageFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final session = ref.read(userSessionServiceProvider);
      final userId = session.getCurrentUserId();

      if (userId == null || userId.isEmpty) {
        throw Exception('Unable to update picture. Please login again.');
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_picture.jpg',
        ),
      });

      final response = await apiClient.put(
        ApiEndpoints.customerProfileById(userId),
        data: formData,
        options: Options(extra: {'noRetry': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected server response');
      }

      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Failed to update picture').toString());
      }

      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final imagePath = (data['image'] ?? data['profilePicture'] ?? '').toString();

      await session.saveUserSession(
        userId: userId,
        email: session.getCurrentUserEmail() ?? '',
        fullName: session.getCurrentUserFullName() ?? '',
        username: session.getCurrentUsername() ?? '',
        profilePicture: imagePath,
      );

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload picture: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ref.read(userSessionServiceProvider).clearSession();
    ref.read(profilePictureProvider.notifier).clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openEditProfileSheet() async {
    final session = ref.read(userSessionServiceProvider);
    final currentName = session.getCurrentUserFullName() ?? '';
    final currentEmail = session.getCurrentUserEmail() ?? '';

    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();

    final payload = await showModalBottomSheet<_EditProfilePayload>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Email cannot be empty';
                    }
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                        _EditProfilePayload(
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (payload == null || !mounted) return;
    await _updateProfile(payload);
  }

  Future<void> _updateProfile(_EditProfilePayload payload) async {
    final session = ref.read(userSessionServiceProvider);
    final userId = session.getCurrentUserId();

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update profile. Please login again.')),
      );
      return;
    }

    setState(() => _isProfileUpdating = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final (firstName, lastName) = _splitName(payload.fullName);

      final response = await apiClient.put(
        '${ApiEndpoints.customers}/$userId',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': payload.email,
        },
        options: Options(extra: {'noRetry': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected server response');
      }

      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Profile update failed').toString());
      }

      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final responseFirst = (data['firstName'] ?? firstName).toString();
      final responseLast = (data['lastName'] ?? lastName).toString();
      final responseFullName = [responseFirst, responseLast]
          .where((part) => part.trim().isNotEmpty)
          .join(' ')
          .trim();
      final updatedFullName = responseFullName.isEmpty ? payload.fullName : responseFullName;
      final updatedEmail = (data['email'] ?? payload.email).toString();
      final updatedUsername = (data['username'] ?? updatedEmail.split('@').first).toString();
      final updatedImage = (data['image'] ?? session.getCurrentUserProfilePicture() ?? '').toString();

      await session.saveUserSession(
        userId: userId,
        email: updatedEmail,
        fullName: updatedFullName,
        username: updatedUsername,
        profilePicture: updatedImage,
      );

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serverMessage ?? e.message ?? 'Profile update failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isProfileUpdating = false);
      }
    }
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return ('', '');
    }
    if (parts.length == 1) {
      return (parts.first, '');
    }
    return (parts.first, parts.sublist(1).join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);
    final userId = session.getCurrentUserId() ?? '';
    final profilePictureState = ref.watch(profilePictureProvider);
    final profilePicture = profilePictureState.userId == userId ? profilePictureState.file : null;
    final userName = session.getCurrentUserFullName() ?? 'Recipe Lover';
    final userEmail = session.getCurrentUserEmail() ?? 'your@email.com';
    final profilePictureUrl = session.getCurrentUserProfilePicture();
    final avatarImage = profilePicture != null
        ? FileImage(profilePicture) as ImageProvider
        : _networkProfileImage(profilePictureUrl);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isShakeSensorEnabled = ref.watch(shakeThemeSensorProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickImageFromCamera,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 54,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap profile picture to update',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _profileActionCard(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your name, email and personal info',
                onTap: _openEditProfileSheet,
                isLoading: _isProfileUpdating,
              ),
              const SizedBox(height: 12),
              _profileActionCard(
                icon: Icons.menu_book_outlined,
                title: 'My Recipes',
                subtitle: 'View and manage recipes posted by you',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRecipesScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _themeModeCard(
                isDarkMode: isDarkMode,
                onDarkModeChanged: (value) {
                  ref.read(themeModeProvider.notifier).setDarkMode(value);
                },
              ),
              const SizedBox(height: 12),
              _themeSensorCard(
                enabled: isShakeSensorEnabled,
                onChanged: (value) {
                  ref.read(shakeThemeSensorProvider.notifier).setEnabled(value);
                },
              ),
              const SizedBox(height: 12),
              _biometricCard(
                enabled: _isBiometricEnabled,
                isLoading: _isBiometricLoading,
                onChanged: _toggleBiometric,
              ),
              const SizedBox(height: 12),
              _profileActionCard(
                icon: Icons.settings_outlined,
                title: 'App Settings',
                subtitle: 'Control your preferences and app behavior',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeModeCard({
    required bool isDarkMode,
    required ValueChanged<bool> onDarkModeChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dark mode',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDarkMode,
                      onChanged: onDarkModeChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _biometricCard({
    required bool enabled,
    required bool isLoading,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fingerprint, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? 'Fingerprint login is enabled'
                      : 'Enable fingerprint login for next sign in',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: enabled,
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }

  Widget _themeSensorCard({
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sensors, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Shake Sensor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? 'Shake phone to switch light/dark mode'
                      : 'Shake sensor is disabled',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  ImageProvider? _networkProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final trimmedPath = imagePath.trim();
    final resolvedUrl = trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')
        ? trimmedPath
        : '${ApiEndpoints.baseUrl}$trimmedPath';
    return NetworkImage(resolvedUrl);
  }

  Widget _profileActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfilePayload {
  final String fullName;
  final String email;

  const _EditProfilePayload({
    required this.fullName,
    required this.email,
  });
}


