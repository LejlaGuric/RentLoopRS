import 'package:flutter/material.dart';

import '../models/listing_card.dart';
import '../models/listing_filters.dart';
import '../models/lookup_item.dart';
import '../services/listings_service.dart';
import '../services/lookups_service.dart';
import '../widgets/listing_card_widget.dart';
import '../widgets/recommended_card_widget.dart';
import 'filters_sheet.dart';
import 'listing_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _svc = ListingsService();
  final _lookups = LookupsService();
  final ListingFilters _filters = ListingFilters();

  bool _loading = true;
  String _error = '';

  List<ListingCard> _recommended = [];
  List<ListingCard> _items = [];

  // ✅ lookups cache (za prikaz naziva u chips)
  List<LookupItem> _cities = [];
  List<LookupItem> _rentTypes = [];

  // ✅ NOVO: search state
  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';

  // ✅ controller za recommended slider + dimenzije
  final ScrollController _recCtrl = ScrollController();
  static const double _recItemWidth = 320; // ✅ bolje za mobitel (da ne reže)
  static const double _recGap = 12;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _load();
  }

  Future<void> _loadLookups() async {
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
    } catch (_) {
      // ako lookups failaju, samo ćemo fallbackovati na brojeve
    }
  }

  @override
  void dispose() {
    _recCtrl.dispose();
    _searchCtrl.dispose(); // ✅ NOVO
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        _svc.getRecommended(take: 10),
        _svc.getAll(
          cityId: _filters.cityId,
          rentTypeId: _filters.rentTypeId,
          minPrice: _filters.minPrice,
          maxPrice: _filters.maxPrice,
          rooms: _filters.rooms,
          guests: _filters.guests,
          sort: _filters.sort,
          q: _q, // ✅ NOVO: search po nazivu
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _recommended = results[0] as List<ListingCard>;
        _items = results[1] as List<ListingCard>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFilters() async {
    final res = await showModalBottomSheet<ListingFilters?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: _filters),
    );

    if (res == null) return;

    setState(() {
      _filters.cityId = res.cityId;
      _filters.rentTypeId = res.rentTypeId;
      _filters.minPrice = res.minPrice;
      _filters.maxPrice = res.maxPrice;
      _filters.rooms = res.rooms;
      _filters.guests = res.guests;
      _filters.sort = res.sort;
    });

    await _load();
  }

  String _cityName(int id) {
    for (final c in _cities) {
      if (c.id == id) return c.name;
    }
    return 'City $id';
  }

  String _rentTypeName(int id) {
    for (final r in _rentTypes) {
      if (r.id == id) return r.name;
    }
    return 'RentType $id';
  }

  String _chipsText() {
    final parts = <String>[];

    if (_filters.cityId != null) parts.add(_cityName(_filters.cityId!));
    if (_filters.rentTypeId != null) parts.add(_rentTypeName(_filters.rentTypeId!));

    if (_filters.minPrice != null) parts.add('Min ${_filters.minPrice!.toStringAsFixed(0)}');
    if (_filters.maxPrice != null) parts.add('Max ${_filters.maxPrice!.toStringAsFixed(0)}');
    if (_filters.rooms != null) parts.add('${_filters.rooms} soba');
    if (_filters.guests != null) parts.add('${_filters.guests} gost');

    parts.add('Sort ${_filters.sort}');
    return parts.isEmpty ? 'Bez filtera' : parts.join(' • ');
  }

  void _openDetails(ListingCard it) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailsPage(listingId: it.id),
      ),
    );
  }

  void _recLeft() {
    if (!_recCtrl.hasClients) return;
    final next = (_recCtrl.offset - (_recItemWidth + _recGap)).clamp(
      0.0,
      _recCtrl.position.maxScrollExtent,
    );
    _recCtrl.animateTo(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _recRight() {
    if (!_recCtrl.hasClients) return;
    final next = (_recCtrl.offset + (_recItemWidth + _recGap)).clamp(
      0.0,
      _recCtrl.position.maxScrollExtent,
    );
    _recCtrl.animateTo(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Widget _recArrow({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {}, // ostavljeno da ne mijenjamo strukturu
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // malo manje zbog TextFielda
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.black.withOpacity(0.55)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Pretraga po nazivu...',
                              hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (val) async {
                              final term = val.trim();
                              if (term == _q) return;
                              setState(() => _q = term);
                              await _load();
                            },
                          ),
                        ),
                        if (_q.isNotEmpty)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.close, size: 20, color: Colors.black.withOpacity(0.55)),
                            onPressed: () async {
                              _searchCtrl.clear();
                              setState(() => _q = '');
                              await _load();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _openFilters,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: blue.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.tune, color: blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Text(
              _chipsText(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(height: 12),

          if (_loading) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 40),
          ] else if (_error.isNotEmpty) ...[
            Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ] else ...[
            if (_recommended.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Preporučeno za tebe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Row(
                    children: [
                      _recArrow(icon: Icons.chevron_left, onTap: _recLeft),
                      const SizedBox(width: 8),
                      _recArrow(icon: Icons.chevron_right, onTap: _recRight),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 290,
                child: ListView.separated(
                  controller: _recCtrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommended.length,
                  separatorBuilder: (_, __) => const SizedBox(width: _recGap),
                  itemBuilder: (_, i) {
                    final it = _recommended[i];
                    return SizedBox(
                      width: _recItemWidth,
                      child: RecommendedCardWidget(
                        item: it,
                        onTap: () => _openDetails(it),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
            ],

            const Text('Oglasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),

            if (_items.isEmpty)
              Text(
                'Nema oglasa za izabrane filtere.',
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              )
            else
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
    );
  }
}
