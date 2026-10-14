import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/cart.dart';
import '../../services/db_service.dart';
import '../../utils.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'my_rentals_screen.dart';
import 'products_screen.dart';

/// Player's home: shows the categories as a grid.
class PlayerHomeScreen extends StatelessWidget {
  final AppUser user;
  const PlayerHomeScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    cart.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _openProducts(BuildContext context, EquipmentCategory? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductsScreen(user: user, category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(' ').first}'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => _openProducts(context, null),
          ),
          CartButton(user: user),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rentals') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MyRentalsScreen(user: user)));
              } else {
                _logout(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rentals', child: Text('My rentals')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<EquipmentCategory>>(
        stream: DbService.categoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          // First tile is "All equipment", then one tile per category
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryTile(
                  name: 'All equipment',
                  icon: Icons.apps,
                  onTap: () => _openProducts(context, null),
                );
              }
              final c = categories[index - 1];
              return _CategoryTile(
                name: c.name,
                icon: categoryIcon(c.name),
                onTap: () => _openProducts(context, c),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.name, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// Cart icon with a small badge showing how many items are in the cart.
class CartButton extends StatelessWidget {
  final AppUser user;
  const CartButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => IconButton(
        tooltip: 'Cart',
        icon: Badge(
          isLabelVisible: cart.count > 0,
          label: Text('${cart.count}'),
          child: const Icon(Icons.shopping_cart),
        ),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CartScreen(user: user))),
      ),
    );
  }
}
