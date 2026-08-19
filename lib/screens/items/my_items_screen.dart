import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_post_service.dart';
import 'edit_post_screen.dart';
import 'post_details_screen.dart';

class MyItemsScreen extends StatelessWidget {
  MyItemsScreen({super.key});

  final FirestorePostService _postService =
      FirestorePostService();

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? _buildNotLoggedInState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _postService.getUserPosts(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final posts =
                    snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data();

                    return _buildPostCard(
                      context,
                      post,
                    );
                  },
                );
              },
            ),
    );
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  Future<void> _deletePost(
    BuildContext context,
    String postId,
    String itemName,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: Text(
            'Are you sure you want to delete '
            '"$itemName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _postService.deletePost(postId);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete post.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // POST CARD
  // ============================================================

  Widget _buildPostCard(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    final String postId =
        post['postId']?.toString() ?? '';

    final String itemName =
        post['itemName']?.toString() ??
            'Unnamed Item';

    final String postType =
        post['postType']?.toString() ??
            'Unknown';

    final String category =
        post['category']?.toString() ?? '';

    final String location =
        post['location']?.toString() ?? '';

    final String description =
        post['description']?.toString() ?? '';

    final String status =
        post['status']?.toString() ?? 'active';

    final bool isCompleted =
        post['isCompleted'] == true ||
            status == 'completed';

    final String imageUrl =
        post['imageUrl']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: isCompleted ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.shade300
              : Colors.grey.shade200,
        ),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGE
              // ==================================================

              _buildThumbnail(
                imageUrl,
                isCompleted,
              ),

              const SizedBox(width: 14),

              // ==================================================
              // DETAILS
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TITLE + STATUS + POPUP MENU
                    // ==================================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              color: isCompleted
                                  ? Colors.grey.shade700
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _buildStatusBadge(
                          postType,
                          isCompleted,
                        ),

                        const SizedBox(width: 2),

                        // ==================================================
                        // POPUP MENU
                        // ==================================================

                        PopupMenuButton<String>(
                          tooltip: 'More options',
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            // EDIT
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditPostScreen(
                                    post: post,
                                  ),
                                ),
                              );
                            }

                            // DELETE
                            else if (value == 'delete') {
                              _deletePost(
                                context,
                                postId,
                                itemName,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            // EDIT
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // DELETE
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // CATEGORY
                    // ==================================================

                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                    // ==================================================
                    // LOCATION
                    // ==================================================

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color:
                                Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // ==================================================
                    // BOTTOM STATUS
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        if (isCompleted)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 17,
                                color:
                                    Colors.green.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: Colors
                                      .green
                                      .shade700,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            postType == 'Lost'
                                ? 'Lost Item'
                                : 'Found Item',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        Row(
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color:
                                  Colors.teal.shade700,
                            ),
                          ],
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

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String postType,
    bool isCompleted,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          'COMPLETED',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      );
    }

    final bool isLost =
        postType == 'Lost';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isLost
            ? Colors.orange.shade50
            : Colors.green.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isLost
              ? Colors.orange.shade800
              : Colors.green.shade800,
        ),
      ),
    );
  }

  // ============================================================
  // THUMBNAIL
  // ============================================================

  Widget _buildThumbnail(
    String imageUrl,
    bool isCompleted,
  ) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          color: isCompleted
              ? Colors.white
                  .withValues(alpha: 0.35)
              : null,
          colorBlendMode: isCompleted
              ? BlendMode.saturation
              : null,
          errorBuilder:
              (context, error, stackTrace) {
            return _buildImagePlaceholder(
              isCompleted,
            );
          },
        ),
      );
    }

    return _buildImagePlaceholder(
      isCompleted,
    );
  }

  Widget _buildImagePlaceholder(
    bool isCompleted,
  ) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        isCompleted
            ? Icons.check_circle_outline
            : Icons.image_outlined,
        size: 38,
        color: isCompleted
            ? Colors.green.shade500
            : Colors.grey.shade500,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Items Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you create will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOT LOGGED IN
  // ============================================================

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please Log In',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in to view your items.',
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

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
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
              'Unable to load your items',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
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