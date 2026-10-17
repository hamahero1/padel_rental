import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'categories_screen.dart';
import 'equipment_list_screen.dart';
import 'qr_codes_screen.dart';
import 'rentals_screen.dart';
import 'report_screen.dart';

/// Facility owner's home: one button for each owner feature.
class OwnerHomeScreen extends StatelessWidget {
  final AppUser user;
  const OwnerHomeScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Equipment', 'Add, edit, delete, price & quantity', Icons.sports_tennis,
          const EquipmentListScreen()),
      ('Categories', 'Create categories', Icons.category,
          const CategoriesScreen()),
      ('Active rentals', 'Mark equipment as returned', Icons.assignment_return,
          const RentalsScreen()),
      ('Transaction report', 'Rentals & returns on a date', Icons.bar_chart,
          const ReportScreen()),
      ('QR codes', 'Show or print the equipment QR codes', Icons.qr_code_2,
          const QrCodesScreen()),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner: ${user.name.split(' ').first}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final (title, subtitle, icon, screen) in items)
            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(icon,
                    size: 36, color: Theme.of(context).colorScheme.primary),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, screen),
              ),
            ),
        ],
      ),
    );
  }
}
