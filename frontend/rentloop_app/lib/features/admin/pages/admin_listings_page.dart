import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import '../models/admin_listing_list_item.dart';
import '../reports/listings_pdf_report.dart';
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
  final _pdfReport = ListingsPdfReport();
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

  Future<void> _generatePdf() async {
    try {
      await _pdfReport.generate(_filtered);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Greška pri generisanju PDF-a: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _openDetails(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminListingDetailsPage(listingId: id)),
    );
  }

  Future<void> _deactivateListing(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deaktivacija listinga'),
        content: const Text(
          'Da li ste sigurni da želite deaktivirati ovaj listing? '
          'Listing neće biti trajno obrisan, nego samo sakriven iz aktivne ponude.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktiviraj'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deactivateListing(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing je uspješno deaktiviran.'),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
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
            ElevatedButton(
              onPressed: _load,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Pretraga (naziv, grad, tip najma...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              Tooltip(
                message:
                    'PDF izvještaj je prilagođen za horizontalni (landscape) prikaz.',
                child: OutlinedButton.icon(
                  onPressed: _filtered.isEmpty ? null : _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF stanovi'),
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DataTable2(
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  minWidth: 1050,
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
                    DataColumn2(label: Text('Akcije'), fixedWidth: 260),
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
                        DataCell(
                          Text(
                            '${l.avgRating.toStringAsFixed(2)} (${l.reviewsCount})',
                          ),
                        ),
                       DataCell(
  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        OutlinedButton(
          onPressed: () => _openDetails(l.id),
          child: const Text('Detalji'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _deactivateListing(l.id),
          child: const Text('Deaktiviraj'),
        ),
      ],
    ),
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