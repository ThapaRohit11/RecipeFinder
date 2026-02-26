import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'dart:typed_data';

class AddScreen extends ConsumerStatefulWidget {
  final VoidCallback? onRecipeCreated;

  const AddScreen({super.key, this.onRecipeCreated});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _submitRecipe() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipe image')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: _selectedImage!.name,
        ),
      });

      final response = await apiClient.uploadFile(
        ApiEndpoints.recipes,
        formData: formData,
        options: Options(
          extra: {'noRetry': true},
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected server response');
      }

      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Failed to create recipe').toString());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe posted successfully')),
      );

      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      widget.onRecipeCreated?.call();
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Failed to create recipe')
          : (e.message ?? 'Network error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Recipe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your recipe with the community',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  title: 'Recipe Image',
                  subtitle: 'Upload a clear photo of your dish',
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedImage == null
                              ? colorScheme.outlineVariant
                              : colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap to choose image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JPG, PNG • Good lighting works best',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: _selectedImageBytes == null
                                      ? const SizedBox.shrink()
                                      : Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: IconButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => setState(() {
                                                _selectedImage = null;
                                                _selectedImageBytes = null;
                                              }),
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      iconSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Recipe Details',
                  subtitle: 'Add a catchy title and short description',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          label: 'Title',
                          hint: 'e.g. Creamy Garlic Pasta',
                          icon: Icons.restaurant_menu,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isSubmitting,
                        maxLines: 6,
                        decoration: _fieldDecoration(
                          label: 'Description',
                          hint: 'Write ingredients, steps, or special tips...',
                          icon: Icons.notes_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSubmitting
                      ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isSubmitting ? 'Posting Recipe...' : 'Post Recipe',
                      style: const TextStyle(
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
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}