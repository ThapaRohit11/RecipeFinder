import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_finder/core/api/api_client.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'package:recipe_finder/features/dashboard/presentation/widgets/recipe_card.dart';

class FavouriteScreen extends ConsumerStatefulWidget {
  final VoidCallback? onFavoriteChanged;

  const FavouriteScreen({super.key, this.onFavoriteChanged});

  @override
  ConsumerState<FavouriteScreen> createState() => FavouriteScreenState();
}

class FavouriteScreenState extends ConsumerState<FavouriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<_FavoriteItem> _items = [];
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    refreshFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FavoriteItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.authorName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> refreshFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.favorites,
        options: Options(extra: {'noRetry': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Invalid response');
      }

      if (body['success'] != true || body['data'] is! List) {
        throw Exception((body['message'] ?? 'Failed to load favorites').toString());
      }

      final recipes = (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_FavoriteItem.fromJson)
          .toList();

      recipes.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (!mounted) return;
      setState(() {
        _items = recipes;
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

  Future<void> _toggleFavorite(_FavoriteItem item) async {
    if (_busyIds.contains(item.id)) return;

    setState(() {
      _busyIds.add(item.id);
      _items = _items.where((element) => element.id != item.id).toList();
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(
        ApiEndpoints.favoriteByRecipeId(item.id),
        options: Options(extra: {'noRetry': true}),
      );
      widget.onFavoriteChanged?.call();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [..._items, item]
          ..sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update favorite')),
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSearchBar(),
              const SizedBox(height: 16),
              Text(
                'Favorite Recipes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
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
                                  onPressed: refreshFavorites,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _filteredItems.isEmpty
                            ? const Center(child: Text('No favorite recipes found'))
                            : RefreshIndicator(
                                onRefresh: refreshFavorites,
                                child: ListView.separated(
                                  itemCount: _filteredItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    return _buildCard(item);
                                  },
                                ),
                              ),
              ),
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
          hintText: 'Search favorite recipes',
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

  Widget _buildCard(_FavoriteItem item) {
    final data = item.toCardData();

    return RecipeCard(
      data: data,
      favoriteBusy: _busyIds.contains(item.id),
      onFavoriteTap: () => _toggleFavorite(item),
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

class _FavoriteItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? authorImageUrl;
  final String authorName;
  final DateTime? createdAt;

  _FavoriteItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.authorImageUrl,
    required this.authorName,
    required this.createdAt,
  });

  factory _FavoriteItem.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt']?.toString();
    return _FavoriteItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      authorImageUrl: json['authorImageUrl']?.toString(),
      authorName: (json['authorName'] ?? 'Unknown').toString(),
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }

  String get createdAtLabel {
    if (createdAt == null) {
      return 'unknown';
    }
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  RecipeCardData toCardData() {
    return RecipeCardData(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      authorImageUrl: authorImageUrl,
      authorName: authorName,
      createdAtLabel: createdAtLabel,
      isFavorited: true,
    );
  }
}
