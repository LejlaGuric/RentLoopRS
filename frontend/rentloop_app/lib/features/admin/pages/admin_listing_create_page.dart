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
  final _formKey = GlobalKey<FormState>();

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

  bool _hasWifi = false;
  bool _hasAirConditioning = false;
  bool _petsAllowed = false;

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
      _error = '';
    });
  }

  void _removeImage(int i) {
    setState(() {
      _images.removeAt(i);
      if (_images.isEmpty) _coverIndex = 0;
      if (_coverIndex >= _images.length) _coverIndex = 0;
    });
  }

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

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Naziv je obavezan';
    if (v.length > 100) return 'Naziv može imati najviše 100 karaktera';
    return null;
  }

  String? _validateDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 1000) return 'Opis može imati najviše 1000 karaktera';
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Adresa je obavezna';
    if (v.length > 200) return 'Adresa može imati najviše 200 karaktera';
    return null;
  }

  String? _validatePrice(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Cijena/noć je obavezna';

    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return 'Unesi ispravnu cijenu';
    if (parsed <= 0) return 'Cijena/noć mora biti veća od 0';

    return null;
  }

  String? _validateRooms(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Broj soba je obavezan';

    final parsed = int.tryParse(raw);
    if (parsed == null) return 'Unesi cijeli broj';
    if (parsed <= 0) return 'Broj soba mora biti veći od 0';

    return null;
  }

  String? _validateGuests(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Broj gostiju je obavezan';

    final parsed = int.tryParse(raw);
    if (parsed == null) return 'Unesi cijeli broj';
    if (parsed <= 0) return 'Broj gostiju mora biti veći od 0';

    return null;
  }

  String? _validateDistance(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;

    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return 'Unesi ispravnu udaljenost';
    if (parsed < 0) return 'Udaljenost ne može biti negativna';

    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _error = '';
    });

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _loading = true;
    });

    try {
      if (_lookupsLoading) {
        throw Exception('Sačekaj da se učitaju gradovi i tipovi najma.');
      }
      if (_cityId == null) throw Exception('Nema dostupnih gradova.');
      if (_rentTypeId == null) throw Exception('Nema dostupnih tipova najma.');
      if (_images.isEmpty) throw Exception('Dodaj bar jednu sliku.');

      final name = _nameCtrl.text.trim();
      final price = double.parse(_priceCtrl.text.trim().replaceAll(',', '.'));
      final rooms = int.parse(_roomsCtrl.text.trim());
      final guests = int.parse(_guestsCtrl.text.trim());
      final distance = _distanceCtrl.text.trim().isEmpty
          ? 0.0
          : double.parse(_distanceCtrl.text.trim().replaceAll(',', '.'));

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
        hasWifi: _hasWifi,
        hasAirConditioning: _hasAirConditioning,
        petsAllowed: _petsAllowed,
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
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
            Expanded(
              flex: 3,
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: ListView(
                      children: [
                        if (_error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const Text(
                          'Osnovno',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _nameCtrl,
                          'Naziv',
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _addressCtrl,
                          'Adresa',
                          validator: _validateAddress,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _descCtrl,
                          'Opis',
                          maxLines: 4,
                          validator: _validateDescription,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Lokacija i tip',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdownLookup(
                                label: 'Grad',
                                value: _cityId,
                                items: _cities,
                                onChanged: _lookupsLoading
                                    ? null
                                    : (v) => setState(() => _cityId = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdownLookup(
                                label: 'Tip najma',
                                value: _rentTypeId,
                                items: _rentTypes,
                                onChanged: _lookupsLoading
                                    ? null
                                    : (v) => setState(() => _rentTypeId = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Cijena i kapacitet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _priceCtrl,
                                'Cijena/noć',
                                keyboard: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validatePrice,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _roomsCtrl,
                                'Sobe',
                                keyboard: TextInputType.number,
                                validator: _validateRooms,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _guestsCtrl,
                                'Gosti',
                                keyboard: TextInputType.number,
                                validator: _validateGuests,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _distanceCtrl,
                                'Udaljenost (km)',
                                keyboard: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateDistance,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Osnovne pogodnosti',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _hasWifi,
                          onChanged: (v) => setState(() => _hasWifi = v ?? false),
                          title: const Text('WiFi'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: _hasAirConditioning,
                          onChanged: (v) => setState(() => _hasAirConditioning = v ?? false),
                          title: const Text('Klima'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: _petsAllowed,
                          onChanged: (v) => setState(() => _petsAllowed = v ?? false),
                          title: const Text('Ljubimci dozvoljeni'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Amenities',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
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
                        const Text(
                          'Slike',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
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
                              Text(
                                'Cover: ${_coverIndex + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
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
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Card(
                elevation: 1.2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                                Text(
                                  'Slike: ${_images.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  'Cover: ${_coverIndex + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isCover ? 'COVER ✅' : 'COVER',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
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
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
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

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
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
          items: items
              .map((x) => DropdownMenuItem<int>(value: x.id, child: Text(x.name)))
              .toList(),
          onChanged: (v) => (v == null || onChanged == null) ? null : onChanged(v),
        ),
      ),
    );
  }
}