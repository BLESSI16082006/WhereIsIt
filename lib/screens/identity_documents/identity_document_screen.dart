import 'package:flutter/material.dart';

class IdentityDocumentScreen extends StatefulWidget {
  const IdentityDocumentScreen({super.key});

  @override
  State<IdentityDocumentScreen> createState() =>
      _IdentityDocumentScreenState();
}

class _IdentityDocumentScreenState
    extends State<IdentityDocumentScreen> {
  String _postType = 'Lost';
  String? _selectedDocument;

  final List<String> _documentTypes = [
    'Aadhaar Card',
    'Voter ID',
    'Passport',
    'ATM Card',
    'Smart Card',
    'Passbook',
    'Certificate',
    'Mark Sheet',
    'Other Identity Document',
  ];

  final TextEditingController _itemNameController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  @override
  void dispose() {
    _itemNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------

  void _submitPost() {
    if (_selectedDocument == null ||
        _itemNameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Identity document post is ready. '
          'Database connection will be added next.',
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
      appBar: AppBar(
        title: const Text(
          'Identity Documents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // INTRODUCTION
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.teal.shade700,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report a lost or found identity '
                        'document. Provide accurate details '
                        'to help identify the rightful owner.',
                        style: TextStyle(
                          color: Colors.teal.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // POST TYPE
              // --------------------------------------------------

              const Text(
                'Post Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildPostTypeButton(
                      title: 'Lost',
                      icon: Icons.search_off_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPostTypeButton(
                      title: 'Found',
                      icon: Icons.search_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // DOCUMENT TYPE
              // --------------------------------------------------

              const Text(
                'Document Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedDocument,
                decoration: InputDecoration(
                  hintText: 'Select document type',
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                items: _documentTypes.map(
                  (document) {
                    return DropdownMenuItem<String>(
                      value: document,
                      child: Text(document),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDocument = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // ITEM NAME
              // --------------------------------------------------

              _buildTextField(
                controller: _itemNameController,
                label: 'Document / Item Name',
                hint: 'Example: Aadhaar Card',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // LOCATION
              // --------------------------------------------------

              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'Example: Nagercoil',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // PHONE
              // --------------------------------------------------

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter contact number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // EMAIL
              // --------------------------------------------------

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter email address',
                icon: Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // DESCRIPTION
              // --------------------------------------------------

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint:
                    'Enter useful details about the document...',
                icon: Icons.notes_outlined,
                maxLines: 5,
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // IMAGE PLACEHOLDER
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 42,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Document Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Image selection will be connected '
                      'in the next step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // SUBMIT BUTTON
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitPost,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
  // POST TYPE BUTTON
  // ------------------------------------------------------------

  Widget _buildPostTypeButton({
    required String title,
    required IconData icon,
  }) {
    final bool selected = _postType == title;

    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _postType = title;
        });
      },
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          double.infinity,
          50,
        ),
        backgroundColor:
            selected ? Colors.teal.shade50 : null,
        foregroundColor:
            selected ? Colors.teal.shade700 : null,
        side: BorderSide(
          color: selected
              ? Colors.teal.shade600
              : Colors.grey.shade300,
          width: selected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}