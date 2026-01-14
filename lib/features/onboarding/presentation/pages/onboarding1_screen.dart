import 'package:flutter/material.dart';
import 'package:recipe_finder/features/onboarding/presentation/pages/onboarding2_screen.dart';


class Onboarding1Screen extends StatelessWidget {
  const Onboarding1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Onboarding.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.28)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Image.asset('assets/images/logo.png', width: 120, height: 120),
                  const SizedBox(height: 30),
                  Text('Start Cooking', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Let's join our community to cook better food!", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),

          Positioned(
            right: 24,
            bottom: 80,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Onboarding2Screen()),
                );
              },
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
