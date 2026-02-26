import 'package:flutter/material.dart';
import 'package:recipe_finder/core/api/api_endpoints.dart';

class RecipeCardData {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? authorImageUrl;
  final String authorName;
  final String createdAtLabel;
  final bool isFavorited;

  const RecipeCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.authorImageUrl,
    required this.authorName,
    required this.createdAtLabel,
    required this.isFavorited,
  });

  String get authorInitial {
    final value = authorName.trim();
    if (value.isEmpty) {
      return 'U';
    }
    return value.characters.first.toUpperCase();
  }
}

class RecipeCard extends StatelessWidget {
  final RecipeCardData data;
  final VoidCallback onFavoriteTap;
  final VoidCallback onReadMoreTap;
  final bool favoriteBusy;

  const RecipeCard({
    super.key,
    required this.data,
    required this.onFavoriteTap,
    required this.onReadMoreTap,
    this.favoriteBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final authorAvatar = resolveApiImageUrl(data.authorImageUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? const Color(0xFF214231) : Colors.green.shade50,
                backgroundImage: authorAvatar == null ? null : NetworkImage(authorAvatar),
                child: authorAvatar == null
                    ? Text(
                        data.authorInitial,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted ${data.createdAtLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: favoriteBusy ? null : onFavoriteTap,
                  icon: Icon(
                    data.isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: data.isFavorited ? Colors.red : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RecipeImage(imageUrl: data.imageUrl),
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReadMoreTap,
              icon: const Icon(Icons.menu_book, size: 18, color: Colors.green),
              label: const Text(
                'Read more',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeImage extends StatelessWidget {
  final String? imageUrl;

  const RecipeImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveApiImageUrl(imageUrl);

    if (resolvedUrl == null) {
      return Image.asset(
        'assets/images/salad.jpg',
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      resolvedUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/salad.jpg',
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }

}

class RecipeDetailsPage extends StatelessWidget {
  final RecipeCardData data;

  const RecipeDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    data.authorInitial,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(data.authorName),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RecipeImage(imageUrl: data.imageUrl),
            ),
            const SizedBox(height: 12),
            Text(
              data.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? resolveApiImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  return '${ApiEndpoints.baseUrl}$url';
}
