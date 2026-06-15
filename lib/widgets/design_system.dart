import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Universal design system for Pau App.
/// Every screen should use these instead of raw padding/ListTile/Row.
/// Ensures consistency across all screens.

/// Bottom padding for scrollable screens (accounts for nav bar).
EdgeInsets screenPadding(BuildContext context) {
  return EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 80);
}

/// Section header with icon.
Widget sectionHeader(String title, IconData icon) {
  return Row(children: [
    Icon(icon, size: 16, color: AppTheme.primary),
    const SizedBox(width: 6),
    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
  ]);
}

/// Standard card with icon, title, subtitle, and chevron.
Widget navCard({
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Widget? trailing,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      leading: CircleAvatar(radius: 18, backgroundColor: color.withAlpha(25),
        child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    ),
  );
}

/// Standard screen header with back button and title.
Widget screenHeader(BuildContext context, String title, {String? subtitle, List<Widget>? actions}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight)),
        ]),
      ),
      if (actions != null) ...actions,
    ]),
  );
}

/// Standard search bar.
Widget searchBar(TextEditingController controller, ValueChanged<String> onChanged, {String hint = 'Search...'}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { controller.clear(); onChanged(''); })
          : null,
    ),
    onChanged: onChanged,
  );
}

/// Build method wrapper — wraps the body with safe area and keyboard dismiss.
/// Use this as the body of every Scaffold.
Widget screenBody(BuildContext context, Widget child) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: SafeArea(child: child),
  );
}
