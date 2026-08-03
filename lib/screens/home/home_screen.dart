import 'package:flutter/material.dart';

import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/recent_post_card.dart';
import '../../widgets/navigation/user_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  // Temporary sample posts.
  // Firestore posts will be connected later.
  final List<Map<String, String>> _recentPosts = [
    {
      'itemName': 'Gold Ring',
      'category': 'Valuable Items',
      'postType': 'Lost',
      'location': 'Nagercoil',
      'description':
          'Gold ring with a small engraved mark and unique design.',
    },
    {
      'itemName': 'Aadhaar Card',
      'category': 'Identity Documents',
      'postType': 'Found',
      'location': 'Marthandam',
      'description':
          'Identity document found near the main road.',
    },
    {
      'itemName': 'Black Backpack',
      'category': 'General Items',
      'postType': 'Lost',
      'location': 'Thuckalay',
      'description':
          'Black backpack containing books and personal belongings.',
    },
  ];

  // ------------------------------------------------------------
  // SEARCH POSTS
  // ------------------------------------------------------------

  List<Map<String, String>> get _filteredPosts {
    if (_searchQuery.trim().isEmpty) {
      return _recentPosts;
    }

    final query = _searchQuery.trim().toLowerCase();

    return _recentPosts.where((post) {
      return post['itemName']!.toLowerCase().contains(query) ||
          post['category']!.toLowerCase().contains(query) ||
          post['description']!.toLowerCase().contains(query) ||
          post['location']!.toLowerCase().contains(query);
    }).toList();
  }

  // ------------------------------------------------------------
  // OPEN SEARCH FILTER
  // ------------------------------------------------------------

  Future<void> _openSearchFilter() async {
    final result = await Navigator.pushNamed(
      context,
      '/search-filter',
    );

    if (!mounted) return;

    if (result != null && result is Map) {
      final keyword =
          result['keyword']?.toString().trim() ?? '';

      final location =
          result['location']?.toString().trim() ?? '';

      setState(() {
        if (keyword.isNotEmpty) {
          _searchQuery = keyword;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            location.isEmpty
                ? 'Filter applied'
                : 'Filter applied: $location',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

    return Scaffold(
      drawer: const UserDrawer(),

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'WhereIsIt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notifications will be available soon.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
        ],
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Firestore refresh will be added later.
            await Future.delayed(
              const Duration(milliseconds: 500),
            );

            if (!mounted) return;

            setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // ------------------------------------------------
              // WELCOME SECTION
              // ------------------------------------------------

              const Text(
                'Find what you lost.\nHelp return what you found.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Search recent lost and found posts.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // SEARCH BAR
              // ------------------------------------------------

              AppSearchBar(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // SEARCH FILTER + CREATE POST
              // ------------------------------------------------

              Row(
                children: [
                  // FILTER BUTTON
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openSearchFilter,
                      icon: const Icon(
                        Icons.filter_list,
                      ),
                      label: const Text('Filter'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // CREATE POST BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Create Post will be connected in the Lost/Found module.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Post'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // RECENT POSTS HEADER
              // ------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Posts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${posts.length} posts',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // POSTS
              // ------------------------------------------------

              if (posts.isEmpty)
                _buildEmptySearchState()
              else
                ...posts.map(
                  (post) => RecentPostCard(
                    itemName: post['itemName']!,
                    category: post['category']!,
                    postType: post['postType']!,
                    location: post['location']!,
                    description: post['description']!,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'View details for '
                            '${post['itemName']} '
                            'will be connected later.',
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY SEARCH STATE
  // ------------------------------------------------------------

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey.shade100,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 14),
          const Text(
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching with another item name or keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}