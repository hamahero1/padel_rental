import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/equipment.dart';
import '../../services/cart.dart';
import '../../utils.dart';
import '../../widgets/equipment_qr.dart';
import 'player_home_screen.dart';

/// Shows one piece of equipment and lets the player add it to the cart.
class ProductDetailsScreen extends StatefulWidget {
  final AppUser user;
  final Equipment equipment;
  const ProductDetailsScreen(
      {super.key, required this.user, required this.equipment});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  void _addToCart() {
    cart.add(widget.equipment, _quantity);
    showMsg('Added $_quantity x ${widget.equipment.name} to cart');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.equipment;
    final outOfStock = e.quantity == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(e.name),
        actions: [CartButton(user: widget.user)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(categoryIcon(e.categoryName),
              size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(e.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(e.categoryName, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (e.description.isNotEmpty) Text(e.description),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments),
            title: Text('${money(e.price)} per day'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2),
            title: Text(outOfStock ? 'Out of stock' : '${e.quantity} available'),
          ),
          if (e.barcode.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Scan this QR code to find this equipment',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Center(child: EquipmentQr(equipment: e)),
          ],
          const SizedBox(height: 16),
          if (!outOfStock) ...[
            // Quantity selector: - 1 +
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('$_quantity',
                      style: const TextStyle(fontSize: 22)),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: _quantity < e.quantity
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add to cart  (${money(e.price * _quantity)} / day)'),
              onPressed: _addToCart,
            ),
          ],
        ],
      ),
    );
  }
}
