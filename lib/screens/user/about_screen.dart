import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --------------------------------------------------
            // APP LOGO
            // --------------------------------------------------

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.shade50,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 58,
                color: Colors.teal.shade700,
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // APP NAME
            // --------------------------------------------------

            const Text(
              'WhereIsIt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Lost & Found Service',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // ABOUT
            // --------------------------------------------------

            _buildSection(
              icon: Icons.info_outline,
              title: 'About WhereIsIt',
              content:
                  'WhereIsIt is a Lost and Found Service App that helps '
                  'people report lost or found items and makes it easier '
                  'to identify the rightful owner.',
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // HOW IT WORKS
            // --------------------------------------------------

            _buildSection(
              icon: Icons.sync_alt,
              title: 'How It Works',
              content:
                  'Users can create posts for lost or found items. '
                  'The system uses item images and detailed descriptions '
                  'to help identify possible matches. When a valid match '
                  'is identified, the relevant users can be notified.',
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // ITEM CATEGORIES
            // --------------------------------------------------

            _buildSection(
              icon: Icons.category_outlined,
              title: 'Item Categories',
              content:
                  'The app supports three main categories: Identity '
                  'Documents, Valuable Items, and General Items. '
                  'Each category follows its own matching and verification '
                  'process.',
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // LOCATION
            // --------------------------------------------------

            _buildSection(
              icon: Icons.location_on_outlined,
              title: 'Service Area',
              content:
                  'The initial service area is Kanniyakumari district, '
                  'including locations such as Nagercoil, Marthandam, '
                  'Thuckalay and other supported locations.',
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // VERSION
            // --------------------------------------------------

            Text(
              'WhereIsIt • Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // REUSABLE INFORMATION SECTION
  // ------------------------------------------------------------

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
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
                color: Colors.teal.shade700,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}