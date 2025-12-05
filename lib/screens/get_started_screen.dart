import 'package:flutter/material.dart';
import 'package:recipe_finder/screens/login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the local logo for thumbnails; metrics are responsive using screen size
    final logo = 'assets/images/logo.png';
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width * 0.86;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Center(
          child: Container(
            width: cardWidth,
            // aspect ratio similar to mobile mock
            constraints: BoxConstraints(minHeight: 520, maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                // top area with circular thumbnails positioned freely
                SizedBox(
                  height: 360,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // center large circle
                      Positioned(
                        left: (cardWidth / 2) - 70,
                        top: 40,
                        child: _Thumb(radius: 70, asset: logo),
                      ),
                      Positioned(left: 30, top: 18, child: _Thumb(radius: 28, asset: logo)),
                      Positioned(left: cardWidth - 30 - 56, top: 18, child: _Thumb(radius: 28, asset: logo)),
                      Positioned(left: 50, top: 140, child: _Thumb(radius: 20, asset: logo)),
                      Positioned(left: cardWidth - 80, top: 130, child: _Thumb(radius: 24, asset: logo)),
                      Positioned(left: cardWidth / 2 - 18, top: 220, child: _Thumb(radius: 18, asset: logo)),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                Text('Start Cooking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Text(
                    "Let's join our community to cook better food!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19C76E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16)),
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
}

// small helper widget for circular thumbnail with subtle shadow
class _Thumb extends StatelessWidget {
  final double radius;
  final String asset;
  const _Thumb({required this.radius, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: radius - 6,
          backgroundImage: AssetImage(asset),
          backgroundColor: Colors.grey[50],
        ),
      ),
    );
  }
}
