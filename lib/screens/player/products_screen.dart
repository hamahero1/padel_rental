import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../models/app_user.dart';
import '../../models/category.dart';
import '../../models/equipment.dart';
import '../../services/db_service.dart';
import '../../services/search.dart';
import '../../utils.dart';
import '../scanner_screen.dart';
import 'player_home_screen.dart';
import 'product_details_screen.dart';

/// List of equipment (all, or one category) with search by
/// text, voice and barcode.
class ProductsScreen extends StatefulWidget {
  final AppUser user;
  final EquipmentCategory? category; // null = all equipment
  const ProductsScreen({super.key, required this.user, this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  final _speech = SpeechToText();
  String _query = '';
  bool _listening = false;
  // Created once; typing in the search box only filters, it doesn't re-read
  late final Stream<List<Equipment>> _equipmentStream =
      DbService.equipmentStream(categoryId: widget.category?.id);
  // Last list from Firestore, used to pick the best voice result
  List<Equipment> _allItems = [];

  // ---- Search by voice ----
  Future<void> _voiceSearch() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    // Asks for microphone permission the first time
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (error) => showMsg('Voice error: ${error.errorMsg}'),
    );
    if (!available) {
      showMsg('Voice search is not available on this device');
      return;
    }
    setState(() {
      _listening = true;
      _searchController.clear();
      _query = '';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'en_US', // product names are in English
        partialResults: true, // show the words while the user speaks
        listenMode: ListenMode.search,
        cancelOnError: true,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) {
        var words = result.recognizedWords;
        // The recognizer gives a few guesses. At the end, use the first
        // guess that actually finds equipment.
        if (result.finalResult) {
          for (final guess in result.alternates) {
            if (searchEquipment(_allItems, guess.recognizedWords).isNotEmpty) {
              words = guess.recognizedWords;
              break;
            }
          }
        }
        setState(() {
          _searchController.text = words;
          _query = words;
        });
      },
    );
  }

  // ---- Search by barcode ----
  Future<void> _barcodeSearch() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (code == null) return;
    final equipment = await DbService.findByBarcode(code);
    if (!mounted) return;
    if (equipment == null) {
      showMsg('No equipment with barcode $code');
      return;
    }
    _openDetails(equipment);
  }

  void _openDetails(Equipment e) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(user: widget.user, equipment: e)));
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'All equipment'),
        actions: [CartButton(user: widget.user)],
      ),
      body: Column(
        children: [
          // Search row: text field + mic button + barcode button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _listening
                          ? 'Listening... say a product'
                          : 'Search by name',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Search by voice',
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? Colors.red : null),
                  onPressed: _voiceSearch,
                ),
                IconButton.filledTonal(
                  tooltip: 'Search by barcode',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _barcodeSearch,
                ),
              ],
            ),
          ),
          // Moving bar while the microphone is listening
          if (_listening) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: _equipmentStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                _allItems = snapshot.data!;
                // Same search for typed and spoken words (see search.dart)
                final items = searchEquipment(_allItems, _query);
                if (items.isEmpty) {
                  return const Center(child: Text('No equipment found'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Icon(categoryIcon(e.categoryName))),
                        title: Text(e.name),
                        subtitle: Text(
                            '${money(e.price)} / day  •  ${e.quantity} available'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetails(e),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
