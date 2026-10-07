import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_post_service.dart';
import '../../services/recovery_service.dart';
import 'edit_post_screen.dart';
import 'post_details_screen.dart';
import 'recovery_confirmation_screen.dart';

class MyItemsScreen extends StatelessWidget {
  MyItemsScreen({super.key});

  final FirestorePostService _postService =
      FirestorePostService();

  final RecoveryService _recoveryService =
      RecoveryService();

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
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _postService.getUserPosts(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
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
                  padding:
                      const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder:
                      (context, index) {
                    final post =
                        posts[index].data();

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
  // ITEM RETURNED
  // ============================================================

  Future<void> _markItemReturned(
    BuildContext context,
    Map<String, dynamic> post,
  ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        context,
        'Please log in again.',
      );
      return;
    }

    final String postId =
        post['postId']?.toString() ?? '';

    final String itemName =
        post['itemName']?.toString() ??
            'this item';

    final String matchedPostId =
        post['matchedPostId']?.toString() ??
            '';

    if (postId.isEmpty) {
      _showMessage(
        context,
        'Unable to identify this post.',
      );
      return;
    }

    // ----------------------------------------------------------
    // A matched post is required for the current
    // lost/found recovery workflow.
    // ----------------------------------------------------------

    if (matchedPostId.isEmpty) {
      _showMessage(
        context,
        'This item has not been connected to a matching Lost/Found post yet.',
      );
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Start Item Recovery?',
          ),
          content: Text(
            'Do you want to start the recovery process '
            'for "$itemName"?\n\n'
            'After the recovery request is created, '
            'both the owner and finder must confirm '
            'the item return.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // --------------------------------------------------------
      // Get current post.
      // --------------------------------------------------------

      final DocumentSnapshot<
              Map<String, dynamic>>
          currentPost =
          await _recoveryService.getPost(
        postId,
      );

      if (!currentPost.exists) {
        _showMessage(
          context,
          'The post could not be found.',
        );
        return;
      }

      final Map<String, dynamic>? currentData =
          currentPost.data();

      if (currentData == null) {
        _showMessage(
          context,
          'Unable to read the post information.',
        );
        return;
      }

      // --------------------------------------------------------
      // Get matched post.
      // --------------------------------------------------------

      final DocumentSnapshot<
              Map<String, dynamic>>
          matchedPost =
          await _recoveryService.getPost(
        matchedPostId,
      );

      if (!matchedPost.exists) {
        _showMessage(
          context,
          'The matched post could not be found.',
        );
        return;
      }

      final Map<String, dynamic>? matchedData =
          matchedPost.data();

      if (matchedData == null) {
        _showMessage(
          context,
          'Unable to read the matched post information.',
        );
        return;
      }

      final String currentPostType =
          currentData['postType']
                  ?.toString() ??
              '';

      final String matchedPostType =
          matchedData['postType']
                  ?.toString() ??
              '';

      // --------------------------------------------------------
      // Determine Lost and Found posts.
      // --------------------------------------------------------

      String lostPostId;
      String foundPostId;

      Map<String, dynamic> lostData;
      Map<String, dynamic> foundData;

      if (currentPostType == 'Lost' &&
          matchedPostType == 'Found') {
        lostPostId = postId;
        foundPostId = matchedPostId;

        lostData = currentData;
        foundData = matchedData;
      } else if (currentPostType == 'Found' &&
          matchedPostType == 'Lost') {
        lostPostId = matchedPostId;
        foundPostId = postId;

        lostData = matchedData;
        foundData = currentData;
      } else {
        _showMessage(
          context,
          'The matched posts do not form a valid Lost/Found pair.',
        );
        return;
      }

      final String ownerId =
          lostData['userId']?.toString() ??
              '';

      final String finderId =
          foundData['userId']?.toString() ??
              '';

      if (ownerId.isEmpty ||
          finderId.isEmpty) {
        _showMessage(
          context,
          'Unable to identify the owner or finder.',
        );
        return;
      }

      // --------------------------------------------------------
      // Make sure current user is one of the two users.
      // --------------------------------------------------------

      if (currentUser.uid != ownerId &&
          currentUser.uid != finderId) {
        _showMessage(
          context,
          'You are not part of this recovery.',
        );
        return;
      }

      // --------------------------------------------------------
      // Check whether recovery already exists.
      // --------------------------------------------------------

      final QuerySnapshot<
              Map<String, dynamic>>
          existingRecovery =
          await _recoveryService
              .getRecoveryByPosts(
        lostPostId: lostPostId,
        foundPostId: foundPostId,
      );

      String recoveryId;

      if (existingRecovery.docs.isNotEmpty) {
        // ------------------------------------------------------
        // Recovery already exists.
        // ------------------------------------------------------

        final QueryDocumentSnapshot<
                Map<String, dynamic>>
            recoveryDoc =
            existingRecovery.docs.first;

        recoveryId = recoveryDoc.id;

        final Map<String, dynamic>
            recoveryData =
            recoveryDoc.data();

        final String status =
            recoveryData['status']
                    ?.toString() ??
                'pending';

        if (status == 'completed') {
          _showMessage(
            context,
            'This recovery has already been completed.',
          );
          return;
        }

        if (status == 'cancelled') {
          _showMessage(
            context,
            'This recovery request was cancelled.',
          );
          return;
        }
      } else {
        // ------------------------------------------------------
        // Create new recovery request.
        // ------------------------------------------------------

        recoveryId =
            await _recoveryService
                .createRecoveryRequest(
          lostPostId: lostPostId,
          foundPostId: foundPostId,
          ownerId: ownerId,
          finderId: finderId,
        );
      }

      if (!context.mounted) {
        return;
      }

      // --------------------------------------------------------
      // Open the existing Recovery Confirmation screen.
      // --------------------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecoveryConfirmationScreen(
            recoveryId: recoveryId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Unable to start the recovery process. '
        'Please try again.',
      );
    }
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
          title: const Text(
            'Delete Post?',
          ),
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
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _postService.deletePost(
        postId,
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Post deleted successfully.',
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Unable to delete post.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
        post['status']?.toString() ??
            'active';

    final String recoveryStatus =
        post['recoveryStatus']
                ?.toString() ??
            'not_started';

    final bool isCompleted =
        post['isCompleted'] == true ||
            status == 'completed';

    // IMPORTANT:
    // RecoveryService uses "return_pending".
    final bool recoveryPending =
        recoveryStatus == 'return_pending' ||
            status == 'return_pending';

    final String imageUrl =
        post['imageUrl']?.toString() ?? '';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation:
          isCompleted ? 0 : 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: isCompleted
              ? AppColors.success
              : recoveryPending
                  ? AppColors.warning
                  : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailsScreen(
                post: post,
              ),
            ),
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildThumbnail(
                imageUrl,
                isCompleted,
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TITLE + STATUS + MENU
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
                                  ? Colors
                                      .grey
                                      .shade700
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        _buildStatusBadge(
                          postType,
                          isCompleted,
                          recoveryPending,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        PopupMenuButton<String>(
                          tooltip:
                              'More options',
                          padding:
                              EdgeInsets.zero,
                          onSelected:
                              (value) {
                            if (value ==
                                'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditPostScreen(
                                    post: post,
                                  ),
                                ),
                              );
                            } else if (value ==
                                'returned') {
                              _markItemReturned(
                                context,
                                post,
                              );
                            } else if (value ==
                                'delete') {
                              _deletePost(
                                context,
                                postId,
                                itemName,
                              );
                            }
                          },
                          itemBuilder:
                              (context) => [
                            // EDIT
                            if (!isCompleted)
                              const PopupMenuItem<
                                  String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .edit_outlined,
                                      color:
                                          AppColors.primaryBlue,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Edit',
                                    ),
                                  ],
                                ),
                              ),

                            // ITEM RETURNED
                            if (!isCompleted &&
                                !recoveryPending)
                              const PopupMenuItem<
                                  String>(
                                value:
                                    'returned',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .check_circle_outline,
                                      color:
                                          AppColors.success,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Item Returned',
                                    ),
                                  ],
                                ),
                              ),

                            // DELETE
                            if (!isCompleted)
                              const PopupMenuItem<
                                  String>(
                                value:
                                    'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delete_outline,
                                      color:
                                          AppColors.error,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Delete',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // CATEGORY
                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              AppColors.secondaryText,
                        ),
                      ),

                    // LOCATION
                    if (location.isNotEmpty) ...[
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .location_on_outlined,
                            size: 16,
                            color:
                                AppColors.secondaryText,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
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

                    // DESCRIPTION
                    if (description
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color:
                              AppColors.secondaryText,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 10,
                    ),

                    // BOTTOM STATUS
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
                                color: Colors
                                    .green
                                    .shade600,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Colors
                                      .green
                                      .shade700,
                                ),
                              ),
                            ],
                          )
                        else if (recoveryPending)
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .hourglass_top_rounded,
                                size: 17,
                                color: Colors
                                    .orange
                                    .shade700,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Return Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Colors
                                      .orange
                                      .shade800,
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
                              color: Colors
                                  .grey
                                  .shade600,
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
                                color: Colors
                                    .teal
                                    .shade700,
                              ),
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                            Icon(
                              Icons
                                  .arrow_forward_ios,
                              size: 12,
                              color: Colors
                                  .teal
                                  .shade700,
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
    bool recoveryPending,
  ) {
    if (isCompleted) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration:
            BoxDecoration(
          color: AppColors.successSoft,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          'COMPLETED',
          style: TextStyle(
            fontSize: 9,
            fontWeight:
                FontWeight.bold,
            color:
                AppColors.success,
          ),
        ),
      );
    }

    if (recoveryPending) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration:
            BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          'RETURN PENDING',
          style: TextStyle(
            fontSize: 9,
            fontWeight:
                FontWeight.bold,
            color:
                AppColors.warning,
          ),
        ),
      );
    }

    final bool isLost =
        postType == 'Lost';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color: isLost
            ? AppColors.warningSoft
            : AppColors.successSoft,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
          color: isLost
              ? AppColors.warning
              : AppColors.success,
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
              ? Colors.white.withValues(
                  alpha: 0.35,
                )
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
            ? AppColors.successSoft
            : AppColors.card,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        isCompleted
            ? Icons.check_circle_outline
            : Icons.image_outlined,
        size: 38,
        color: isCompleted
            ? AppColors.mutedText
            : AppColors.secondaryText,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color:
                  AppColors.secondaryText,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'No Items Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Posts you create will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    AppColors.secondaryText,
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
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .account_circle_outlined,
              size: 64,
              color:
                  AppColors.secondaryText,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Please Log In',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'You need to be logged in to view your items.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppColors.secondaryText,
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
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 60,
              color:
                  AppColors.error,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Unable to load your items',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Please check your connection and try again.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}