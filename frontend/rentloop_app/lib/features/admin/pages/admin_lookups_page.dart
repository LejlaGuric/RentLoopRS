import 'package:flutter/material.dart';

import '../models/lookup_item.dart';
import '../services/admin_lookups_service.dart';

class AdminLookupsPage extends StatefulWidget {
  const AdminLookupsPage({super.key});

  @override
  State<AdminLookupsPage> createState() => _AdminLookupsPageState();
}

class _AdminLookupsPageState extends State<AdminLookupsPage>
    with SingleTickerProviderStateMixin {
  final _service = AdminLookupsService();

  late final TabController _tabController;

  bool _loading = true;
  String _error = '';

  List<LookupItem> _cities = [];
  List<LookupItem> _rentTypes = [];
  List<LookupItem> _amenities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final cities = await _service.getCities();
      final rentTypes = await _service.getRentTypes();
      final amenities = await _service.getAmenities();

      if (!mounted) return;
      setState(() {
        _cities = cities;
        _rentTypes = rentTypes;
        _amenities = amenities;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreateDialog({
    required String title,
    required Future<void> Function(String value) onSave,
  }) async {
    final controller = TextEditingController();
    String error = '';
    bool submitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> submit() async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                setLocal(() => error = 'Naziv je obavezan.');
                return;
              }

              setLocal(() {
                submitting = true;
                error = '';
              });

              try {
                await onSave(value);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setLocal(() {
                  error = e.toString().replaceFirst('Exception: ', '');
                  submitting = false;
                });
              }
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Naziv',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uspješno sačuvano.')),
      );
      await _load();
    }
  }

  Future<void> _openEditDialog({
    required String title,
    required LookupItem item,
    required Future<void> Function(String value) onSave,
  }) async {
    final controller = TextEditingController(text: item.name);
    String error = '';
    bool submitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> submit() async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                setLocal(() => error = 'Naziv je obavezan.');
                return;
              }

              setLocal(() {
                submitting = true;
                error = '';
              });

              try {
                await onSave(value);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setLocal(() {
                  error = e.toString().replaceFirst('Exception: ', '');
                  submitting = false;
                });
              }
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Naziv',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uspješno izmijenjeno.')),
      );
      await _load();
    }
  }

  Future<void> _confirmDelete({
    required String entityName,
    required String itemName,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Brisanje $entityName'),
        content: Text('Da li sigurno želiš obrisati "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await onDelete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uspješno obrisano.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildTable({
    required String title,
    required List<LookupItem> items,
    required VoidCallback onAdd,
    required Future<void> Function(LookupItem item) onEdit,
    required Future<void> Function(LookupItem item) onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Naziv')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: items.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item.id.toString())),
                            DataCell(Text(item.name)),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(70, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () => onEdit(item),
                                      child: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(70, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () => onDelete(item),
                                      child: const Text('Delete'),
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'Cities'),
              Tab(text: 'Rent Types'),
              Tab(text: 'Amenities'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTable(
                title: 'Gradovi',
                items: _cities,
                onAdd: () => _openCreateDialog(
                  title: 'Dodaj grad',
                  onSave: (value) => _service.createCity(value),
                ),
                onEdit: (item) => _openEditDialog(
                  title: 'Izmijeni grad',
                  item: item,
                  onSave: (value) => _service.updateCity(item.id, value),
                ),
                onDelete: (item) => _confirmDelete(
                  entityName: 'grada',
                  itemName: item.name,
                  onDelete: () => _service.deleteCity(item.id),
                ),
              ),
              _buildTable(
                title: 'Tipovi najma',
                items: _rentTypes,
                onAdd: () => _openCreateDialog(
                  title: 'Dodaj tip najma',
                  onSave: (value) => _service.createRentType(value),
                ),
                onEdit: (item) => _openEditDialog(
                  title: 'Izmijeni tip najma',
                  item: item,
                  onSave: (value) => _service.updateRentType(item.id, value),
                ),
                onDelete: (item) => _confirmDelete(
                  entityName: 'tipa najma',
                  itemName: item.name,
                  onDelete: () => _service.deleteRentType(item.id),
                ),
              ),
              _buildTable(
                title: 'Amenities',
                items: _amenities,
                onAdd: () => _openCreateDialog(
                  title: 'Dodaj amenity',
                  onSave: (value) => _service.createAmenity(value),
                ),
                onEdit: (item) => _openEditDialog(
                  title: 'Izmijeni amenity',
                  item: item,
                  onSave: (value) => _service.updateAmenity(item.id, value),
                ),
                onDelete: (item) => _confirmDelete(
                  entityName: 'amenity-ja',
                  itemName: item.name,
                  onDelete: () => _service.deleteAmenity(item.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}