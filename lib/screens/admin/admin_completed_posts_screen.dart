import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCompletedPostsScreen extends StatefulWidget {
  const AdminCompletedPostsScreen({super.key});

  @override
  State<AdminCompletedPostsScreen> createState() =>
      _AdminCompletedPostsScreenState();
}

class _AdminCompletedPostsScreenState
    extends State<AdminCompletedPostsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _getCompletedPosts() {
    return _firestore
        .collection('posts')
        .where(
          'isCompleted',
          isEqualTo: true,
        )
        .snapshots();
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final String itemName =
        data['itemName']?.toString().toLowerCase() ?? '';

    final String category =
        data['category']?.toString().toLowerCase() ?? '';

    final String location =
        data['location']?.toString().toLowerCase() ?? '';

    final String description =
        data['description']?.toString().toLowerCase() ?? '';

    final String email =
        data['email']?.toString().toLowerCase() ?? '';

    final String phone =
        data['phone']?.toString().toLowerCase() ?? '';

    final String userId =
        data['userId']?.toString().toLowerCase() ?? '';

    final String postType =
        data['postType']?.toString().toLowerCase() ?? '';

    final String recoveryStatus =
        data['recoveryStatus']?.toString().toLowerCase() ?? '';

    return itemName.contains(_searchText) ||
        category.contains(_searchText) ||
        location.contains(_searchText) ||
        description.contains(_searchText) ||
        email.contains(_searchText) ||
        phone.contains(_searchText) ||
        userId.contains(_searchText) ||
        postType.contains(_searchText) ||
        recoveryStatus.contains(_searchText);
  }

  String _getDateText(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return value.toString();
  }

  String _getImageUrl(
    Map<String, dynamic> data,
  ) {
    final dynamic imageUrl = data['imageUrl'];

    if (imageUrl != null &&
        imageUrl.toString().trim().isNotEmpty) {
      return imageUrl.toString();
    }

    final dynamic images = data['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  Future<void> _deletePost(
    BuildContext context,
    String postId,
    String itemName,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Completed Post',
          ),
          content: Text(
            'Are you sure you want to permanently delete '
            'the completed post "$itemName"?\n\n'
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
                backgroundColor:
                    AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completed post deleted successfully.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Permission denied. Update Firestore rules for admin deletion.'
                : 'Unable to delete the completed post.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the completed post.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImage(
    BuildContext context,
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    );
                  },
                  loadingBuilder:
                      (_, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostDetails(
    BuildContext context,
    String postId,
    Map<String, dynamic> data,
  ) {
    final String itemName =
        data['itemName']?.toString() ??
            'Unknown Item';

    final String category =
        data['category']?.toString() ??
            'Not available';

    final String postType =
        data['postType']?.toString() ??
            'Not available';

    final String location =
        data['location']?.toString() ??
            'Not available';

    final String phone =
        data['phone']?.toString() ??
            'Not available';

    final String email =
        data['email']?.toString() ??
            'Not available';

    final String description =
        data['description']?.toString() ??
            'No description provided.';

    final String userId =
        data['userId']?.toString() ??
            'Not available';

    final String recoveryStatus =
        data['recoveryStatus']?.toString() ??
            'Completed';

    final String status =
        data['status']?.toString() ??
            'Completed';

    final String date = _getDateText(
      data['completedDate'] ??
          data['recoveredDate'] ??
          data['recoveryDate'] ??
          data['updatedAt'] ??
          data['createdAt'],
    );

    final String originalDate =
        _getDateText(
      data['lostDate'] ??
          data['foundDate'] ??
          data['date'] ??
          data['createdAt'],
    );

    final String reward =
        data['reward']?.toString() ??
            data['rewardAmount']?.toString() ??
            'None';

    final bool isCompleted =
        data['isCompleted'] == true;

    final String imageUrl =
        _getImageUrl(data);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
              maxHeight: 780,
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Completed Post Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (imageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          dialogContext,
                        );

                        _showImage(
                          context,
                          imageUrl,
                        );
                      },
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return Container(
                              height: 220,
                              color:
                                  AppColors.border,
                              child:
                                  const Icon(
                                Icons
                                    .broken_image_outlined,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.card,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .image_not_supported_outlined,
                            size: 45,
                            color: AppColors.secondaryText,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No image available',
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.successSoft,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color:
                            AppColors.successBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .check_circle_outline,
                          color:
                              AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'This post has been marked as completed/recovered.',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _detailRow(
                    'Item Name',
                    itemName,
                  ),

                  _detailRow(
                    'Category',
                    category,
                  ),

                  _detailRow(
                    'Post Type',
                    postType,
                  ),

                  _detailRow(
                    'Original Date',
                    originalDate,
                  ),

                  _detailRow(
                    'Completed Date',
                    date,
                  ),

                  _detailRow(
                    'Location',
                    location,
                  ),

                  _detailRow(
                    'Phone',
                    phone,
                  ),

                  _detailRow(
                    'Email',
                    email,
                  ),

                  _detailRow(
                    'Reward',
                    reward,
                  ),

                  _detailRow(
                    'Status',
                    status,
                  ),

                  _detailRow(
                    'Recovery Status',
                    recoveryStatus,
                  ),

                  _detailRow(
                    'Completed',
                    isCompleted
                        ? 'Yes'
                        : 'No',
                  ),

                  _detailRow(
                    'User ID',
                    userId,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.card,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Post ID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  SelectableText(
                    postId,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.primaryText,
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                        );

                        _deletePost(
                          context,
                          postId,
                          itemName,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text(
                        'Delete Completed Post',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.error,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color:
                    AppColors.secondaryText,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    String postId,
    Map<String, dynamic> data,
  ) {
    final String itemName =
        data['itemName']?.toString() ??
            'Unknown Item';

    final String category =
        data['category']?.toString() ??
            'Unknown Category';

    final String postType =
        data['postType']?.toString() ??
            'Unknown';

    final String location =
        data['location']?.toString() ??
            'Unknown Location';

    final String date =
        _getDateText(
      data['completedDate'] ??
          data['recoveredDate'] ??
          data['recoveryDate'] ??
          data['updatedAt'],
    );

    final String imageUrl =
        _getImageUrl(data);

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _showPostDetails(
            context,
            postId,
            data,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showImage(
                    context,
                    imageUrl,
                  );
                },
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _imagePlaceholder();
                          },
                        )
                      : _imagePlaceholder(),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: postType
                                    .toLowerCase() ==
                                'lost'
                                ? Colors
                                    .orange.shade50
                                : Colors
                                    .purple.shade50,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            postType,
                            style: TextStyle(
                              color: postType
                                      .toLowerCase() ==
                                  'lost'
                                  ? AppColors.warning
                                  : Colors.purple
                                      .shade800,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors
                                  .grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,
                          size: 15,
                          color:
                              AppColors.secondaryText,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Completed: $date',
                      style: TextStyle(
                        color:
                            AppColors.success,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.successSoft,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          color:
                              AppColors.success,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 82,
      height: 82,
      color: AppColors.card,
      child: const Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: 34,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,
        foregroundColor: Colors.white,
        title: const Text(
          'Completed Posts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              12,
            ),
            color: AppColors.card,
            child: TextField(
              controller:
                  _searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search completed posts...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                            },
                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,
                filled: true,
                fillColor:
                    AppColors.card,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _getCompletedPosts(),
              builder:
                  (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        'Unable to load completed posts.\n\n'
                        '${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                final filteredDocs =
                    docs.where((doc) {
                  return _matchesSearch(
                    doc.data(),
                  );
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .check_circle_outline,
                            size: 70,
                            color: Colors
                                .green.shade300,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            _searchText.isEmpty
                                ? 'No completed posts yet'
                                : 'No matching completed posts',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            _searchText.isEmpty
                                ? 'Recovered items will appear here.'
                                : 'Try a different search term.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  itemCount:
                      filteredDocs.length,
                  itemBuilder:
                      (context, index) {
                    final doc =
                        filteredDocs[index];

                    return _buildPostCard(
                      context,
                      doc.id,
                      doc.data(),
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