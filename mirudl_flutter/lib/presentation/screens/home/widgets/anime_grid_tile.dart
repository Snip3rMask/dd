import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/models/anime_item.dart';
import '../../../theme/app_colors.dart';

/// List tile variant for tablet/landscape
class AnimeListTile extends StatelessWidget {
  final AnimeItem anime;
  final VoidCallback onTap;

  const AnimeListTile({
    super.key,
    required this.anime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              child: SizedBox(
                width: 80,
                height: 112,
                child: CachedNetworkImage(
                  imageUrl: anime.thumbnail,
                  fit: BoxFit.cover,
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
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (anime.type.isNotEmpty || anime.year.isNotEmpty)
                      Text(
                        '${anime.type}${anime.type.isNotEmpty && anime.year.isNotEmpty ? ' • ' : ''}${anime.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    if (anime.episodes > 0)
                      Text(
                        '${anime.episodes} episodes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
