import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/lookup_item.dart';
import '../services/admin_listings_service.dart';
import '../services/lookups_service.dart';

class AdminListingCreatePage extends StatefulWidget {
  const AdminListingCreatePage({super.key});

  @override
  State<AdminListingCreatePage> createState() => _AdminListingCreatePageState();
}

class _AdminListingCreatePageState extends State<AdminListingCreatePage> {
  final _listings = AdminListingsService();
  final _lookups = LookupsService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _priceCtrl = TextEditingController(text: '50');
  final _roomsCtrl = TextEditingController(text: '1');
  final _guestsCtrl = TextEditingController(text: '2');
  final _distanceCtrl = TextEditingController(text: '0.5');

  List<PlatformFile> _images = [];
  int _coverIndex = 0;

  bool _loading = false;
  String _error = '';

  bool _lookupsLoading = true;
  List<LookupItem> _cities = [];
  List<LookupItem> _rentTypes = [];
  List<LookupItem> _amenities = [];

  int? _cityId;
  int? _rentTypeId;

  final Set<int> _selectedAmenityIds = {};

  final ScrollController _gridCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _lookupsLoading = true;
      _error = '';
    });

    try {
      final cities = await _lookups.getCities();
      final rentTypes = await _lookups.getRentTypes();
      final amenities = await _lookups.getAmenities();

      if (!mounted) return;

      setState(() {
        _cities = cities;
        _rentTypes = rentTypes;
        _amenities = amenities;

        _cityId = cities.isNotEmpty ? cities.first.id : null;
        _rentTypeId = rentTypes.isNotEmpty ? rentTypes.first.id : null;

        _lookupsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _lookupsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _roomsCtrl.dispose();
    _guestsCtrl.dispose();
    _distanceCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (res == null) return;

    final picked = res.files.where((f) => f.path != null).toList();

    setState(() {
      _images.addAll(picked);

      final seen = <String>{};
      _images = _images.where((x) => seen.add(x.path!)).toList();

      if (_coverIndex >= _images.length) _coverIndex = 0;
    });
  }

  void _removeImage(int i) {
    setState(() {
      _images.removeAt(i);
      if (_images.isEmpty) _coverIndex = 0;
      if (_coverIndex >= _images.length) _coverIndex = 0;
    });
  }

  // ✅ skrola čak i ako controller još “nema client” (sačeka frame)
  void _scrollGridBy(double delta) {
    void go() {
      if (!_gridCtrl.hasClients) return;
      final current = _gridCtrl.offset;
      final max = _gridCtrl.position.maxScrollExtent;
      final next = (current + delta).clamp(0.0, max);
      _gridCtrl.animateTo(
        next,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }

    if (_gridCtrl.hasClients) {
      go();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (_lookupsLoading) throw Exception('Sačekaj da se učitaju gradovi i tipovi najma.');
      if (_cityId == null) throw Exception('Nema dostupnih gradova.');
      if (_rentTypeId == null) throw Exception('Nema dostupnih tipova najma.');

      final name = _nameCtrl.text.trim();
      if (name.isEmpty) throw Exception('Naziv je obavezan.');
      if (_images.isEmpty) throw Exception('Dodaj bar jednu sliku.');

      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
      if (price <= 0) throw Exception('Cijena/noć mora biti > 0.');

      final rooms = int.tryParse(_roomsCtrl.text) ?? 0;
      if (rooms <= 0) throw Exception('Broj soba mora biti > 0.');

      final guests = int.tryParse(_guestsCtrl.text) ?? 0;
      if (guests <= 0) throw Exception('Broj gostiju mora biti > 0.');

      final distance = double.tryParse(_distanceCtrl.text.replaceAll(',', '.')) ?? 0;

      final amenityIdsJson = jsonEncode(_selectedAmenityIds.toList());

      await _listings.createListingMultipart(
        name: name,
        description: _descCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        cityId: _cityId!,
        rentTypeId: _rentTypeId!,
        pricePerNight: price,
        roomsCount: rooms,
        maxGuests: guests,
        distanceToCenterKm: distance,
        hasWifi: false,
        hasAirConditioning: false,
        petsAllowed: false,
        amenityIds: amenityIdsJson,
        coverIndex: _coverIndex,
        imagePaths: _images.map((e) => e.path!).toList(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj stan'),
        actions: [
          if (_lookupsLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          IconButton(
            tooltip: 'Reload lookups',
            onPressed: _lookupsLoading ? null : _loadLookups,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // LEFT
            Expanded(
              flex: 3,
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ListView(
                    children: [
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                          ),
                        ),
                      const Text('Osnovno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _field(_nameCtrl, 'Naziv'),
                      const SizedBox(height: 12),
                      _field(_addressCtrl, 'Adresa'),
                      const SizedBox(height: 12),
                      _field(_descCtrl, 'Opis', maxLines: 4),
                      const SizedBox(height: 18),
                      const Text('Lokacija i tip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownLookup(
                              label: 'Grad',
                              value: _cityId,
                              items: _cities,
                              onChanged: _lookupsLoading ? null : (v) => setState(() => _cityId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdownLookup(
                              label: 'Tip najma',
                              value: _rentTypeId,
                              items: _rentTypes,
                              onChanged: _lookupsLoading ? null : (v) => setState(() => _rentTypeId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Cijena i kapacitet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_priceCtrl, 'Cijena/noć', keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_roomsCtrl, 'Sobe', keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_guestsCtrl, 'Gosti', keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_distanceCtrl, 'Udaljenost (km)', keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      if (_amenities.isEmpty)
                        const Text('Nema amenities (ili nisu učitani).')
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _amenities.map((a) {
                            final selected = _selectedAmenityIds.contains(a.id);
                            return FilterChip(
                              label: Text(a.name),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedAmenityIds.add(a.id);
                                  } else {
                                    _selectedAmenityIds.remove(a.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 18),
                      const Text('Slike', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _pickImages,
                            icon: const Icon(Icons.image),
                            label: const Text('Dodaj slike'),
                          ),
                          const SizedBox(width: 12),
                          Text('Odabrano: ${_images.length}'),
                          const Spacer(),
                          if (_images.isNotEmpty)
                            Text('Cover: ${_coverIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: Text(_loading ? 'Spremam...' : 'Spremi stan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // RIGHT
            Expanded(
              flex: 4,
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _images.isEmpty
                      ? const Center(
                          child: Text(
                            'Nema odabranih slika.\nKlikni "Dodaj slike" i izaberi više (Ctrl/Shift).',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Gore',
                                  onPressed: () => _scrollGridBy(-320),
                                  icon: const Icon(Icons.keyboard_arrow_up),
                                ),
                                IconButton(
                                  tooltip: 'Dole',
                                  onPressed: () => _scrollGridBy(320),
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                ),
                                const SizedBox(width: 8),
                                Text('Slike: ${_images.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text('Cover: ${_coverIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Scrollbar(
                                controller: _gridCtrl,
                                thumbVisibility: true,
                                child: GridView.builder(
                                  controller: _gridCtrl,
                                  itemCount: _images.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemBuilder: (_, i) {
                                    final img = _images[i];
                                    final isCover = i == _coverIndex;

                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.file(
                                            File(img.path!),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: InkWell(
                                            onTap: () => setState(() => _coverIndex = i),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isCover ? 'COVER ✅' : 'COVER',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: InkWell(
                                            onTap: () => _removeImage(i),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.85),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _dropdownLookup({
    required String label,
    required int? value,
    required List<LookupItem> items,
    required void Function(int)? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: items.map((x) => DropdownMenuItem<int>(value: x.id, child: Text(x.name))).toList(),
          onChanged: (v) => (v == null || onChanged == null) ? null : onChanged(v),
        ),
      ),
    );
  }
}
