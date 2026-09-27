import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/recent_post_card.dart';
import '../../widgets/navigation/user_drawer.dart';
import '../items/post_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedLocation = '';

  // ------------------------------------------------------------
  // FIRESTORE POSTS
  //
  // No where() + orderBy() query is used here.
  // This avoids the Firestore composite-index requirement.
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> _getRecentPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .snapshots();
  }

  // ------------------------------------------------------------
  // PREPARE RECENT ACTIVE POSTS
  //
  // Filtering and sorting are done in Dart instead of Firestore.
  // ------------------------------------------------------------

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _getRecentActivePosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allPosts,
  ) {
    // ----------------------------------------------------------
    // ONLY ACTIVE POSTS
    // ----------------------------------------------------------

    final activePosts =
        allPosts.where((doc) {
      final Map<String, dynamic> post = doc.data();

      return post['status']?.toString().toLowerCase() == 'active';
    }).toList();

    // ----------------------------------------------------------
    // SORT BY CREATED DATE
    //
    // Newest posts appear first.
    // Posts without createdAt are placed at the bottom.
    // ----------------------------------------------------------

    activePosts.sort((a, b) {
      final dynamic valueA = a.data()['createdAt'];
      final dynamic valueB = b.data()['createdAt'];

      final Timestamp? dateA =
          valueA is Timestamp ? valueA : null;

      final Timestamp? dateB =
          valueB is Timestamp ? valueB : null;

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    // ----------------------------------------------------------
    // LATEST 20 POSTS
    // ----------------------------------------------------------

    return activePosts.take(20).toList();
  }

  // ------------------------------------------------------------
  // SEARCH / FILTER
  // ------------------------------------------------------------

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    final String query =
        _searchQuery.trim().toLowerCase();

    final String location =
        _selectedLocation.trim().toLowerCase();

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    return posts.where((doc) {
      final Map<String, dynamic> post = doc.data();

      final String itemName =
          post['itemName']?.toString().toLowerCase() ?? '';

      final String category =
          post['category']?.toString().toLowerCase() ?? '';

      final String postLocation =
          post['location']?.toString().toLowerCase() ?? '';

      final String postUserId =
          post['userId']?.toString() ?? '';

      final bool isOwner =
          currentUser != null &&
          currentUser.uid == postUserId;

      // --------------------------------------------------------
      // VALUABLE ITEM PRIVACY
      //
      // Finder details for Found Valuable Items must not be
      // searchable publicly through the private description.
      // The owner can still search their own description.
      // --------------------------------------------------------

      final bool isPrivateFinderData =
          post['isPrivateFinderData'] == true;

      final String description =
          (!isPrivateFinderData || isOwner)
              ? post['description']
                      ?.toString()
                      .toLowerCase() ??
                  ''
              : '';

      // --------------------------------------------------------
      // KEYWORD SEARCH
      // --------------------------------------------------------

      final bool matchesKeyword =
          query.isEmpty ||
          itemName.contains(query) ||
          category.contains(query) ||
          description.contains(query) ||
          postLocation.contains(query);

      // --------------------------------------------------------
      // LOCATION FILTER
      // --------------------------------------------------------

      final bool matchesLocation =
          location.isEmpty ||
          postLocation == location;

      return matchesKeyword && matchesLocation;
    }).toList();
  }

  // ------------------------------------------------------------
  // OPEN SEARCH FILTER
  // ------------------------------------------------------------

  Future<void> _openSearchFilter() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.searchFilter,
    );

    if (!mounted) {
      return;
    }

    if (result != null && result is Map) {
      final String keyword =
          result['keyword']?.toString().trim() ?? '';

      final String location =
          result['location']?.toString().trim() ?? '';

      setState(() {
        _searchQuery = keyword;
        _selectedLocation = location;
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
  // OPEN LOST ITEMS
  // ------------------------------------------------------------

  void _openLostItems() {
    Navigator.pushNamed(
      context,
      AppRoutes.lostItems,
    );
  }

  // ------------------------------------------------------------
  // OPEN FOUND ITEMS
  // ------------------------------------------------------------

  void _openFoundItems() {
    Navigator.pushNamed(
      context,
      AppRoutes.foundItems,
    );
  }

  // ------------------------------------------------------------
  // OPEN CREATE POST
  // ------------------------------------------------------------

  void _openCreatePost() {
    Navigator.pushNamed(
      context,
      AppRoutes.createPost,
    );
  }

  // ------------------------------------------------------------
  // OPEN POST DETAILS
  // ------------------------------------------------------------

  void _openPostDetails(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(
          post: post,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
        child:
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _getRecentPosts(),
          builder: (context, snapshot) {
            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------

            if (snapshot.hasError) {
              debugPrint(
                'FIRESTORE ERROR: ${snapshot.error}',
              );

              return _buildErrorState(
                snapshot.error.toString(),
              );
            }

            // ----------------------------------------------------
            // LOADING
            // ----------------------------------------------------

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // ----------------------------------------------------
            // ALL FIRESTORE POSTS
            // ----------------------------------------------------

            final List<
                    QueryDocumentSnapshot<Map<String, dynamic>>>
                allPosts =
                snapshot.data?.docs ?? [];

            // ----------------------------------------------------
            // ACTIVE + SORTED + LATEST 20
            // ----------------------------------------------------

            final List<
                    QueryDocumentSnapshot<Map<String, dynamic>>>
                recentPosts =
                _getRecentActivePosts(allPosts);

            // ----------------------------------------------------
            // SEARCH + LOCATION FILTER
            // ----------------------------------------------------

            final List<
                    QueryDocumentSnapshot<Map<String, dynamic>>>
                posts =
                _filterPosts(recentPosts);

            return RefreshIndicator(
              onRefresh: () async {
                // Firestore Stream automatically receives changes.
                await Future.delayed(
                  const Duration(milliseconds: 300),
                );
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // ----------------------------------------------
                  // WELCOME
                  // ----------------------------------------------

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

                  // ----------------------------------------------
                  // SEARCH BAR
                  // ----------------------------------------------

                  AppSearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // ----------------------------------------------
                  // FILTER + CREATE POST
                  // ----------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openSearchFilter,
                          icon: const Icon(
                            Icons.filter_list,
                          ),
                          label: const Text(
                            'Filter',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openCreatePost,
                          icon: const Icon(
                            Icons.add,
                          ),
                          label: const Text(
                            'Create Post',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ----------------------------------------------
                  // LOST / FOUND QUICK ACCESS
                  // ----------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(12),
                            onTap: _openLostItems,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 10,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 30,
                                    color:
                                        Colors.orange.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Lost Items',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(12),
                            onTap: _openFoundItems,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 10,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle_outline,
                                    size: 30,
                                    color:
                                        Colors.green.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Found Items',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------------------
                  // RECENT POSTS HEADER
                  // ----------------------------------------------

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

                  // ----------------------------------------------
                  // POSTS
                  // ----------------------------------------------

                  if (posts.isEmpty)
                    _buildEmptySearchState()
                  else
                    ...posts.map(
                      (doc) {
                        final Map<String, dynamic> post =
                            doc.data();

                        return _buildRecentPostCard(
                          context,
                          post,
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT POST CARD
  // ------------------------------------------------------------

  Widget _buildRecentPostCard(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    final String itemName =
        post['itemName']?.toString() ?? 'Unnamed Item';

    final String category =
        post['category']?.toString() ?? '';

    final String postType =
        post['postType']?.toString() ?? '';

    final String location =
        post['location']?.toString() ?? '';

    final String description =
        post['description']?.toString() ?? '';

    final String postUserId =
        post['userId']?.toString() ?? '';

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final bool isOwner =
        currentUser != null &&
        currentUser.uid == postUserId;

    // ----------------------------------------------------------
    // VALUABLE ITEM PRIVACY
    //
    // Found Valuable Item finder information remains private
    // to public users.
    // ----------------------------------------------------------

    final bool isPrivateFinderData =
        post['isPrivateFinderData'] == true;

    final String visibleDescription =
        isPrivateFinderData && !isOwner
            ? ''
            : description;

    // ----------------------------------------------------------
    // IMPORTANT:
    // No userName parameter.
    // No profile picture parameter.
    // ----------------------------------------------------------

    return RecentPostCard(
      itemName: itemName,
      category: category,
      postType: postType,
      location: location,
      description: visibleDescription,
      isPrivateFinderData:
          isPrivateFinderData && !isOwner,
      onTap: () {
        _openPostDetails(
          context,
          post,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptySearchState() {
    final bool isFiltered =
        _searchQuery.trim().isNotEmpty ||
        _selectedLocation.trim().isNotEmpty;

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
            isFiltered
                ? Icons.search_off_rounded
                : Icons.inventory_2_outlined,
            size: 52,
            color: Colors.grey.shade500,
          ),

          const SizedBox(height: 14),

          Text(
            isFiltered
                ? 'No posts found'
                : 'No recent posts',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            isFiltered
                ? 'Try searching with another item name or keyword.'
                : 'No users have created a post yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR STATE
  // ------------------------------------------------------------

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load recent posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}