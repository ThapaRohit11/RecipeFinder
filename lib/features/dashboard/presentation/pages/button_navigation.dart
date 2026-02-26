import 'package:flutter/material.dart';
import 'package:recipe_finder/features/dashboard/presentation/pages/add_screen.dart';
import 'package:recipe_finder/features/dashboard/presentation/pages/favourite_screen.dart';
import 'package:recipe_finder/features/dashboard/presentation/pages/home_screen.dart';
import 'package:recipe_finder/features/dashboard/presentation/pages/profile_screen.dart';


class ButtonNavigation extends StatefulWidget {
  const ButtonNavigation({super.key});

  @override
  State<ButtonNavigation> createState() => _ButtonNavigationState();
}

class _ButtonNavigationState extends State<ButtonNavigation> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<FavouriteScreenState> _favouriteKey = GlobalKey<FavouriteScreenState>();

  void _handleRecipeCreated() {
    setState(() {
      _currentIndex = 0;
    });
    _homeKey.currentState?.refreshRecipes();
  }

  void _handleFavoriteChanged() {
    _homeKey.currentState?.refreshRecipes();
    _favouriteKey.currentState?.refreshFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            key: _homeKey,
            onFavoriteChanged: _handleFavoriteChanged,
          ),
          AddScreen(onRecipeCreated: _handleRecipeCreated),
          FavouriteScreen(
            key: _favouriteKey,
            onFavoriteChanged: _handleFavoriteChanged,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favourite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}