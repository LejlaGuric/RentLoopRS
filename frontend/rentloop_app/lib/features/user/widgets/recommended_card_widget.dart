import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../models/listing_card.dart';

class RecommendedCardWidget extends StatelessWidget {
  final ListingCard item;
  final VoidCallback onTap;

  const RecommendedCardWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    final cover = (item.coverUrl == null || item.coverUrl!.isEmpty)
        ? null
        : '${ApiConfig.baseUrl}${item.coverUrl}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ manja slika da uvijek stane
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 120, // ✅ bilo 150
                width: double.infinity,
                color: Colors.black.withOpacity(0.05),
                child: cover == null
                    ? const Center(child: Icon(Icons.image, size: 40))
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.image_not_supported, size: 40)),
                      ),
              ),
            ),

            // ✅ sadržaj zbijen + kontrola redova
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),

                  // city + rentType
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.black.withOpacity(0.55)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.city} • ${item.rentType}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.65),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // price + rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: blue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: blue.withOpacity(0.25)),
                        ),
                        child: Text(
                          '${item.pricePerNight.toStringAsFixed(0)} KM / noć',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            item.avgRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${item.reviewsCount})',
                            style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ✅ Wrap da nikad ne overflowa horizontalno/vertikalno
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _mini('🛏 ${item.roomsCount}'),
                      _mini('👥 ${item.maxGuests}'),
                      _mini('📍 ${item.distanceToCenterKm.toStringAsFixed(1)} km'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
