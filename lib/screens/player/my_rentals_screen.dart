import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/rental.dart';
import '../../services/db_service.dart';
import '../../widgets/rental_card.dart';

/// The player's rental history.
class MyRentalsScreen extends StatelessWidget {
  final AppUser user;
  const MyRentalsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My rentals')),
      body: StreamBuilder<List<Rental>>(
        stream: DbService.myRentalsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rentals = snapshot.data!;
          if (rentals.isEmpty) {
            return const Center(child: Text('You have no rentals yet'));
          }
          return ListView(
            children: [for (final r in rentals) RentalCard(rental: r)],
          );
        },
      ),
    );
  }
}
