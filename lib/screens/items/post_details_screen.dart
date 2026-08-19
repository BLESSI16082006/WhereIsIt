import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  String _stringValue(String key) {
    final value = post[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String itemName = _stringValue('itemName');
    final String category = _stringValue('category');
    final String postType = _stringValue('postType');
    final String location = _stringValue('location');
    final String description = _stringValue('description');
    final String phone = _stringValue('phone');
    final String email = _stringValue('email');
    final String reward = _stringValue('reward');
    final String imageUrl = _stringValue('imageUrl');

    final bool isFound = postType.toLowerCase() == 'found';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // IMAGE
              // ------------------------------------------------

              _buildImageSection(
                imageUrl: imageUrl,
                itemName: itemName,
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // POST TYPE
              // ------------------------------------------------

              Row(
                children: [
                  _buildStatusChip(
                    label: postType.isEmpty ? 'Post' : postType,
                    icon: isFound
                        ? Icons.search_rounded
                        : Icons.search_off_rounded,
                    color: isFound
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // ITEM NAME
              // ------------------------------------------------

              Text(
                itemName.isEmpty ? 'Unnamed Item' : itemName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              if (category.isNotEmpty)
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // BASIC INFORMATION
              // ------------------------------------------------

              _buildSection(
                title: 'Item Information',
                icon: Icons.inventory_2_outlined,
                children: [
                  _buildInfoRow(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    value: category,
                  ),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    value: location,
                  ),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    value: _formatDate(post['date']),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------

              _buildSection(
                title: 'Description',
                icon: Icons.description_outlined,
                children: [
                  Text(
                    description.isEmpty
                        ? 'No description provided.'
                        : description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // REWARD
              // ------------------------------------------------

              if (reward.isNotEmpty)
                _buildSection(
                  title: 'Reward',
                  icon: Icons.card_giftcard_outlined,
                  children: [
                    Text(
                      '₹ $reward',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              if (reward.isNotEmpty) const SizedBox(height: 16),

              // ------------------------------------------------
              // CONTACT
              // ------------------------------------------------

              _buildSection(
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                children: [
                  if (phone.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: phone,
                    ),
                  if (email.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: email,
                    ),
                  if (phone.isEmpty && email.isEmpty)
                    Text(
                      'No contact information available.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // INFORMATION MESSAGE
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isFound
                            ? 'If this item belongs to you, use the available information to verify the item carefully.'
                            : 'If you found this item, compare the details carefully before contacting the person who reported it lost.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
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
  // IMAGE SECTION
  // ------------------------------------------------------------

  Widget _buildImageSection({
    required String imageUrl,
    required String itemName,
  }) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 230,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _buildImagePlaceholder(itemName);
          },
        ),
      );
    }

    return _buildImagePlaceholder(itemName);
  }

  Widget _buildImagePlaceholder(String itemName) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            itemName.isEmpty
                ? 'No image available'
                : 'No image available for $itemName',
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
  // SECTION
  // ------------------------------------------------------------

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO ROW
  // ------------------------------------------------------------

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS CHIP
  // ------------------------------------------------------------

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    DateTime? date;

    if (value is DateTime) {
      date = value;
    }

    // Firestore Timestamp
    if (value is dynamic && value.toString().contains('Timestamp')) {
      try {
        date = value.toDate();
      } catch (_) {
        // Ignore invalid date.
      }
    }

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}