import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/search_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'widgets/anime_card.dart';
import 'widgets/search_bar.dart';
import '../detail/detail_screen.dart';
import '../downloads/downloads_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentTab],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() => _currentTab = index);
        },
      ),
    );
  }
}

/// Home tab with search and grid
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              return SearchBarWidget(
                controller: _searchController,
                onChanged: (query) {
                  provider.search(query);
                },
                onClear: () {
                  _searchController.clear();
                  provider.clear();
                },
              );
            },
          ),
          // Results
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const LoadingIndicator(message: 'Searching...');
                }

                if (provider.error != null) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    message: 'Something went wrong',
                    subtitle: provider.error,
                  );
                }

                if (provider.results.isEmpty) {
                  if (provider.query.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search,
                      message: 'Search for anime',
                      subtitle: 'Type in the search bar to find anime',
                    );
                  }
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'No results found',
                    subtitle: 'Try a different search term',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600
                        ? (constraints.maxWidth / 180).floor()
                        : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: provider.results.length,
                      itemBuilder: (context, index) {
                        final anime = provider.results[index];
                        return AnimeCard(
                          anime: anime,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(anime: anime),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
