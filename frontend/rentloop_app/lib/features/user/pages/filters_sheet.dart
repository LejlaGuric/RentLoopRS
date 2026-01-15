import 'package:flutter/material.dart';

import '../models/listing_filters.dart';
import '../models/lookup_item.dart';
import '../services/lookups_service.dart';

class FiltersSheet extends StatefulWidget {
  final ListingFilters initial;

  const FiltersSheet({super.key, required this.initial});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  // ❌ više ne trebaju city/rentType textfieldi
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _roomsCtrl;
  late final TextEditingController _guestsCtrl;

  // ✅ dropdown vrijednosti
  int? _cityId;
  int? _rentTypeId;

  String _sort = 'newest';

  // ✅ lookups
  final _lookups = LookupsService();
  bool _loadingLookups = true;
  String _lookupError = '';
  List<LookupItem> _cities = [];
  List<LookupItem> _rentTypes = [];

  @override
  void initState() {
    super.initState();

    _cityId = widget.initial.cityId;
    _rentTypeId = widget.initial.rentTypeId;

    _minCtrl = TextEditingController(text: widget.initial.minPrice?.toString() ?? '');
    _maxCtrl = TextEditingController(text: widget.initial.maxPrice?.toString() ?? '');
    _roomsCtrl = TextEditingController(text: widget.initial.rooms?.toString() ?? '');
    _guestsCtrl = TextEditingController(text: widget.initial.guests?.toString() ?? '');
    _sort = widget.initial.sort;

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = '';
    });

    try {
      final results = await Future.wait([
        _lookups.getCities(),
        _lookups.getRentTypes(),
      ]);

      if (!mounted) return;

      setState(() {
        _cities = results[0] as List<LookupItem>;
        _rentTypes = results[1] as List<LookupItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupError = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loadingLookups = false);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _roomsCtrl.dispose();
    _guestsCtrl.dispose();
    super.dispose();
  }

  int? _toInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  double? _toDouble(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _apply() {
    final f = widget.initial.copy();

    f.cityId = _cityId;
    f.rentTypeId = _rentTypeId;

    f.minPrice = _toDouble(_minCtrl.text);
    f.maxPrice = _toDouble(_maxCtrl.text);
    f.rooms = _toInt(_roomsCtrl.text);
    f.guests = _toInt(_guestsCtrl.text);
    f.sort = _sort;

    Navigator.of(context).pop(f);
  }

  void _clear() {
    Navigator.of(context).pop(ListingFilters());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filteri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),

            if (_loadingLookups) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (_lookupError.isNotEmpty) ...[
              Text(_lookupError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
            ],

            // ✅ Grad (dropdown)
            DropdownButtonFormField<int?>(
              value: _cityId,
              decoration: const InputDecoration(
                labelText: 'Grad',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Svi gradovi'),
                ),
                ..._cities.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: _loadingLookups ? null : (v) => setState(() => _cityId = v),
            ),
            const SizedBox(height: 10),

            // ✅ Tip rentanja (dropdown)
            DropdownButtonFormField<int?>(
              value: _rentTypeId,
              decoration: const InputDecoration(
                labelText: 'Tip izdavanja',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Svi tipovi'),
                ),
                ..._rentTypes.map(
                  (r) => DropdownMenuItem<int?>(
                    value: r.id,
                    child: Text(r.name),
                  ),
                ),
              ],
              onChanged: _loadingLookups ? null : (v) => setState(() => _rentTypeId = v),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Min cijena',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Max cijena',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sobe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _guestsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gosti',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Sort', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: _sort,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Najnovije')),
                DropdownMenuItem(value: 'priceasc', child: Text('Cijena ↑')),
                DropdownMenuItem(value: 'pricedesc', child: Text('Cijena ↓')),
                DropdownMenuItem(value: 'distanceasc', child: Text('Udaljenost ↑')),
              ],
              onChanged: (v) => setState(() => _sort = v ?? 'newest'),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Primijeni'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
