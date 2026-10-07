import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RecentPostCard extends StatelessWidget {
  final String itemName;
  final String category;
  final String postType;
  final String location;
  final String description;
  final bool isPrivateFinderData;
  final VoidCallback? onTap;

  const RecentPostCard({
    super.key,
    required this.itemName,
    required this.category,
    required this.postType,
    required this.location,
    required this.description,
    this.isPrivateFinderData = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLost = postType.toLowerCase() == 'lost';

    // ------------------------------------------------------------
    // PRIVATE FINDER INFORMATION
    //
    // Found Valuable Item details remain private.
    // ------------------------------------------------------------

    final bool hidePrivateDetails =
        isPrivateFinderData && !isLost;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP ROW
              // ==================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // ITEM ICON
                  // ------------------------------------------------

                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isLost
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ------------------------------------------------
                  // ITEM NAME + CATEGORY
                  // ------------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName.isEmpty
                              ? 'Unnamed Item'
                              : itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ------------------------------------------------
                  // LOST / FOUND LABEL
                  // ------------------------------------------------

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLost
                          ? AppColors.errorSoft
                          : AppColors.successSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      postType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLost
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // LOCATION
              // ==================================================

              if (location.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 19,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),

              // ==================================================
              // DESCRIPTION
              //
              // Hidden for Found Valuable Items.
              // ==================================================

              if (!hidePrivateDetails &&
                  description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.primaryText,
                  ),
                ),
              ],

              // ==================================================
              // PRIVATE INFORMATION NOTICE
              // ==================================================

              if (hidePrivateDetails) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.blueSoft,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 17,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Some item details are private for verification.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ==================================================
              // VIEW DETAILS
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}