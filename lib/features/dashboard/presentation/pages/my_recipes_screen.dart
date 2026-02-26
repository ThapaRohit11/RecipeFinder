import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/recipe_card.dart';

class MyRecipesScreen extends ConsumerStatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  ConsumerState<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends ConsumerState<MyRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  String? _errorMessage;
  List<_MyRecipeItem> _recipes = [];
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _fetchMyRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MyRecipeItem> get _filteredRecipes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _recipes;
    }

    return _recipes.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _fetchMyRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.myRecipes,
        options: Options(extra: {'noRetry': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response from server');
      }

      if (body['success'] != true || body['data'] is! List) {
        throw Exception((body['message'] ?? 'Failed to fetch my recipes').toString());
      }

      final parsed = (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_MyRecipeItem.fromJson)
          .toList();

      parsed.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (!mounted) return;
      setState(() {
        _recipes = parsed;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data is Map<String, dynamic>
            ? (e.response?.data['message']?.toString() ?? 'Network error')
            : (e.message ?? 'Network error');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecipe(_MyRecipeItem item) async {
    if (_busyIds.contains(item.id)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _busyIds.add(item.id);
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(
        ApiEndpoints.recipeById(item.id),
        options: Options(extra: {'noRetry': true}),
      );

      if (!mounted) return;
      setState(() {
        _recipes = _recipes.where((element) => element.id != item.id).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serverMessage ?? e.message ?? 'Delete failed')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _editRecipe(_MyRecipeItem item) async {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);
    XFile? selectedImage;

    final updated = await showModalBottomSheet<_EditRecipePayload>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Recipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked == null) return;
                      if (!context.mounted) return;
                      setModalState(() {
                        selectedImage = picked;
                      });
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: Text(selectedImage == null ? 'Update image' : 'Image selected'),
                  ),
                  if (selectedImage != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(selectedImage!.path),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Text('Selected image'),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();

                        if (title.isEmpty || description.isEmpty) {
                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          _EditRecipePayload(
                            title: title,
                            description: description,
                            imageFile: selectedImage,
                          ),
                        );
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (updated == null) return;
    if (!mounted) return;

    setState(() {
      _busyIds.add(item.id);
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      Response response;
      if (updated.imageFile != null) {
        final data = <String, dynamic>{
          'title': updated.title,
          'description': updated.description,
          'image': await MultipartFile.fromFile(
            updated.imageFile!.path,
            filename: updated.imageFile!.name,
          ),
        };

        response = await apiClient.patch(
          ApiEndpoints.recipeById(item.id),
          data: FormData.fromMap(data),
          options: Options(
            extra: {'noRetry': true},
            contentType: 'multipart/form-data',
          ),
        );
      } else {
        response = await apiClient.patch(
          ApiEndpoints.recipeById(item.id),
          data: {
            'title': updated.title,
            'description': updated.description,
          },
          options: Options(extra: {'noRetry': true}),
        );
      }

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response from server');
      }

      if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
        throw Exception((body['message'] ?? 'Update failed').toString());
      }

      final updatedItem = _MyRecipeItem.fromJson(body['data'] as Map<String, dynamic>);

      if (!mounted) return;
      setState(() {
        _recipes = _recipes.map((recipe) {
          if (recipe.id == item.id) {
            return updatedItem;
          }
          return recipe;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe updated successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serverMessage ?? e.message ?? 'Update failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Recipes'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTopSearchBar(),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search my recipes',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchMyRecipes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = _filteredRecipes;
    if (items.isEmpty) {
      return const Center(
        child: Text('No recipes posted yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyRecipes,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMyRecipeCard(item);
        },
      ),
    );
  }

  Widget _buildMyRecipeCard(_MyRecipeItem item) {
    final data = RecipeCardData(
      id: item.id,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl,
      authorName: item.authorName,
      createdAtLabel: item.createdAtLabel,
      isFavorited: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecipeCard(
          data: data,
          favoriteBusy: true,
          onFavoriteTap: () {},
          onReadMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailsPage(data: data),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busyIds.contains(item.id) ? null : () => _editRecipe(item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busyIds.contains(item.id) ? null : () => _deleteRecipe(item),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyRecipeItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String authorName;
  final DateTime? createdAt;

  _MyRecipeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.authorName,
    required this.createdAt,
  });

  factory _MyRecipeItem.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt']?.toString();
    return _MyRecipeItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      authorName: (json['authorName'] ?? 'You').toString(),
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }

  String get createdAtLabel {
    if (createdAt == null) {
      return 'unknown';
    }
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}

class _EditRecipePayload {
  final String title;
  final String description;
  final XFile? imageFile;

  const _EditRecipePayload({required this.title, required this.description, this.imageFile});
}
