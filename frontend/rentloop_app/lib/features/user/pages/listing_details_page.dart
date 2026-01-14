import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';

import '../models/listing_details.dart';
import '../services/listings_service.dart';
import '../services/favorites_service.dart'; 
import 'reservation_create_page.dart';


class ListingDetailsPage extends StatefulWidget {
  final int listingId;

  const ListingDetailsPage({super.key, required this.listingId});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  final _svc = ListingsService();
  final _favSvc = FavoritesService(); // ✅ NOVO

  bool _loading = true;
  String _error = '';
  ListingDetails? _data;

  // ✅ NOVO: favorites state
  bool _isFav = false;
  bool _favLoading = false;

  final PageController _pageCtrl = PageController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        _svc.getById(widget.listingId),
        _favSvc.isFavorite(widget.listingId),
      ]);

      if (!mounted) return;

      setState(() {
        _data = results[0] as ListingDetails;
        _isFav = results[1] as bool;
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

  Future<void> _toggleFavorite() async {
    if (_favLoading) return;

    setState(() => _favLoading = true);

    try {
      if (_isFav) {
        await _favSvc.remove(widget.listingId);
        if (!mounted) return;
        setState(() => _isFav = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uklonjeno iz favorita')),
        );
      } else {
        await _favSvc.add(widget.listingId);
        if (!mounted) return;
        setState(() => _isFav = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano u favorite')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Greška' : msg)),
      );
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  void _goPrev(int count) {
    if (count <= 1) return;
    final next = (_pageIndex - 1).clamp(0, count - 1);
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goNext(int count) {
    if (count <= 1) return;
    final next = (_pageIndex + 1).clamp(0, count - 1);
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
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
        title: const Text('Detalji'),
        actions: [
          IconButton(
            onPressed: _favLoading ? null : _toggleFavorite,
            icon: _favLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFav ? Icons.favorite : Icons.favorite_border,
                    color: _isFav ? Colors.red : Colors.black.withOpacity(0.75),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _data == null
                  ? const Center(child: Text('Nema podataka'))
                  : _buildBody(context, blue),
    );
  }

  Widget _buildBody(BuildContext context, Color blue) {
    final d = _data!;

    final imgs = d.images
        .map((e) => '${ApiConfig.baseUrl}${e.url}')
        .where((u) => u.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _gallery(context, imgs, blue),

        const SizedBox(height: 14),

        // naslov + lokacija
        Text(
          d.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18, color: Colors.black.withOpacity(0.55)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${d.city} • ${d.rentType}',
                style: TextStyle(color: Colors.black.withOpacity(0.65), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // info cards
        Row(
          children: [
            Expanded(child: _infoCard('Cijena', '${d.pricePerNight.toStringAsFixed(0)} KM / noć', blue)),
            const SizedBox(width: 10),
            Expanded(child: _infoCard('Sobe', '${d.roomsCount}', blue)),
            const SizedBox(width: 10),
            Expanded(child: _infoCard('Gosti', '${d.maxGuests}', blue)),
          ],
        ),

        const SizedBox(height: 12),

        _section(
          title: 'Adresa',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, color: Colors.black.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.address,
                  style: TextStyle(color: Colors.black.withOpacity(0.75), height: 1.35),
                ),
              ),
            ],
          ),
        ),

        if (d.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _section(
            title: 'Opis',
            child: Text(
              d.description,
              style: TextStyle(color: Colors.black.withOpacity(0.75), height: 1.45),
            ),
          ),
        ],

        const SizedBox(height: 12),

        _section(
          title: 'Opcije',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(d.hasWifi ? 'WiFi' : 'Bez WiFi', icon: Icons.wifi),
              _chip(d.hasAirConditioning ? 'Klima' : 'Bez klime', icon: Icons.ac_unit),
              _chip(d.petsAllowed ? 'Pets allowed' : 'No pets', icon: Icons.pets),
              _chip('Udaljenost: ${d.distanceToCenterKm.toStringAsFixed(1)} km', icon: Icons.map_outlined),
            ],
          ),
        ),

        if (d.selectedAmenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section(
            title: 'Amenities',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: d.selectedAmenities.map((t) => _chip(t, icon: Icons.check_circle_outline)).toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // CTA dugme (kasnije rezervacija)
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
  final d = _data!;
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ReservationCreatePage(
        listingId: d.id, // ili widget.listingId, oba su ok
        listingName: d.name,
        pricePerNight: d.pricePerNight.toDouble(),
        maxGuests: d.maxGuests,
      ),
    ),
  );

  if (!mounted) return;

  if (changed == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rezervacija poslana (čeka odobrenje).')),
    );

    // opcionalno: refresh detalja (ne mora, ali može)
    // await _load();
  }
},

            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Rezerviši', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  // ------------------ GALLERY ------------------

  Widget _gallery(BuildContext context, List<String> imgs, Color blue) {
    final count = imgs.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 250,
        color: Colors.black.withOpacity(0.05),
        child: Stack(
          children: [
            if (count == 0)
              const Center(child: Icon(Icons.image, size: 64))
            else
              PageView.builder(
                controller: _pageCtrl,
                itemCount: count,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (_, i) {
                  final url = imgs[i];
                  return GestureDetector(
                    onTap: () => _openGalleryPreview(context, imgs, i),
                    child: Hero(
                      tag: 'listing_gallery_${widget.listingId}_$i',
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 54)),
                      ),
                    ),
                  );
                },
              ),

            // strelice (samo ako ima više slika)
            if (count > 1) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: _arrowBtn(
                  icon: Icons.chevron_left,
                  onTap: () => _goPrev(count),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: _arrowBtn(
                  icon: Icons.chevron_right,
                  onTap: () => _goNext(count),
                ),
              ),
            ],

            // indicator (1/5)
            if (count > 0)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_pageIndex + 1}/$count',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),

            // hint
            if (count > 0)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.zoom_out_map, size: 16, color: blue),
                      const SizedBox(width: 6),
                      const Text('Tap za full', style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _arrowBtn({required IconData icon, required VoidCallback onTap}) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _openGalleryPreview(BuildContext context, List<String> imgs, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryPreviewPage(
          listingId: widget.listingId,
          images: imgs,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // ------------------ UI HELPERS ------------------

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, Color blue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: blue.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.black.withOpacity(0.65), fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _chip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black.withOpacity(0.65)),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ------------------ FULLSCREEN PREVIEW ------------------

class _GalleryPreviewPage extends StatefulWidget {
  final int listingId;
  final List<String> images;
  final int initialIndex;

  const _GalleryPreviewPage({
    required this.listingId,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GalleryPreviewPage> createState() => _GalleryPreviewPageState();
}

class _GalleryPreviewPageState extends State<_GalleryPreviewPage> {
  late final PageController _ctrl;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_i + 1}/$count'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: count,
        onPageChanged: (x) => setState(() => _i = x),
        itemBuilder: (_, idx) {
          final url = widget.images[idx];
          return Center(
            child: Hero(
              tag: 'listing_gallery_${widget.listingId}_$idx',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.white, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
