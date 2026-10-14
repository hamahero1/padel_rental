import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/cart.dart';
import '../../services/db_service.dart';
import '../../utils.dart';

/// Rental cart: edit quantities, choose number of days,
/// see the total, then submit the rental.
class CartScreen extends StatefulWidget {
  final AppUser user;
  const CartScreen({super.key, required this.user});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await DbService.submitRental(widget.user, cart);
      final total = cart.total;
      cart.clear();
      showMsg('Rental submitted. Total ${money(total)}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMsg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental cart')),
      // Rebuilds every time the cart changes
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final item in cart.items)
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(item.equipment.name),
                          subtitle: Text(
                              '${money(item.equipment.price)} / day  x ${item.quantity}  =  ${money(item.subtotal)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                // Going below 1 removes the item
                                onPressed: () =>
                                    cart.setQuantity(item, item.quantity - 1),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: item.quantity <
                                        item.equipment.quantity
                                    ? () => cart.setQuantity(
                                        item, item.quantity + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _Summary(submitting: _submitting, onSubmit: _submit),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom part: number of days, cost per day and total.
class _Summary extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSubmit;
  const _Summary({required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Rental days'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: cart.days > 1
                      ? () => cart.setDays(cart.days - 1)
                      : null,
                ),
                Text('${cart.days}', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => cart.setDays(cart.days + 1),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Cost per day'),
                const Spacer(),
                Text(money(cart.perDay)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text('Total (${cart.days} day${cart.days > 1 ? 's' : ''})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(money(cart.total),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: Text(submitting ? 'Submitting...' : 'Submit rental'),
            ),
          ],
        ),
      ),
    );
  }
}
