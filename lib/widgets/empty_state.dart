import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark 
                  ? colorScheme.surface 
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: isDark
                  ? null
                  : Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
            ),
            child: Icon(
              icon,
              size: 50,
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}