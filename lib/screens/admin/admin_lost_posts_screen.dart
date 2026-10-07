import '../../core/theme/app_colors.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLostPostsScreen extends StatefulWidget {
  const AdminLostPostsScreen({super.key});

  @override
  State<AdminLostPostsScreen> createState() =>
      _AdminLostPostsScreenState();
}

class _AdminLostPostsScreenState
    extends State<AdminLostPostsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  static const Color primaryColor = AppColors.primaryBlue;
  static const Color accentColor = AppColors.primaryBlue;
  static const Color backgroundColor = AppColors.background;

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
      _getLostPosts() {
    return _firestore
        .collection('posts')
        .where('postType', isEqualTo: 'Lost')
        .snapshots();
  }

  String _readString(
    Map<String, dynamic> data,
    String field,
  ) {
    final dynamic value = data[field];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Not available';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final String itemName =
        _readString(data, 'itemName').toLowerCase();

    final String category =
        _readString(data, 'category').toLowerCase();

    final String location =
        _readString(data, 'location').toLowerCase();

    final String description =
        _readString(data, 'description').toLowerCase();

    final String email =
        _readString(data, 'email').toLowerCase();

    final String phone =
        _readString(data, 'phone').toLowerCase();

    return itemName.contains(_searchText) ||
        category.contains(_searchText) ||
        location.contains(_searchText) ||
        description.contains(_searchText) ||
        email.contains(_searchText) ||
        phone.contains(_searchText);
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
              'Search by item, category, location or contact',
          hintStyle: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: accentColor,
          ),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: accentColor,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String itemName =
        _readString(data, 'itemName').isEmpty
            ? 'Unnamed Item'
            : _readString(data, 'itemName');

    final String category =
        _readString(data, 'category').isEmpty
            ? 'Category not available'
            : _readString(data, 'category');

    final String location =
        _readString(data, 'location').isEmpty
            ? 'Location not available'
            : _readString(data, 'location');

    final String date =
        _formatDate(data['date']);

    final String imageUrl =
        _readString(data, 'imageUrl');

    final bool isCompleted =
        data['isCompleted'] == true;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showPostDetails(document);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _buildImagePreview(imageUrl),
              const SizedBox(width: 14),
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
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            margin:
                                const EdgeInsets.only(
                              left: 6,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              'COMPLETED',
                              style: TextStyle(
                                color:
                                    AppColors.success,
                                fontSize: 8,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: accentColor,
          size: 30,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  accentColor.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              color: accentColor,
              size: 30,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value.isEmpty
                  ? 'Not provided'
                  : value,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    final String postId = document.id;

    final String itemName =
        _readString(data, 'itemName');

    final String category =
        _readString(data, 'category');

    final String location =
        _readString(data, 'location');

    final String date =
        _formatDate(data['date']);

    final String phone =
        _readString(data, 'phone');

    final String email =
        _readString(data, 'email');

    final String description =
        _readString(data, 'description');

    final String reward =
        _readString(data, 'reward');

    final String userId =
        _readString(data, 'userId');

    final String status =
        _readString(data, 'status');

    final String recoveryStatus =
        _readString(data, 'recoveryStatus');

    final String imageUrl =
        _readString(data, 'imageUrl');

    final bool isCompleted =
        data['isCompleted'] == true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              maxHeight: 720,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    20,
                    14,
                    18,
                  ),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lost Post Details',
                          style: TextStyle(
                            color: AppColors.card,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _showFullImage(
                                context,
                                imageUrl,
                              );
                            },
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return _buildLargeImageError();
                                },
                              ),
                            ),
                          ),
                        if (imageUrl.isNotEmpty)
                          const SizedBox(height: 18),
                        Text(
                          itemName.isEmpty
                              ? 'Unnamed Item'
                              : itemName,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            'LOST ITEM',
                            style: TextStyle(
                              color:
                                  AppColors.warning,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildDetailRow(
                          Icons.category_outlined,
                          'Category',
                          category,
                        ),
                        _buildDetailRow(
                          Icons.calendar_today_outlined,
                          'Lost Date',
                          date,
                        ),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'Location',
                          location,
                        ),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'Phone',
                          phone,
                        ),
                        _buildDetailRow(
                          Icons.email_outlined,
                          'Email',
                          email,
                        ),
                        _buildDetailRow(
                          Icons.card_giftcard_outlined,
                          'Reward',
                          reward.isEmpty
                              ? 'No reward'
                              : reward,
                        ),
                        _buildDetailRow(
                          Icons.circle_outlined,
                          'Status',
                          status.isEmpty
                              ? 'Not available'
                              : status,
                        ),
                        _buildDetailRow(
                          Icons.replay_outlined,
                          'Recovery',
                          recoveryStatus.isEmpty
                              ? 'Not started'
                              : recoveryStatus,
                        ),
                        _buildDetailRow(
                          Icons.check_circle_outline,
                          'Completed',
                          isCompleted
                              ? 'Yes'
                              : 'No',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                AppColors.card,
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: Text(
                            description.isEmpty
                                ? 'No description provided.'
                                : description,
                            style: TextStyle(
                              color:
                                  AppColors.primaryText,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Post Information',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'Post ID: $postId',
                          style: TextStyle(
                            color:
                                AppColors.primaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SelectableText(
                          'User ID: $userId',
                          style: TextStyle(
                            color:
                                AppColors.primaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                          label: const Text(
                            'Close',
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                primaryColor,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                            _confirmDeletePost(
                              document,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          label: const Text(
                            'Delete',
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.error,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLargeImageError() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: accentColor,
          size: 50,
        ),
      ),
    );
  }

  void _showFullImage(
    BuildContext context,
    String imageUrl,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(15),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.card,
                          size: 50,
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
                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePost(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    final String itemName =
        _readString(data, 'itemName').isEmpty
            ? 'this lost post'
            : _readString(data, 'itemName');

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Lost Post?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
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

    if (confirmed != true) {
      return;
    }

    await _deletePost(document.id);
  }

  Future<void> _deletePost(
    String postId,
  ) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .delete();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Lost post deleted successfully.',
        isError: false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message ??
            'Unable to delete the lost post.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete the lost post.',
        isError: true,
      );
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 70,
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: AppColors.card,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppColors.error
            : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lost Posts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              22,
            ),
            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost Item Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View and manage all reported lost items.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _getLostPosts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Unable to load lost posts',
                    message:
                        'There was a problem loading the lost item reports.',
                    icon: Icons.error_outline,
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  );
                }

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    documents =
                    snapshot.data?.docs ?? [];

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    filteredDocuments =
                    documents.where((document) {
                  return _matchesSearch(
                    document.data(),
                  );
                }).toList();

                filteredDocuments.sort(
                  (a, b) {
                    final dynamic aDate =
                        a.data()['date'];

                    final dynamic bDate =
                        b.data()['date'];

                    if (aDate is Timestamp &&
                        bDate is Timestamp) {
                      return bDate.compareTo(aDate);
                    }

                    return 0;
                  },
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        12,
                      ),
                      child: _buildSearchBar(),
                    ),
                    Expanded(
                      child: filteredDocuments.isEmpty
                          ? _buildEmptyState(
                              title: _searchText.isEmpty
                                  ? 'No lost posts'
                                  : 'No matching lost posts',
                              message: _searchText.isEmpty
                                  ? 'There are currently no lost item reports.'
                                  : 'Try a different search term.',
                              icon:
                                  Icons.search_off_outlined,
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                20,
                                4,
                                20,
                                25,
                              ),
                              itemCount:
                                  filteredDocuments.length,
                              itemBuilder:
                                  (context, index) {
                                return _buildPostCard(
                                  filteredDocuments[index],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
