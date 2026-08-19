import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_post_service.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() =>
      _EditPostScreenState();
}

class _EditPostScreenState
    extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirestorePostService _postService =
      FirestorePostService();

  late final TextEditingController _itemNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _rewardController;
  late final TextEditingController _descriptionController;

  late String _category;
  late String _location;
  late DateTime _selectedDate;

  bool _isSaving = false;

  final List<String> _categories = [
    'Identity Documents',
    'Valuable Items',
    'General Items',
  ];

  final List<String> _locations = [
    'Nagercoil',
    'Marthandam',
    'Thuckalay',
    'Kuzhithurai',
    'Colachel',
    'Kanyakumari',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _itemNameController = TextEditingController(
      text: widget.post['itemName']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.post['phone']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.post['email']?.toString() ?? '',
    );

    _rewardController = TextEditingController(
      text: widget.post['reward']?.toString() ?? '',
    );

    _descriptionController =
        TextEditingController(
      text:
          widget.post['description']?.toString() ?? '',
    );

    final String savedCategory =
        widget.post['category']?.toString() ?? '';

    _category = _categories.contains(savedCategory)
        ? savedCategory
        : _categories.first;

    final String savedLocation =
        widget.post['location']?.toString() ?? '';

    _location = _locations.contains(savedLocation)
        ? savedLocation
        : _locations.first;

    final dynamic dateValue =
        widget.post['date'];

    if (dateValue is Timestamp) {
      _selectedDate = dateValue.toDate();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rewardController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // SELECT DATE
  // ------------------------------------------------------------

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ------------------------------------------------------------
  // SAVE CHANGES
  // ------------------------------------------------------------

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_descriptionController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Please enter a description.',
      );
      return;
    }

    if (_category == 'Valuable Items' &&
        _descriptionController.text
                .trim()
                .length <
            50) {
      _showMessage(
        'Valuable items require at least 50 characters in the description.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String postId =
          widget.post['postId']?.toString() ?? '';

      if (postId.isEmpty) {
        throw Exception(
          'Post ID is missing.',
        );
      }

      await _postService.updatePost(
        postId: postId,
        data: {
          'category': _category,
          'itemName':
              _itemNameController.text.trim(),
          'date':
              Timestamp.fromDate(_selectedDate),
          'location': _location,
          'phone':
              _phoneController.text.trim(),
          'email':
              _emailController.text.trim(),
          'reward':
              _rewardController.text.trim(),
          'description':
              _descriptionController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update post. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final String postType =
        widget.post['postType']?.toString() ??
            'Lost';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // POST TYPE
                // ------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: postType == 'Lost'
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        postType == 'Lost'
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        color: postType == 'Lost'
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$postType Item',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: postType == 'Lost'
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Cannot be changed',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // CATEGORY
                // ------------------------------------------------

                _buildSectionTitle(
                  'Item Category',
                  'Select the category of your item.',
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration:
                      InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  items: _categories
                      .map(
                        (category) =>
                            DropdownMenuItem<
                                String>(
                          value: category,
                          child:
                              Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _category = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // ITEM NAME
                // ------------------------------------------------

                _buildSectionTitle(
                  'Item Details',
                  'Update the basic information.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _itemNameController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter the item name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // DATE
                // ------------------------------------------------

                InkWell(
                  onTap: _selectDate,
                  borderRadius:
                      BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration:
                        InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(
                        Icons
                            .calendar_today_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: Text(
                      _formatDate(
                        _selectedDate,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // LOCATION
                // ------------------------------------------------

                DropdownButtonFormField<String>(
                  initialValue: _location,
                  decoration:
                      InputDecoration(
                    labelText: 'Location',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  items: _locations
                      .map(
                        (location) =>
                            DropdownMenuItem<
                                String>(
                          value: location,
                          child:
                              Text(location),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _location = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // CONTACT
                // ------------------------------------------------

                _buildSectionTitle(
                  'Contact Information',
                  'Update your contact details.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your phone number.';
                    }

                    if (value.trim().length <
                        10) {
                      return 'Please enter a valid phone number.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }

                    if (!value.contains('@')) {
                      return 'Please enter a valid email.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // REWARD
                // ------------------------------------------------

                _buildSectionTitle(
                  'Reward',
                  'Update the optional reward.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _rewardController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Reward (Optional)',
                    prefixIcon: const Icon(
                      Icons
                          .card_giftcard_outlined,
                    ),
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                _buildSectionTitle(
                  'Description',
                  _category ==
                          'Valuable Items'
                      ? 'At least 50 characters are required.'
                      : 'Update useful item details.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _descriptionController,
                  minLines: 5,
                  maxLines: 8,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Describe the item...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a description.';
                    }

                    if (_category ==
                            'Valuable Items' &&
                        value.trim().length <
                            50) {
                      return 'Please provide at least 50 characters.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // SAVE BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save Changes',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your updated information will be saved to your post.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}