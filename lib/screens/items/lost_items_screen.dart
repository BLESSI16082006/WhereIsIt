import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_post_service.dart';
import 'post_details_screen.dart';

class LostItemsScreen extends StatelessWidget {
  LostItemsScreen({super.key});

  final FirestorePostService _postService = FirestorePostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lost Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _postService.getLostPosts(),
        builder: (context, snapshot) {
          // --------------------------------------------------
          // LOADING
          // --------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // --------------------------------------------------
          // ERROR
          // --------------------------------------------------

          if (snapshot.hasError) {
            return _buildErrorState(
              context,
              snapshot.error.toString(),
            );
          }

          // --------------------------------------------------
          // EMPTY
          // --------------------------------------------------

          final posts = snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          // --------------------------------------------------
          // POSTS
          // --------------------------------------------------

          return RefreshIndicator(
            onRefresh: () async {
              // Stream automatically refreshes from Firestore.
              await Future.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data();

                return _buildPostCard(
                  context,
                  post,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // POST CARD
  // ------------------------------------------------------------

  Widget _buildPostCard(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    final String itemName =
        post['itemName']?.toString() ?? 'Unnamed Item';

    final String category =
        post['category']?.toString() ?? '';

    final String location =
        post['location']?.toString() ?? '';

    final String description =
        post['description']?.toString() ?? '';

    final String imageUrl =
        post['imageUrl']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsScreen(
                post: post,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // IMAGE
              // ------------------------------------------------

              _buildThumbnail(
                imageUrl,
              ),

              const SizedBox(width: 14),

              // ------------------------------------------------
              // DETAILS
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            'LOST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],

                    const SizedBox(height: 9),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 13,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // THUMBNAIL
  // ------------------------------------------------------------

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _buildImagePlaceholder();
          },
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 38,
        color: AppColors.secondaryText,
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Lost Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no active lost item posts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR STATE
  // ------------------------------------------------------------

  Widget _buildErrorState(
    BuildContext context,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load lost items',
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
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                // The StreamBuilder will reconnect automatically.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Refreshing lost items...',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}