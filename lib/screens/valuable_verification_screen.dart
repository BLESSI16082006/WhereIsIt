import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class ValuableVerificationScreen extends StatefulWidget {
  final String postId;
  final String itemName;

  const ValuableVerificationScreen({
    super.key,
    required this.postId,
    required this.itemName,
  });

  @override
  State<ValuableVerificationScreen> createState() =>
      _ValuableVerificationScreenState();
}

class _ValuableVerificationScreenState
    extends State<ValuableVerificationScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  final List<TextEditingController> _controllers =
      List.generate(
    5,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;

  // ============================================================
  // FIXED VERIFICATION QUESTIONS
  // ============================================================

  final List<String> _questions = [
    'What is the main color of the item?',
    'What is the brand or model of the item?',
    'What is one unique feature of the item?',
    'Does the item have any mark, scratch, sticker, case, engraving, or other identifying detail?',
    'Describe one additional detail that can prove the item belongs to you.',
  ];

  // ============================================================
  // NORMALIZE ANSWER
  // ============================================================

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9\s]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  // ============================================================
  // HASH ANSWER
  // ============================================================

  String _hashAnswer(String answer) {
    return sha256
        .convert(
          utf8.encode(
            _normalize(answer),
          ),
        )
        .toString();
  }

  // ============================================================
  // CREATE NOTIFICATION SAFELY
  // ============================================================

  Future<void> _createSafeNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    if (userId.trim().isEmpty) {
      return;
    }

    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );
    } catch (e) {
      debugPrint(
        'Notification creation failed: $e',
      );
    }
  }

  // ============================================================
  // SEND OWNER VERIFICATION SUCCESS NOTIFICATIONS
  // ============================================================

  Future<void> _sendVerificationSuccessNotifications({
    required String ownerId,
    required String finderId,
  }) async {
    // ----------------------------------------------------------
    // LOST PERSON / OWNER
    // ----------------------------------------------------------

    await _createSafeNotification(
      userId: ownerId,
      title: 'Ownership Verification Successful',
      message:
          'Your ownership verification was successful. '
          'You can now continue with the item return process.',
      type: 'ownership_verification',
    );

    // ----------------------------------------------------------
    // FINDER
    // ----------------------------------------------------------

    if (finderId.isNotEmpty &&
        finderId != ownerId) {
      await _createSafeNotification(
        userId: finderId,
        title: 'Ownership Verification Successful',
        message:
            'The lost person has successfully completed '
            'ownership verification for your found valuable item.',
        type: 'ownership_verification',
      );
    }
  }

  // ============================================================
  // SUBMIT VERIFICATION
  // ============================================================

  Future<void> _submitVerification() async {
    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in to verify ownership.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK ALL ANSWERS
    // ----------------------------------------------------------

    if (_controllers.any(
      (controller) =>
          controller.text.trim().isEmpty,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer all 5 questions.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // GET STORED VERIFICATION DATA
      // --------------------------------------------------------

      final DocumentSnapshot<
          Map<String, dynamic>> verificationDoc =
          await _firestore
              .collection('post_verification')
              .doc(widget.postId)
              .get();

      if (!verificationDoc.exists) {
        throw Exception(
          'Verification information is not available for this item.',
        );
      }

      final Map<String, dynamic>? data =
          verificationDoc.data();

      final List<dynamic> storedHashes =
          data?['answerHashes'] ?? [];

      if (storedHashes.length != 5) {
        throw Exception(
          'Invalid verification data.',
        );
      }

      // --------------------------------------------------------
      // COMPARE ANSWERS
      // --------------------------------------------------------

      int correctAnswers = 0;

      for (int i = 0; i < 5; i++) {
        final String userHash =
            _hashAnswer(
          _controllers[i].text,
        );

        final String storedHash =
            storedHashes[i].toString();

        if (userHash == storedHash) {
          correctAnswers++;
        }
      }

      // --------------------------------------------------------
      // 4 OUT OF 5 = VERIFIED
      // --------------------------------------------------------

      final bool verified =
          correctAnswers >= 4;

      if (verified) {
        // ------------------------------------------------------
        // GET FOUND POST
        // ------------------------------------------------------

        final DocumentSnapshot<
            Map<String, dynamic>> postSnapshot =
            await _firestore
                .collection('posts')
                .doc(widget.postId)
                .get();

        if (!postSnapshot.exists) {
          throw Exception(
            'The found item post could not be found.',
          );
        }

        final Map<String, dynamic> postData =
            postSnapshot.data() ?? {};

        // The person who created the Found valuable post
        // is the finder.
        final String finderId =
            postData['userId']?.toString() ?? '';

        // ------------------------------------------------------
        // SAVE VERIFIED OWNER
        // ------------------------------------------------------
        //
        // IMPORTANT:
        // The project uses "verifiedUserId" in the recovery
        // and post-details logic, and the Firestore rule also
        // expects "verifiedUserId".
        //
        // Do not use "verifiedOwnerId" here.
        //
        // Also, recoveryStatus is intentionally NOT updated here.
        // Recovery starts only when the user explicitly chooses
        // Continue Item Return.
        // ------------------------------------------------------

        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .update({
          'ownerVerified': true,
          'verifiedUserId':
              currentUser.uid,
          'verifiedAt':
              FieldValue.serverTimestamp(),
          'verificationStatus':
              'verified',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });

        // ------------------------------------------------------
        // SEND NOTIFICATIONS
        // ------------------------------------------------------

        await _sendVerificationSuccessNotifications(
          ownerId: currentUser.uid,
          finderId: finderId,
        );

        if (!mounted) {
          return;
        }

        // ------------------------------------------------------
        // SUCCESS DIALOG
        // ------------------------------------------------------

        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ownership Verified',
                    ),
                  ),
                ],
              ),
              content: Text(
                'Your answers matched $correctAnswers '
                'out of 5 verification questions.\n\n'
                'Ownership verification was successful.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                  ),
                  child: const Text(
                    'Continue',
                  ),
                ),
              ],
            );
          },
        );

        // ------------------------------------------------------
        // RETURN SUCCESS TO POST DETAILS
        // ------------------------------------------------------

        if (mounted) {
          Navigator.pop(
            context,
            true,
          );
        }
      } else {
        // ------------------------------------------------------
        // VERIFICATION FAILED
        // ------------------------------------------------------

        if (!mounted) {
          return;
        }

        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verification Failed',
                    ),
                  ),
                ],
              ),
              content: Text(
                '$correctAnswers out of 5 answers matched.\n\n'
                'Ownership could not be verified.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                  ),
                  child: const Text(
                    'Try Again',
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification error: $e',
          ),
          backgroundColor:
              Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Ownership',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // CLAIM ITEM
              // ------------------------------------------------

              Text(
                'Claim: ${widget.itemName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // EXPLANATION
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color:
                        Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          Colors.blue.shade700,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        'Answer the following questions '
                        'about the item. At least 4 of 5 '
                        'answers must match.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color:
                              Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // QUESTIONS
              // ------------------------------------------------

              ...List.generate(
                5,
                (index) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 18,
                  ),
                  child: TextFormField(
                    controller:
                        _controllers[index],
                    maxLines: 3,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Question ${index + 1}',
                      hintText:
                          _questions[index],
                      alignLabelWithHint:
                          true,
                      border:
                          const OutlineInputBorder(),
                      focusedBorder:
                          OutlineInputBorder(
                        borderSide:
                            BorderSide(
                          color:
                              Colors.teal.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // VERIFY BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : _submitVerification,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.verified_user,
                        ),
                  label: Text(
                    _isLoading
                        ? 'Verifying...'
                        : 'Verify Ownership',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // SECURITY NOTE
              // ------------------------------------------------

              Center(
                child: Text(
                  'Your answers are checked against '
                  'the private item information.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
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
}