import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../models/listing_card.dart';

class ListingCardWidget extends StatelessWidget {
  final ListingCard item;
  final VoidCallback? onTap;

  const ListingCardWidget({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = (item.coverUrl == null || item.coverUrl!.isEmpty)
        ? null
        : '${ApiConfig.baseUrl}${item.coverUrl}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 100,
                height: 82,
                color: Colors.black.withOpacity(0.05),
                child: imgUrl == null
                    ? const Icon(Icons.home, size: 34)
                    : Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.city} • ${item.rentType}',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.orange.withOpacity(0.95)),
                      const SizedBox(width: 4),
                      Text(
                        item.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${item.reviewsCount})',
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                      const Spacer(),
                      Text(
                        '${item.pricePerNight.toStringAsFixed(0)} KM',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
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
}
