import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() =>
      _SearchFilterScreenState();
}

class _SearchFilterScreenState
    extends State<SearchFilterScreen> {
  final TextEditingController _keywordController =
      TextEditingController();

  String? _selectedLocation;

  final List<String> _locations = [
    'All Locations',
    'Nagercoil',
    'Marthandam',
    'Thuckalay',
    'Colachel',
    'Kuzhithurai',
    'Karungal',
    'Kanyakumari',
  ];

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // APPLY FILTER
  // ------------------------------------------------------------

  void _applyFilter() {
    final String keyword =
        _keywordController.text.trim();

    final String location =
        _selectedLocation ?? 'All Locations';

    Navigator.pop(
      context,
      {
        'keyword': keyword,
        'location': location,
      },
    );
  }

  // ------------------------------------------------------------
  // CLEAR FILTER
  // ------------------------------------------------------------

  void _clearFilter() {
    setState(() {
      _keywordController.clear();
      _selectedLocation = null;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Filter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilter,
            child: const Text('Clear'),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ------------------------------------------------------
            // HEADER
            // ------------------------------------------------------

            const Text(
              'Find Lost & Found Items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Use keywords and location to narrow down '
              'the items you are looking for.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------------
            // KEYWORD
            // ------------------------------------------------------

            const Text(
              'Keyword',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _keywordController,
              textInputAction:
                  TextInputAction.search,

              decoration: InputDecoration(
                hintText:
                    'Search e.g. gold, phone, Aadhaar',
                prefixIcon: const Icon(
                  Icons.search,
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.border,
                  ),
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------------
            // LOCATION
            // ------------------------------------------------------

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedLocation,

              decoration: InputDecoration(
                hintText: 'Select location',

                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.border,
                  ),
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
              ),

              items: _locations.map(
                (String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                },
              ).toList(),

              onChanged: (String? value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // ------------------------------------------------------
            // FILTER INFORMATION
            // ------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blueSoft,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'You can search using an item name '
                      'or keyword and optionally select '
                      'a location.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ------------------------------------------------------
            // APPLY BUTTON
            // ------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed: _applyFilter,

                icon: const Icon(
                  Icons.filter_alt_outlined,
                ),

                label: const Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryBlue,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------
            // RESET BUTTON
            // ------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton(
                onPressed: _clearFilter,

                style:
                    OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}