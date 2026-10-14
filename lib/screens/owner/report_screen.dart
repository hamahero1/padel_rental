import 'package:flutter/material.dart';

import '../../models/rental.dart';
import '../../services/db_service.dart';
import '../../utils.dart';
import '../../widgets/rental_card.dart';

/// Transaction report: all rentals and returns on the chosen date.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _date = DateTime.now();
  late Future<(List<Rental>, List<Rental>)> _report = DbService.report(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _report = DbService.report(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction report')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(formatDate(_date),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to choose another date'),
            onTap: _pickDate,
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<(List<Rental>, List<Rental>)>(
              future: _report,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final (rented, returned) = snapshot.data!;
                final income = rented.fold<double>(0, (s, r) => s + r.total);
                return ListView(
                  children: [
                    // Summary numbers
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _Stat(label: 'Rentals', value: '${rented.length}'),
                          _Stat(label: 'Returns', value: '${returned.length}'),
                          _Stat(label: 'Rental income', value: money(income)),
                        ],
                      ),
                    ),
                    _Header('Rented on this day (${rented.length})'),
                    if (rented.isEmpty) const _Empty(),
                    for (final r in rented) RentalCard(rental: r, showUser: true),
                    _Header('Returned on this day (${returned.length})'),
                    if (returned.isEmpty) const _Empty(),
                    for (final r in returned)
                      RentalCard(rental: r, showUser: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Nothing', style: TextStyle(color: Colors.grey)),
      );
}
