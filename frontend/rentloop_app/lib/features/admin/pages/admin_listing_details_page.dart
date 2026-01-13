import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../models/admin_listing_details.dart';
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

  int _selectedImageIndex = 0;

  // ✅ kontroler za horizontalni scroll thumbnails-a
  final ScrollController _thumbCtrl = ScrollController();

  // dimenzije thumbnail kartice (moraju odgovarati onome što imaš dole)
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final d = await _service.getById(widget.listingId);
      if (!mounted) return;

      int idx = 0;
      if (d.images.isNotEmpty) {
        final coverIdx = d.images.indexWhere((x) => x.isCover);
        idx = coverIdx >= 0 ? coverIdx : 0;
      }

      setState(() {
        _data = d;
        _selectedImageIndex = idx;
      });

      // ✅ nakon što se UI nacrta, scrollaj thumbs do selektovane slike
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureThumbVisible(_selectedImageIndex);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _selectImage(int i) {
    setState(() => _selectedImageIndex = i);
    _ensureThumbVisible(i);
  }

  void _ensureThumbVisible(int index) {
    if (!_thumbCtrl.hasClients) return;

    // ciljna pozicija: neka thumbnail dođe lijepo u sredinu (otprilike)
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
    // dir: -1 lijevo, +1 desno
    if (!_thumbCtrl.hasClients) return;

    final current = _thumbCtrl.offset;
    final delta = _thumbItemExtent * 2; // skok za ~2 thumbnail-a (možeš promijeniti)
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

    final all = (d.allAmenities ?? <String>[]);
    final selected = (d.selectedAmenities ?? <String>[]);

    final selectedSet = selected.map((e) => e.toLowerCase().trim()).toSet();
    final hasList = all.where((x) => selectedSet.contains(x.toLowerCase().trim())).toList();
    final noList = all.where((x) => !selectedSet.contains(x.toLowerCase().trim())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Stan #${d.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
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
                  // GALERIJA
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
                                    // ✅ Lijeva strelica
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

                                    // ✅ Thumbnails list
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

                                    // ✅ Desna strelica
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

                  // INFO
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
