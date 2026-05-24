import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../models/admin_listing_details.dart';
import '../models/admin_listing_review.dart';
import '../services/admin_listings_service.dart';

class AdminListingDetailsPage extends StatefulWidget {
  final int listingId;
  const AdminListingDetailsPage({super.key, required this.listingId});

  @override
  State<AdminListingDetailsPage> createState() => _AdminListingDetailsPageState();
}

class _AdminListingDetailsPageState extends State<AdminListingDetailsPage> {
  final _service = AdminListingsService();

  bool _loading = true;
  String _error = '';
  AdminListingDetails? _data;

  List<AdminListingReview> _reviews = [];
  bool _reviewsLoading = false;
  String _reviewsError = '';

  int _selectedImageIndex = 0;

  final ScrollController _thumbCtrl = ScrollController();

  static const double _thumbWidth = 124;
  static const double _thumbGap = 12;
  static const double _thumbItemExtent = _thumbWidth + _thumbGap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _thumbCtrl.dispose();
    super.dispose();
  }

  String _fullUrl(String relative) {
    if (relative.startsWith('http')) return relative;
    if (relative.startsWith('/')) return '${ApiConfig.baseUrl}$relative';
    return '${ApiConfig.baseUrl}/$relative';
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _reviews = [];
      _reviewsError = '';
      _reviewsLoading = true;
    });

    try {
      final d = await _service.getById(widget.listingId);
      final reviews = await _service.getReviewsForListing(widget.listingId);

      if (!mounted) return;

      int idx = 0;
      if (d.images.isNotEmpty) {
        final coverIdx = d.images.indexWhere((x) => x.isCover);
        idx = coverIdx >= 0 ? coverIdx : 0;
      }

      setState(() {
        _data = d;
        _reviews = reviews;
        _selectedImageIndex = idx;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureThumbVisible(_selectedImageIndex);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _openEditDialog() async {
    final d = _data;
    if (d == null) return;

    final nameCtrl = TextEditingController(text: d.name);
    final descriptionCtrl = TextEditingController(text: d.description);
    final addressCtrl = TextEditingController(text: d.address);
    final priceCtrl = TextEditingController(text: d.pricePerNight.toString());
    final roomsCtrl = TextEditingController(text: d.roomsCount.toString());
    final guestsCtrl = TextEditingController(text: d.maxGuests.toString());
    final distanceCtrl = TextEditingController(text: d.distanceToCenterKm.toString());

    bool hasWifi = d.hasWifi;
    bool hasAirConditioning = d.hasAirConditioning;
    bool petsAllowed = d.petsAllowed;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final name = nameCtrl.text.trim();
              final description = descriptionCtrl.text.trim();
              final address = addressCtrl.text.trim();

              final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
              final rooms = int.tryParse(roomsCtrl.text.trim()) ?? 0;
              final guests = int.tryParse(guestsCtrl.text.trim()) ?? 0;
              final distance = double.tryParse(distanceCtrl.text.trim().replaceAll(',', '.')) ?? 0;

              if (name.isEmpty ||
                  description.isEmpty ||
                  address.isEmpty ||
                  price <= 0 ||
                  rooms <= 0 ||
                  guests <= 0 ||
                  distance < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Provjeri unesene podatke. Sva obavezna polja moraju biti validna.'),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                await _service.updateListing(
                  id: d.id,
                  name: name,
                  description: description,
                  address: address,
                  cityId: d.cityId,
                  rentTypeId: d.rentTypeId,
                  pricePerNight: price,
                  roomsCount: rooms,
                  maxGuests: guests,
                  distanceToCenterKm: distance,
                  hasWifi: hasWifi,
                  hasAirConditioning: hasAirConditioning,
                  petsAllowed: petsAllowed,
                );

                if (!mounted) return;

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing je uspješno izmijenjen.')),
                );

                await _load();
              } catch (e) {
                if (!mounted) return;

                setDialogState(() => saving = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Uredi listing'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Naziv'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Opis'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(labelText: 'Adresa'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Cijena/noć'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: distanceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Udaljenost do centra'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: roomsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Broj soba'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: guestsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Max gosti'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        value: hasWifi,
                        onChanged: saving ? null : (v) => setDialogState(() => hasWifi = v ?? false),
                        title: const Text('WiFi'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: hasAirConditioning,
                        onChanged: saving ? null : (v) => setDialogState(() => hasAirConditioning = v ?? false),
                        title: const Text('Klima'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: petsAllowed,
                        onChanged: saving ? null : (v) => setDialogState(() => petsAllowed = v ?? false),
                        title: const Text('Ljubimci dozvoljeni'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grad i tip najma ostaju isti: ${d.city} • ${d.rentType}.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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

    nameCtrl.dispose();
    descriptionCtrl.dispose();
    addressCtrl.dispose();
    priceCtrl.dispose();
    roomsCtrl.dispose();
    guestsCtrl.dispose();
    distanceCtrl.dispose();
  }

  void _selectImage(int i) {
    setState(() => _selectedImageIndex = i);
    _ensureThumbVisible(i);
  }

  void _ensureThumbVisible(int index) {
    if (!_thumbCtrl.hasClients) return;

    final target = (index * _thumbItemExtent) - (_thumbCtrl.position.viewportDimension / 2) + (_thumbWidth / 2);

    final clamped = target.clamp(
      _thumbCtrl.position.minScrollExtent,
      _thumbCtrl.position.maxScrollExtent,
    );

    _thumbCtrl.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _scrollThumbsBy(int dir) {
    if (!_thumbCtrl.hasClients) return;

    final current = _thumbCtrl.offset;
    final delta = _thumbItemExtent * 2;
    final target = current + (dir * delta);

    final clamped = target.clamp(
      _thumbCtrl.position.minScrollExtent,
      _thumbCtrl.position.maxScrollExtent,
    );

    _thumbCtrl.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  bool get _canScrollLeft {
    if (!_thumbCtrl.hasClients) return false;
    return _thumbCtrl.offset > (_thumbCtrl.position.minScrollExtent + 2);
  }

  bool get _canScrollRight {
    if (!_thumbCtrl.hasClients) return false;
    return _thumbCtrl.offset < (_thumbCtrl.position.maxScrollExtent - 2);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalji stana')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final images = d.images;

    final badgeText = d.isActive ? 'Aktivan' : 'Neaktivan';

    final all = d.allAmenities;
    final selected = d.selectedAmenities;

    final selectedSet = selected.map((e) => e.toLowerCase().trim()).toSet();
    final hasList = all.where((x) => selectedSet.contains(x.toLowerCase().trim())).toList();
    final noList = all.where((x) => !selectedSet.contains(x.toLowerCase().trim())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Stan #${d.id}'),
        actions: [
          TextButton.icon(
            onPressed: _openEditDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Uredi'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    d.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: d.isActive ? Colors.green.withOpacity(0.14) : Colors.red.withOpacity(0.14),
                    border: Border.all(color: d.isActive ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: d.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${d.city} • ${d.rentType}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 1.6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Galerija', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 14),
                            Expanded(
                              child: images.isEmpty
                                  ? const Center(child: Text('Nema slika'))
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            _fullUrl(images[_selectedImageIndex].url),
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            child: _pill(
                                              text: '${_selectedImageIndex + 1}/${images.length}',
                                            ),
                                          ),
                                          if (images[_selectedImageIndex].isCover)
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: _pill(text: 'COVER'),
                                            ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 14),
                            if (images.isNotEmpty)
                              SizedBox(
                                height: 96,
                                child: Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _thumbCtrl,
                                      builder: (_, __) {
                                        final enabled = _canScrollLeft;
                                        return _arrowBtn(
                                          icon: Icons.chevron_left_rounded,
                                          enabled: enabled,
                                          onTap: () => _scrollThumbsBy(-1),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: ListView.separated(
                                          controller: _thumbCtrl,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: images.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
                                          itemBuilder: (_, i) {
                                            final img = images[i];
                                            final selectedThumb = i == _selectedImageIndex;

                                            return InkWell(
                                              onTap: () => _selectImage(i),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: Container(
                                                  width: _thumbWidth,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      width: selectedThumb ? 2 : 1,
                                                      color: selectedThumb ? Colors.blue : Colors.grey.withOpacity(0.35),
                                                    ),
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.network(_fullUrl(img.url), fit: BoxFit.cover),
                                                      if (img.isCover)
                                                        Positioned(
                                                          top: 8,
                                                          left: 8,
                                                          child: _pill(text: 'C'),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedBuilder(
                                      animation: _thumbCtrl,
                                      builder: (_, __) {
                                        final enabled = _canScrollRight;
                                        return _arrowBtn(
                                          icon: Icons.chevron_right_rounded,
                                          enabled: enabled,
                                          onTap: () => _scrollThumbsBy(1),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 1.6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: ListView(
                          children: [
                            const Text('Informacije', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 14),
                            _sectionTitle('Osnovni podaci'),
                            const SizedBox(height: 10),
                            _kv('Cijena/noć', '${d.pricePerNight.toStringAsFixed(2)} KM'),
                            _kv('Sobe', d.roomsCount.toString()),
                            _kv('Max gosti', d.maxGuests.toString()),
                            _kv('Udaljenost do centra', '${d.distanceToCenterKm.toStringAsFixed(2)} km'),
                            const SizedBox(height: 18),
                            _sectionTitle('Osnovne pogodnosti'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _boolTag('WiFi', d.hasWifi),
                                _boolTag('Klima', d.hasAirConditioning),
                                _boolTag('Ljubimci dozvoljeni', d.petsAllowed),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle('Amenities'),
                            const SizedBox(height: 10),
                            if (all.isEmpty)
                              Text(
                                'Nema dostupnih amenities (backend još ne šalje listu).',
                                style: TextStyle(color: Colors.grey.shade700),
                              )
                            else ...[
                              _amenitiesBlock(title: '✅ Ima', items: hasList),
                              const SizedBox(height: 12),
                              _amenitiesBlock(title: '❌ Nema', items: noList),
                            ],
                            const SizedBox(height: 18),
                            _sectionTitle('Adresa'),
                            const SizedBox(height: 8),
                            _textBox(d.address.isEmpty ? '-' : d.address),
                            const SizedBox(height: 18),
                            _sectionTitle('Opis'),
                            const SizedBox(height: 8),
                            _textBox(d.description.isEmpty ? '-' : d.description),
                            const SizedBox(height: 18),
                            _sectionTitle('Recenzije korisnika'),
                            const SizedBox(height: 10),
                            if (_reviewsLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_reviewsError.isNotEmpty)
                              Text(
                                _reviewsError,
                                style: const TextStyle(color: Colors.red),
                              )
                            else if (_reviews.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.withOpacity(0.22)),
                                ),
                                child: const Text('Nema recenzija za ovaj stan.'),
                              )
                            else
                              Column(
                                children: _reviews
                                    .map(
                                      (r) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _reviewCard(r),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrowBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: enabled ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 30,
            color: enabled ? Colors.black87 : Colors.black26,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900));
  }

  Widget _textBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.22)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35)),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 210,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _amenitiesBlock({required String title, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.22)),
        color: Colors.grey.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text('-', style: TextStyle(color: Colors.grey.shade700))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((x) => _tag(x)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.blue.withOpacity(0.10),
        border: Border.all(color: Colors.blue.withOpacity(0.35)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _boolTag(String text, bool value) {
    final bgColor = value ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.10);
    final borderColor = value ? Colors.green.withOpacity(0.40) : Colors.red.withOpacity(0.35);
    final textColor = value ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '${value ? "✅" : "❌"} $text',
        style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
      ),
    );
  }

  Widget _reviewCard(AdminListingReview review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.user,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.amber.withOpacity(0.16),
                  border: Border.all(color: Colors.amber.withOpacity(0.45)),
                ),
                child: Text(
                  '⭐ ${review.rating}/5',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment == null || review.comment!.trim().isEmpty
                ? 'Korisnik nije ostavio komentar.'
                : review.comment!,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}