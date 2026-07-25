import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/anime_item.dart';
import '../../providers/detail_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'widgets/episode_tile.dart';

class DetailScreen extends StatefulWidget {
  final AnimeItem anime;

  const DetailScreen({super.key, required this.anime});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<DetailProvider>();
    provider.setAnime(widget.anime);
    provider.loadEpisodes(widget.anime.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.anime.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // Download All button
          Consumer<DetailProvider>(
            builder: (context, provider, _) {
              if (provider.episodes.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Download All',
                onPressed: () {
                  if (provider.episodes.isEmpty) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Download All Episodes'),
                      content: Text(
                        'Start downloading all ${provider.episodes.length} episodes?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.downloadAll();
                          },
                          child: const Text('Download All'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<DetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'Loading episodes...');
          }

          if (provider.error != null) {
            return EmptyState(
              icon: Icons.error_outline,
              message: 'Failed to load episodes',
              subtitle: provider.error,
            );
          }

          if (provider.episodes.isEmpty) {
            return const EmptyState(
              icon: Icons.videocam_off_outlined,
              message: 'No episodes available',
            );
          }

          return Column(
            children: [
              // Header with anime info
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 112,
                        child: CachedNetworkImage(
                          imageUrl: widget.anime.thumbnail,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.anime.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.episodes.length} episodes',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Episode list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.episodes.length,
                  itemBuilder: (context, index) {
                    final ep = provider.episodes[index];
                    return EpisodeTile(
                      episode: ep,
                      onDownload: () => provider.resolveAndDownload(ep),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
