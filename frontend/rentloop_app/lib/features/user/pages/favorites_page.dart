import 'package:flutter/material.dart';

import '../models/listing_card.dart';
import '../services/favorites_service.dart';
import '../widgets/listing_card_widget.dart';
import 'listing_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _svc = FavoritesService();

  bool _loading = true;
  String _error = '';
  List<ListingCard> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final items = await _svc.myFavorites();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetails(ListingCard it) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListingDetailsPage(listingId: it.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Favoriti'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_loading) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 60),
            ] else if (_error.isNotEmpty) ...[
              Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ] else if (_items.isEmpty) ...[
              const SizedBox(height: 40),
              Text(
                'Nemaš nijedan oglas u favoritima.',
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w700),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: blue.withOpacity(0.22)),
                ),
                child: Text(
                  'Ukupno: ${_items.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              ..._items.map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListingCardWidget(
                    item: it,
                    onTap: () => _openDetails(it),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
