import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import '../models/admin_listing_list_item.dart';
import '../services/admin_listings_service.dart';
import 'admin_listing_details_page.dart';
import 'admin_listing_create_page.dart';

class AdminListingsPage extends StatefulWidget {
  const AdminListingsPage({super.key});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage> {
  final _service = AdminListingsService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String _error = '';

  List<AdminListingListItem> _all = [];
  List<AdminListingListItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _all = res;
        _filtered = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }

    setState(() {
      _filtered = _all.where((l) {
        final hay = [
          l.name,
          l.city,
          l.rentType,
          l.pricePerNight.toString(),
          l.roomsCount.toString(),
          l.maxGuests.toString(),
        ].join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminListingCreatePage()),
    );
    await _load();
  }

  void _openDetails(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminListingDetailsPage(listingId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // TOP BAR
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Pretraga (naziv, grad, tip najma...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj stan'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DataTable2(
                  // Ovo ti daje “normalan” razmak svuda
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  minWidth: 900,

                  headingRowHeight: 52,
                  dataRowHeight: 56,

                  columns: const [
                    DataColumn2(label: Text('ID'), size: ColumnSize.S),
                    DataColumn2(label: Text('Naziv'), size: ColumnSize.L),
                    DataColumn2(label: Text('Grad'), size: ColumnSize.M),
                    DataColumn2(label: Text('Tip'), size: ColumnSize.M),
                    DataColumn2(label: Text('Cijena/noć'), size: ColumnSize.S),
                    DataColumn2(label: Text('Sobe'), size: ColumnSize.S),
                    DataColumn2(label: Text('Gosti'), size: ColumnSize.S),
                    DataColumn2(label: Text('Ocjena'), size: ColumnSize.S),
                    DataColumn2(label: Text('Akcije'), size: ColumnSize.S),
                  ],
                  rows: _filtered.map((l) {
                    return DataRow(
                      cells: [
                        DataCell(Text(l.id.toString())),
                        DataCell(
                          Text(
                            l.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(Text(l.city)),
                        DataCell(Text(l.rentType)),
                        DataCell(Text(l.pricePerNight.toStringAsFixed(2))),
                        DataCell(Text(l.roomsCount.toString())),
                        DataCell(Text(l.maxGuests.toString())),
                        DataCell(Text('${l.avgRating.toStringAsFixed(2)} (${l.reviewsCount})')),
                        DataCell(
                          OutlinedButton(
                            onPressed: () => _openDetails(l.id),
                            child: const Text('Detalji'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
