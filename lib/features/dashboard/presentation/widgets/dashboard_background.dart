import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  final Widget child;

  const DashboardBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0D1510),
                  Color(0xFF111D16),
                  Color(0xFF0F1712),
                ]
              : const [
                  Color(0xFFF3FFF5),
                  Color(0xFFEAF7EE),
                  Color(0xFFF7FBF8),
                ],
        ),
      ),
      child: child,
    );
  }
}
