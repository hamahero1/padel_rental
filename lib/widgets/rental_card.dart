import 'package:flutter/material.dart';

import '../models/rental.dart';
import '../utils.dart';

/// Shows one rental: who, what, when, total and status.
/// Used by "My rentals", the owner's rentals screen and the report.
/// [action] is an optional button (e.g. "Mark returned").
class RentalCard extends StatelessWidget {
  final Rental rental;
  final bool showUser;
  final Widget? action;
  const RentalCard(
      {super.key, required this.rental, this.showUser = false, this.action});

  @override
  Widget build(BuildContext context) {
    final returned = rental.isReturned;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showUser ? rental.userName : formatDateTime(rental.rentDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: Text(returned ? 'Returned' : 'Rented'),
                  backgroundColor:
                      returned ? Colors.green.shade100 : Colors.orange.shade100,
                ),
              ],
            ),
            for (final item in rental.items)
              Text('• ${item.quantity} x ${item.name}  (${money(item.price)} / day)'),
            const SizedBox(height: 6),
            if (showUser) Text('Rented: ${formatDateTime(rental.rentDate)}'),
            if (returned) Text('Returned: ${formatDateTime(rental.returnDate)}'),
            Text('${rental.days} day(s)  •  Total ${money(rental.total)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (action != null)
              Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }
}
