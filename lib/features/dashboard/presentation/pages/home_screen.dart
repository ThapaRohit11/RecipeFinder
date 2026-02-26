import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/recipe_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onFavoriteChanged;

  const HomeScreen({super.key, this.onFavoriteChanged});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<_RecipeItem> _recipes = [];
  final Set<String> _favoriteBusyIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAllRecipes();
  }

  Future<void> refreshRecipes() => _fetchAllRecipes();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final recipesResponse = await apiClient.get(
        ApiEndpoints.recipes,
        options: Options(
          extra: {'noRetry': true},
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final body = recipesResponse.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response from server');
      }

      final success = body['success'] == true;
      if (!success) {
        throw Exception((body['message'] ?? 'Failed to fetch recipes').toString());
      }

      final data = body['data'];
      if (data is! List) {
        throw Exception('Invalid recipe list format');
      }

      final favoriteIds = await _fetchFavoriteIds();

      final parsedRecipes = data
          .whereType<Map<String, dynamic>>()
          .map(_RecipeItem.fromJson)
          .map((recipe) => recipe.copyWith(isFavorited: favoriteIds.contains(recipe.id)))
          .toList();

      parsedRecipes.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;

        if (aTime == null && bTime == null) {
          return 0;
        }
        if (aTime == null) {
          return 1;
        }
        if (bTime == null) {
          return -1;
        }
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _recipes = parsedRecipes;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.response?.data is Map<String, dynamic>
                ? (e.response?.data['message']?.toString() ?? 'Failed to load recipes')
                : (e.message ?? 'Network error while loading recipes');
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

  Future<Set<String>> _fetchFavoriteIds() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.favorites,
        options: Options(
          extra: {'noRetry': true},
          connectTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return <String>{};
      }

      if (body['success'] != true || body['data'] is! List) {
        return <String>{};
      }

      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => (item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _toggleFavorite(_RecipeItem recipe) async {
    if (recipe.id.isEmpty || _favoriteBusyIds.contains(recipe.id)) {
      return;
    }

    setState(() {
      _favoriteBusyIds.add(recipe.id);
      _recipes = _recipes.map((item) {
        if (item.id == recipe.id) {
          return item.copyWith(isFavorited: !item.isFavorited);
        }
        return item;
      }).toList();
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      if (!recipe.isFavorited) {
        await apiClient.post(
          ApiEndpoints.favoriteByRecipeId(recipe.id),
          options: Options(extra: {'noRetry': true}),
        );
      } else {
        await apiClient.delete(
          ApiEndpoints.favoriteByRecipeId(recipe.id),
          options: Options(extra: {'noRetry': true}),
        );
      }

      widget.onFavoriteChanged?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipes = _recipes.map((item) {
          if (item.id == recipe.id) {
            return item.copyWith(isFavorited: recipe.isFavorited);
          }
          return item;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteBusyIds.remove(recipe.id);
        });
      }
    }
  }

  List<_RecipeItem> get _filteredRecipes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _recipes;
    }

    return _recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(query) ||
          recipe.description.toLowerCase().contains(query) ||
          recipe.authorName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSearchBar(),
              const SizedBox(height: 16),
              Text(
                'All Recipes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
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

    return Row(
      children: [
        Expanded(
          child: Container(
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
                hintText: 'Search recipes',
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
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: IconButton(
            onPressed: _isLoading ? null : _fetchAllRecipes,
            icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant),
            tooltip: 'Refresh',
          ),
        ),
      ],
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
              onPressed: _fetchAllRecipes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final visibleRecipes = _filteredRecipes;
    if (visibleRecipes.isEmpty) {
      return const Center(
        child: Text('No recipes found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllRecipes,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleRecipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final recipe = visibleRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(_RecipeItem recipe) {
    final data = RecipeCardData(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      imageUrl: recipe.imageUrl,
      authorImageUrl: recipe.authorImageUrl,
      authorName: recipe.authorName,
      createdAtLabel: recipe.createdAtLabel,
      isFavorited: recipe.isFavorited,
    );

    return RecipeCard(
      data: data,
      favoriteBusy: _favoriteBusyIds.contains(recipe.id),
      onFavoriteTap: () => _toggleFavorite(recipe),
      onReadMoreTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailsPage(data: data),
          ),
        );
      },
    );
  }
}

class _RecipeItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? authorImageUrl;
  final String authorName;
  final DateTime? createdAt;
  final bool isFavorited;

  _RecipeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.authorImageUrl,
    required this.authorName,
    required this.createdAt,
    required this.isFavorited,
  });

  factory _RecipeItem.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final createdRaw = json['createdAt']?.toString();
    if (createdRaw != null) {
      created = DateTime.tryParse(createdRaw);
    }

    return _RecipeItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      authorImageUrl: json['authorImageUrl']?.toString(),
      authorName: (json['authorName'] ?? 'Unknown').toString(),
      createdAt: created,
      isFavorited: false,
    );
  }

  _RecipeItem copyWith({bool? isFavorited}) {
    return _RecipeItem(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      authorImageUrl: authorImageUrl,
      authorName: authorName,
      createdAt: createdAt,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  String get createdAtLabel {
    if (createdAt == null) {
      return 'Unknown';
    }
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}
