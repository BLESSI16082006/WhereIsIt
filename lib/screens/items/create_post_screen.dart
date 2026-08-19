import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirestorePostService _postService = FirestorePostService();

  final TextEditingController _itemNameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _rewardController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  String _postType = 'Lost';

  String? _category;
  String? _location;
  DateTime? _selectedDate;

  bool _imageSelected = false;
  bool _isCreating = false;

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

    // Automatically use the logged-in user's email.
    final User? user = FirebaseAuth.instance.currentUser;

    if (user?.email != null) {
      _emailController.text = user!.email!;
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

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
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
  // CREATE POST
  // ------------------------------------------------------------

  Future<void> _createPost() async {
    // Prevent double tapping.
    if (_isCreating) {
      return;
    }

    // Validate normal form fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Category validation.
    if (_category == null) {
      _showMessage('Please select an item category.');
      return;
    }

    // Location validation.
    if (_location == null) {
      _showMessage('Please select the location.');
      return;
    }

    // Date validation.
    if (_selectedDate == null) {
      _showMessage('Please select the date.');
      return;
    }

    // Found posts require an image.
    if (_postType == 'Found' && !_imageSelected) {
      _showMessage(
        'Please add an image for a found item.',
      );
      return;
    }

    // Valuable items require at least 50 characters.
    if (_category == 'Valuable Items' &&
        _descriptionController.text.trim().length < 50) {
      _showMessage(
        'For valuable items, please provide at least 50 characters in the description.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    final User? firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _showMessage(
        'Please log in before creating a post.',
      );
      return;
    }

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isCreating = true;
    });

    try {
      // Currently there is no real image upload connected.
      // Cloudinary image upload can be connected later.
      const String imageUrl = '';

      // Save post to Firestore.
      final String postId = await _postService.createPost(
        userId: firebaseUser.uid,
        postType: _postType,
        category: _category!,
        itemName: _itemNameController.text.trim(),
        date: _selectedDate!,
        location: _location!,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        description: _descriptionController.text.trim(),
        reward: _rewardController.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post created successfully.\nPost ID: $postId',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to previous screen.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      debugPrint('CREATE POST ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create post.\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
    final bool isFound = _postType == 'Found';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // POST TYPE
                // ------------------------------------------------

                const Text(
                  'What do you want to report?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildPostTypeButton(
                        title: 'Lost Item',
                        icon: Icons.search_off_rounded,
                        value: 'Lost',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPostTypeButton(
                        title: 'Found Item',
                        icon: Icons.search_rounded,
                        value: 'Found',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // CATEGORY
                // ------------------------------------------------

                _buildSectionTitle(
                  'Item Category',
                  'Select the category that best describes your item.',
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: _isCreating
                      ? null
                      : (value) {
                          setState(() {
                            _category = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // ITEM DETAILS
                // ------------------------------------------------

                _buildSectionTitle(
                  'Item Details',
                  'Enter the basic information about the item.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _itemNameController,
                  enabled: !_isCreating,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'Example: Gold Ring',
                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
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
                  onTap: _isCreating ? null : _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : _formatDate(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey.shade600
                            : Colors.black,
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
                  decoration: InputDecoration(
                    labelText: 'Location',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: _isCreating
                      ? null
                      : (value) {
                          setState(() {
                            _location = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a location.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // CONTACT INFORMATION
                // ------------------------------------------------

                _buildSectionTitle(
                  'Contact Information',
                  'These details help other users contact you.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneController,
                  enabled: !_isCreating,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your phone number.';
                    }

                    if (value.trim().length < 10) {
                      return 'Please enter a valid phone number.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  enabled: !_isCreating,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
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
                  'Optional for lost items.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _rewardController,
                  enabled: !_isCreating,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Reward (Optional)',
                    hintText: 'Example: 500',
                    prefixIcon: const Icon(
                      Icons.card_giftcard_outlined,
                    ),
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // IMAGE
                // ------------------------------------------------

                _buildSectionTitle(
                  'Item Image',
                  isFound
                      ? 'Image is required for found items.'
                      : 'Image is optional for lost items.',
                ),

                const SizedBox(height: 10),

                _buildImagePicker(),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                _buildSectionTitle(
                  'Description',
                  _category == 'Valuable Items'
                      ? 'At least 50 characters are required for valuable items.'
                      : 'Provide useful details such as colour, brand, size, or unique features.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isCreating,
                  minLines: 5,
                  maxLines: 8,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Describe the item in detail...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a description.';
                    }

                    if (_category == 'Valuable Items' &&
                        value.trim().length < 50) {
                      return 'Please provide at least 50 characters.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // CREATE BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isCreating ? null : _createPost,
                    icon: _isCreating
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
                            Icons.add_circle_outline,
                          ),
                    label: Text(
                      _isCreating
                          ? 'Creating Post...'
                          : 'Create Post',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Please make sure all information is accurate before creating your post.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // POST TYPE BUTTON
  // ------------------------------------------------------------

  Widget _buildPostTypeButton({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final bool selected = _postType == value;

    return InkWell(
      onTap: _isCreating
          ? null
          : () {
              setState(() {
                _postType = value;
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.teal.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.teal.shade600
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? Colors.teal.shade700
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: selected
                    ? Colors.teal.shade800
                    : Colors.grey.shade700,
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
  // IMAGE PICKER
  // ------------------------------------------------------------

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _isCreating
          ? null
          : () {
              // Temporary demonstration.
              // Real image picker + Cloudinary upload
              // will be connected in the image module.
              setState(() {
                _imageSelected = true;
              });

              _showMessage(
                'Image selected for demonstration. Real image upload will be connected later.',
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageSelected
                ? Colors.green.shade400
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              _imageSelected
                  ? Icons.check_circle_outline
                  : Icons.add_photo_alternate_outlined,
              size: 42,
              color: _imageSelected
                  ? Colors.green.shade600
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 10),
            Text(
              _imageSelected
                  ? 'Image Selected'
                  : 'Tap to Add Image',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _imageSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _postType == 'Found'
                  ? 'Required'
                  : 'Optional',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}