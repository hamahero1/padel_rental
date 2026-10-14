import 'package:flutter/material.dart';

import '../../models/rental.dart';
import '../../services/db_service.dart';
import '../../utils.dart';
import '../../widgets/rental_card.dart';

/// Rentals that are still out. The owner marks them returned,
/// which puts the quantities back and records the return date.
class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  Future<void> _markReturned(Rental r) async {
    try {
      await DbService.markReturned(r);
      showMsg('Marked as returned');
    } catch (e) {
      showMsg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active rentals')),
      body: StreamBuilder<List<Rental>>(
        stream: DbService.activeRentalsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rentals = snapshot.data!;
          if (rentals.isEmpty) {
            return const Center(child: Text('No equipment is rented right now'));
          }
          return ListView(
            children: [
              for (final r in rentals)
                RentalCard(
                  rental: r,
                  showUser: true,
                  action: FilledButton.tonalIcon(
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Mark returned'),
                    onPressed: () => _markReturned(r),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
