import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/recovery_service.dart';

class RecoveryConfirmationScreen extends StatefulWidget {
  final String recoveryId;

  const RecoveryConfirmationScreen({
    super.key,
    required this.recoveryId,
  });

  @override
  State<RecoveryConfirmationScreen> createState() =>
      _RecoveryConfirmationScreenState();
}

class _RecoveryConfirmationScreenState
    extends State<RecoveryConfirmationScreen> {
  final RecoveryService _recoveryService = RecoveryService();

  bool _isConfirming = false;

  // ============================================================
  // CONFIRM RECOVERY
  // ============================================================

  Future<void> _confirmRecovery({
    required bool isOwner,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in to continue.',
        isError: true,
      );
      return;
    }

    final String dialogTitle = isOwner
        ? 'Confirm Item Received?'
        : 'Confirm Item Returned?';

    final String dialogMessage = isOwner
        ? 'Please confirm that you have received '
            'your lost item from the finder. '
            'This confirmation will be recorded.'
        : 'Please confirm that you have returned '
            'the item to the lost item owner. '
            'This confirmation will be recorded.';

    final String confirmButtonText =
        isOwner ? 'Confirm Received' : 'Confirm Returned';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmButtonText),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      if (isOwner) {
        await _recoveryService.confirmByOwner(
          widget.recoveryId,
        );
      } else {
        await _recoveryService.confirmByFinder(
          widget.recoveryId,
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        isOwner
            ? 'Item received confirmation recorded.'
            : 'Item returned confirmation recorded.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save your confirmation.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recovery Confirmation'),
        ),
        body: _buildLoggedOutState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recovery Confirmation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('recoveries')
            .where(
              'recoveryId',
              isEqualTo: widget.recoveryId,
            )
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildNotFoundState();
          }

          final Map<String, dynamic> recovery =
              docs.first.data();

          return _buildRecoveryContent(
            recovery,
            currentUser.uid,
          );
        },
      ),
    );
  }

  // ============================================================
  // RECOVERY CONTENT
  // ============================================================

  Widget _buildRecoveryContent(
    Map<String, dynamic> recovery,
    String currentUserId,
  ) {
    final String status =
        recovery['status']?.toString() ?? 'pending';

    final String ownerId =
        recovery['ownerId']?.toString() ?? '';

    final String finderId =
        recovery['finderId']?.toString() ?? '';

    final bool isOwner = currentUserId == ownerId;
    final bool isFinder = currentUserId == finderId;

    final bool ownerConfirmed =
        recovery['ownerConfirmed'] == true;

    final bool finderConfirmed =
        recovery['finderConfirmed'] == true;

    final bool isCompleted = status == 'completed';

    final String recoveryId =
        recovery['recoveryId']?.toString() ??
            widget.recoveryId;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _getPostDetails(recovery),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final Map<String, dynamic>? postData =
            postSnapshot.data?.data();

        final String itemName =
            postData?['itemName']?.toString() ?? 'Item';

        final String category =
            postData?['category']?.toString() ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompleted),

              const SizedBox(height: 22),

              _buildItemCard(
                itemName,
                category,
                postData,
              ),

              const SizedBox(height: 24),

              _buildConfirmationStatus(
                ownerConfirmed,
                finderConfirmed,
              ),

              const SizedBox(height: 24),

              if (isCompleted)
                _buildCompletedCard()
              else if (isOwner)
                _buildOwnerConfirmationSection(
                  ownerConfirmed,
                )
              else if (isFinder)
                _buildFinderConfirmationSection(
                  finderConfirmed,
                )
              else
                _buildUnauthorizedCard(),

              const SizedBox(height: 24),

              Text(
                'Recovery ID: $recoveryId',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // OWNER CONFIRMATION
  // ============================================================

  Widget _buildOwnerConfirmationSection(
    bool ownerConfirmed,
  ) {
    return _buildConfirmationButton(
      title: ownerConfirmed
          ? 'Item Received Confirmed'
          : 'Confirm Item Received',
      subtitle: ownerConfirmed
          ? 'Waiting for the finder to confirm the return.'
          : 'Confirm after you have received your lost item.',
      icon: ownerConfirmed
          ? Icons.check_circle
          : Icons.inventory_2_outlined,
      enabled: !ownerConfirmed,
      onPressed: () {
        _confirmRecovery(
          isOwner: true,
        );
      },
    );
  }

  // ============================================================
  // FINDER CONFIRMATION
  // ============================================================

  Widget _buildFinderConfirmationSection(
    bool finderConfirmed,
  ) {
    return _buildConfirmationButton(
      title: finderConfirmed
          ? 'Item Returned Confirmed'
          : 'Confirm Item Returned',
      subtitle: finderConfirmed
          ? 'Waiting for the lost item owner to confirm receipt.'
          : 'Confirm after you have returned the item to the owner.',
      icon: finderConfirmed
          ? Icons.check_circle
          : Icons.assignment_return_outlined,
      enabled: !finderConfirmed,
      onPressed: () {
        _confirmRecovery(
          isOwner: false,
        );
      },
    );
  }

  // ============================================================
  // GET POST DETAILS
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> _getPostDetails(
    Map<String, dynamic> recovery,
  ) async {
    final String lostPostId =
        recovery['lostPostId']?.toString() ?? '';

    final String foundPostId =
        recovery['foundPostId']?.toString() ?? '';

    final String postId = lostPostId.isNotEmpty
        ? lostPostId
        : foundPostId;

    if (postId.isEmpty) {
      throw Exception('Post ID is missing.');
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isCompleted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  AppColors.successSoft,
                  AppColors.successSoftStrong,
                ]
              : [
                  AppColors.blueSoft,
                  AppColors.blueSoft,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : Icons.sync_alt_rounded,
            size: 58,
            color: isCompleted
                ? AppColors.success
                : AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            isCompleted
                ? 'Recovery Completed'
                : 'Item Return Confirmation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isCompleted
                ? 'Both parties have confirmed the recovery.'
                : 'Both parties must confirm before the recovery is completed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM CARD
  // ============================================================

  Widget _buildItemCard(
    String itemName,
    String category,
    Map<String, dynamic>? post,
  ) {
    final String location =
        post?['location']?.toString() ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Item',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                category,
                style: TextStyle(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            if (location.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    location,
                    style: TextStyle(
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONFIRMATION STATUS
  // ============================================================

  Widget _buildConfirmationStatus(
    bool ownerConfirmed,
    bool finderConfirmed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmation Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          'Lost Item Owner',
          ownerConfirmed,
        ),
        const SizedBox(height: 10),
        _buildStatusRow(
          'Finder',
          finderConfirmed,
        ),
      ],
    );
  }

  // ============================================================
  // STATUS ROW
  // ============================================================

  Widget _buildStatusRow(
    String title,
    bool confirmed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: confirmed
            ? AppColors.successSoft
            : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: confirmed
              ? AppColors.successBorder
              : AppColors.warningBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            confirmed
                ? Icons.check_circle
                : Icons.pending_outlined,
            color: confirmed
                ? AppColors.success
                : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            confirmed ? 'Confirmed' : 'Pending',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: confirmed
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM BUTTON
  // ============================================================

  Widget _buildConfirmationButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            enabled && !_isConfirming ? onPressed : null,
        icon: _isConfirming
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETED CARD
  // ============================================================

  Widget _buildCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.successBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            size: 50,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          Text(
            'Mission Completed',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The item recovery has been confirmed by both parties.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UNAUTHORIZED
  // ============================================================

  Widget _buildUnauthorizedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'You are not one of the users involved in this recovery request.',
        textAlign: TextAlign.center,
      ),
    );
  }

  // ============================================================
  // LOGGED OUT
  // ============================================================

  Widget _buildLoggedOutState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Please log in to view this recovery request.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _buildNotFoundState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Recovery request not found.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load recovery request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}