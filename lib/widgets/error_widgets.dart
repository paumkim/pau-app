import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.error.withAlpha(180)),
            ),
            const SizedBox(height: 20),
            Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingShimmer extends StatelessWidget {
  final int itemCount;
  final double height;

  const AppLoadingShimmer({
    super.key,
    this.itemCount = 3,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200;
    final highlight = isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100;

    return Column(
      children: List.generate(itemCount, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primary.withAlpha(120)),
            ),
            const SizedBox(height: 20),
            Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryLight, height: 1.5)),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
