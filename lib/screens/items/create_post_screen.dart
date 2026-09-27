import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

import '../../services/firestore_post_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/ocr_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirestorePostService _postService = FirestorePostService();

  final ImagePicker _imagePicker = ImagePicker();

  final OcrService _ocrService = OcrService();

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

  // ============================================================
  // VALUABLE ITEM VERIFICATION
  // ============================================================

  final List<TextEditingController> _verificationControllers =
      List.generate(5, (_) => TextEditingController());

  final List<String> _verificationQuestions = [
    'What is the main color of the item?',
    'What is the brand or model of the item?',
    'What is one unique feature of the item?',
    'Does the item have any mark, scratch, sticker, case, engraving, or other identifying detail?',
    'Describe one additional detail that can prove the item belongs to you.',
  ];

  bool _isCreating = false;
  bool _isUploadingImage = false;

  String _postType = 'Lost';
  String _ocrText = '';

  String? _category;
  String? _location;
  DateTime? _selectedDate;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final User? user = FirebaseAuth.instance.currentUser;

    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _itemNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rewardController.dispose();
    _descriptionController.dispose();

    for (final controller in _verificationControllers) {
      controller.dispose();
    }

    _ocrService.dispose();

    super.dispose();
  }

  // ============================================================
  // VERIFICATION HELPERS
  // ============================================================

  String _normalizeAnswer(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _hashAnswer(String answer) {
    return sha256
        .convert(
          utf8.encode(_normalizeAnswer(answer)),
        )
        .toString();
  }

  Future<void> _saveValuableVerificationAnswers({
    required String postId,
    required String userId,
  }) async {
    final List<String> answers = _verificationControllers
        .map((controller) => controller.text.trim())
        .toList();

    final List<String> answerHashes =
        answers.map(_hashAnswer).toList();

    await FirebaseFirestore.instance
        .collection('post_verification')
        .doc(postId)
        .set({
      'postId': postId,
      'userId': userId,
      'answerHashes': answerHashes,
      'questionCount': 5,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool get _isValuableFoundPost {
    return _postType == 'Found' &&
        _category == 'Valuable Items';
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    if (_isCreating || _isUploadingImage) {
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _ocrText = '';
      });

      // ==========================================================
      // OCR
      // ==========================================================
      //
      // Google ML Kit OCR is supported on Android/iOS.
      // It is NOT supported on Chrome/Web.
      //
      // Therefore, skip OCR when running on Web.
      // ==========================================================

      if (!kIsWeb) {
        if (mounted) {
          setState(() {
            _isUploadingImage = true;
          });
        }

        try {
          final String extractedText =
              await _ocrService.extractTextFromPath(
            image.path,
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _ocrText = extractedText;
          });

          if (extractedText.isNotEmpty) {
            _showMessage(
              'Text detected from image.',
            );
          } else {
            _showMessage(
              'No readable text found in image.',
            );
          }
        } catch (e) {
          if (!mounted) {
            return;
          }

          setState(() {
            _ocrText = '';
          });

          debugPrint('OCR error: $e');

          _showMessage(
            'Image selected, but OCR could not read text.',
          );
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingImage = false;
            });
          }
        }
      } else {
        // ========================================================
        // CHROME / WEB
        // ========================================================

        if (mounted) {
          setState(() {
            _ocrText = '';
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage() {
    if (_isCreating || _isUploadingImage) {
      return;
    }

    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _ocrText = '';
    });
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    if (_isCreating) {
      return;
    }

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

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> _createPost() async {
    if (_isCreating) {
      return;
    }

    if (_isUploadingImage) {
      _showMessage(
        'Please wait until image processing is finished.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_category == null) {
      _showMessage(
        'Please select an item category.',
      );
      return;
    }

    if (_location == null) {
      _showMessage(
        'Please select the location.',
      );
      return;
    }

    if (_selectedDate == null) {
      _showMessage(
        'Please select the date.',
      );
      return;
    }

    // ==========================================================
    // FOUND ITEMS REQUIRE IMAGE
    // ==========================================================

    if (_postType == 'Found' &&
        _selectedImageBytes == null) {
      _showMessage(
        'Please add an image for a found item.',
      );
      return;
    }

    // ==========================================================
    // VALUABLE ITEMS DESCRIPTION
    // ==========================================================

    if (_category == 'Valuable Items' &&
        _descriptionController.text.trim().length < 50) {
      _showMessage(
        'For valuable items, please provide at least 50 characters.',
      );
      return;
    }

    // ==========================================================
    // VALUABLE FOUND VERIFICATION ANSWERS
    // ==========================================================

    if (_isValuableFoundPost) {
      for (int i = 0;
          i < _verificationControllers.length;
          i++) {
        if (_verificationControllers[i]
            .text
            .trim()
            .isEmpty) {
          _showMessage(
            'Please answer all 5 ownership verification questions.',
          );
          return;
        }
      }
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in before creating a post.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // ========================================================
      // STEP 1
      // CREATE FIRESTORE POST
      // ========================================================

      final String postId =
          await _postService.createPost(
        userId: user.uid,
        postType: _postType,
        category: _category!,
        itemName:
            _itemNameController.text.trim(),
        date: _selectedDate!,
        location: _location!,
        phone:
            _phoneController.text.trim(),
        email:
            _emailController.text.trim(),
        description:
            _descriptionController.text.trim(),
        reward:
            _rewardController.text.trim(),
        ocrText: _ocrText,
      );

      // ========================================================
      // STEP 2
      // UPLOAD IMAGE TO CLOUDINARY
      // ========================================================

      if (_selectedImageBytes != null) {
        final String imageUrl =
            await CloudinaryService.uploadImage(
          imageBytes:
              _selectedImageBytes!,
          fileName:
              '${user.uid}_$postId.jpg',
        );

        // ======================================================
        // STEP 3
        // SAVE CLOUDINARY URL IN FIRESTORE
        // ======================================================

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'imageUrl': imageUrl,
          'imageStorage': 'cloudinary',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      // ========================================================
      // STEP 4
      // SAVE VALUABLE OWNER VERIFICATION ANSWERS
      // ========================================================

      if (_isValuableFoundPost) {
        await _saveValuableVerificationAnswers(
          postId: postId,
          userId: user.uid,
        );

        // Mark verification as waiting for an owner.
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
          'ownerVerified': false,
          'verificationStatus': 'pending',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      _showMessage(
        _isValuableFoundPost
            ? 'Found valuable item posted with owner verification.'
            : _selectedImageBytes != null
                ? 'Post created and image uploaded successfully.'
                : 'Post created successfully.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to create post.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isFound =
        _postType == 'Found';

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
            padding:
                const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // POST TYPE
                // ==================================================

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
                      child:
                          _buildPostTypeButton(
                        title: 'Lost Item',
                        icon:
                            Icons.search_off_rounded,
                        value: 'Lost',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          _buildPostTypeButton(
                        title: 'Found Item',
                        icon:
                            Icons.search_rounded,
                        value: 'Found',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // CATEGORY
                // ==================================================

                _buildSectionTitle(
                  'Item Category',
                  'Select the category that best describes your item.',
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration:
                      InputDecoration(
                    labelText: 'Category',
                    prefixIcon:
                        const Icon(
                      Icons.category_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  items:
                      _categories.map(
                    (category) {
                      return DropdownMenuItem<
                          String>(
                        value: category,
                        child:
                            Text(category),
                      );
                    },
                  ).toList(),
                  onChanged: _isCreating
                      ? null
                      : (value) {
                          setState(() {
                            _category =
                                value;
                          });
                        },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a category.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // ITEM DETAILS
                // ==================================================

                _buildSectionTitle(
                  'Item Details',
                  'Enter the basic information about the item.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _itemNameController,
                  enabled: !_isCreating,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      InputDecoration(
                    labelText: 'Item Name',
                    hintText:
                        'Example: Gold Ring',
                    prefixIcon:
                        const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    border:
                        OutlineInputBorder(
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

                // ==================================================
                // DATE
                // ==================================================

                InkWell(
                  onTap: _isCreating
                      ? null
                      : _selectDate,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  child: InputDecorator(
                    decoration:
                        InputDecoration(
                      labelText: 'Date',
                      prefixIcon:
                          const Icon(
                        Icons
                            .calendar_today_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : _formatDate(
                              _selectedDate!,
                            ),
                      style: TextStyle(
                        color:
                            _selectedDate ==
                                    null
                                ? Colors
                                    .grey
                                    .shade600
                                : Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LOCATION
                // ==================================================

                DropdownButtonFormField<String>(
                  initialValue: _location,
                  decoration:
                      InputDecoration(
                    labelText: 'Location',
                    prefixIcon:
                        const Icon(
                      Icons
                          .location_on_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  items:
                      _locations.map(
                    (location) {
                      return DropdownMenuItem<
                          String>(
                        value: location,
                        child:
                            Text(location),
                      );
                    },
                  ).toList(),
                  onChanged: _isCreating
                      ? null
                      : (value) {
                          setState(() {
                            _location =
                                value;
                          });
                        },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a location.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // CONTACT INFORMATION
                // ==================================================

                _buildSectionTitle(
                  'Contact Information',
                  'These details help other users contact you.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _phoneController,
                  enabled: !_isCreating,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Phone Number',
                    prefixIcon:
                        const Icon(
                      Icons.phone_outlined,
                    ),
                    border:
                        OutlineInputBorder(
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
                  enabled: !_isCreating,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration:
                      InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        const Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(
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

                // ==================================================
                // REWARD
                // ==================================================

                _buildSectionTitle(
                  'Reward',
                  'Optional for lost items.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _rewardController,
                  enabled: !_isCreating,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        'Reward (Optional)',
                    hintText: 'Example: 500',
                    prefixIcon:
                        const Icon(
                      Icons
                          .card_giftcard_outlined,
                    ),
                    prefixText: '₹ ',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // IMAGE
                // ==================================================

                _buildSectionTitle(
                  'Item Image',
                  isFound
                      ? 'Image is required for found items.'
                      : 'Image is optional for lost items.',
                ),

                const SizedBox(height: 10),

                _buildImagePicker(),

                // ==================================================
                // OCR STATUS
                // ==================================================

                if (_isUploadingImage)
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reading text from image...',
                        ),
                      ],
                    ),
                  )
                else if (_ocrText.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color:
                              Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Text detected from image.',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                _buildSectionTitle(
                  'Description',
                  _category ==
                          'Valuable Items'
                      ? 'At least 50 characters are required for valuable items.'
                      : 'Provide useful details such as colour, brand, size, or unique features.',
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller:
                      _descriptionController,
                  enabled: !_isCreating,
                  minLines: 5,
                  maxLines: 8,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Describe the item in detail...',
                    alignLabelWithHint: true,
                    border:
                        OutlineInputBorder(
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

                // ==================================================
                // OWNER VERIFICATION
                // ONLY FOR FOUND + VALUABLE ITEMS
                // ==================================================

                if (_isValuableFoundPost) ...[
                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Owner Verification',
                    'Create 5 questions that a genuine owner should be able to answer.',
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors
                          .teal
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: Colors
                            .teal
                            .withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons
                              .verified_user_outlined,
                          color: Colors.teal,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These answers will be used later to verify whether someone is the genuine owner. Do not enter information that is publicly visible in your post.',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  ...List.generate(
                    5,
                    (index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: TextFormField(
                          controller:
                              _verificationControllers[
                                  index],
                          enabled: !_isCreating,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Answer ${index + 1}',
                            hintText:
                                _verificationQuestions[
                                    index],
                            prefixIcon:
                                CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Colors.teal.shade100,
                              child: Text(
                                '${index + 1}',
                                style:
                                    TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Colors.teal.shade800,
                                ),
                              ),
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 30),

                // ==================================================
                // CREATE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child:
                      ElevatedButton.icon(
                    onPressed: (_isCreating ||
                            _isUploadingImage)
                        ? null
                        : _createPost,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .add_circle_outline,
                          ),
                    label: _isCreating
                        ? const Text(
                            'Creating Post...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Create Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Please make sure all information is accurate before creating your post.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
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

  // ============================================================
  // POST TYPE BUTTON
  // ============================================================

  Widget _buildPostTypeButton({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final bool selected =
        _postType == value;

    return InkWell(
      onTap: (_isCreating ||
              _isUploadingImage)
          ? null
          : () {
              setState(() {
                _postType = value;
              });
            },
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.teal.shade50
              : Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
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
              textAlign:
                  TextAlign.center,
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

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

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _buildImagePicker() {
    final bool isFound =
        _postType == 'Found';

    return InkWell(
      onTap: (_isCreating ||
              _isUploadingImage)
          ? null
          : _pickImage,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedImageBytes != null
                    ? Colors.green.shade400
                    : Colors.grey.shade300,
            width:
                _selectedImageBytes != null
                    ? 2
                    : 1,
          ),
        ),
        child: _selectedImageBytes ==
                null
            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .add_photo_alternate_outlined,
                    size: 44,
                    color:
                        Colors.grey.shade600,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Tap to Add Image',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    isFound
                        ? 'Required'
                        : 'Optional',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFound
                          ? Colors
                              .red
                              .shade600
                          : Colors
                              .grey
                              .shade500,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                    ),

                    // Remove button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor:
                            Colors.black
                                .withValues(
                          alpha: 0.65,
                        ),
                        child:
                            IconButton(
                          onPressed:
                              _isUploadingImage
                                  ? null
                                  : _removeImage,
                          icon:
                              const Icon(
                            Icons.close,
                            color:
                                Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Image filename
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(8),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .black
                              .withValues(
                            alpha: 0.65,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                        child: Text(
                          _selectedImageName ??
                              'Image selected',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}