import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/models/anime_item.dart';
import '../../../theme/app_colors.dart';

class AnimeCard extends StatelessWidget {
  final AnimeItem anime;
  final VoidCallback onTap;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: CachedNetworkImage(
                imageUrl: anime.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                anime.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Meta
            if (anime.type.isNotEmpty || anime.year.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  '${anime.type}${anime.type.isNotEmpty && anime.year.isNotEmpty ? ' • ' : ''}${anime.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
