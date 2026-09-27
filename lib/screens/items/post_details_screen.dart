import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/recovery_service.dart';
import 'recovery_confirmation_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailsScreen> createState() =>
      _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final RecoveryService _recoveryService =
      RecoveryService();

  final List<TextEditingController> _answerControllers =
      List.generate(
    5,
    (_) => TextEditingController(),
  );

  final List<String> _verificationQuestions = [
    'What is the main color of the item?',
    'What is the brand or model of the item?',
    'What is one unique feature of the item?',
    'Does the item have any mark, scratch, sticker, case, engraving, or other identifying detail?',
    'Describe one additional detail that can prove the item belongs to you.',
  ];

  Map<String, dynamic> _post = {};

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isStartingRecovery = false;

  bool _ownerVerified = false;
  String _verifiedUserId = '';

  int _verificationAttempts = 0;

  String _recoveryId = '';
  String _recoveryStatus = '';
  String _recoveryOwnerId = '';
  String _recoveryFinderId = '';

  bool _ownerConfirmed = false;
  bool _finderConfirmed = false;

  static const int _maxVerificationAttempts = 3;

  @override
  void initState() {
    super.initState();

    _post = Map<String, dynamic>.from(widget.post);

    _loadPost();
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // LOAD POST
  // ============================================================

  Future<void> _loadPost() async {
    final String postId =
        _post['postId']?.toString() ?? '';

    if (postId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('posts')
              .doc(postId)
              .get();

      if (!mounted) {
        return;
      }

      if (snapshot.exists && snapshot.data() != null) {
        final Map<String, dynamic> latestData =
            snapshot.data()!;

        setState(() {
          _post = {
            ..._post,
            ...latestData,
          };

          _ownerVerified =
              latestData['ownerVerified'] == true;

          _verifiedUserId =
              latestData['verifiedUserId']
                      ?.toString() ??
                  '';

          _verificationAttempts =
              (latestData['verificationAttempts']
                          as num?)
                      ?.toInt() ??
                  0;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      await _loadRecoveryForCurrentPost();
    } catch (e) {
      debugPrint(
        'PostDetailsScreen load error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load the latest post details.',
      );
    }
  }

  // ============================================================
  // LOAD RECOVERY FOR CURRENT POST
  // ============================================================

  Future<void> _loadRecoveryForCurrentPost() async {
    final String postId =
        _post['postId']?.toString() ?? '';

    if (postId.isEmpty) {
      return;
    }

    try {
      final List<QuerySnapshot<Map<String, dynamic>>>
          results = await Future.wait([
        _firestore
            .collection('recoveries')
            .where(
              'foundPostId',
              isEqualTo: postId,
            )
            .limit(10)
            .get(),
        _firestore
            .collection('recoveries')
            .where(
              'lostPostId',
              isEqualTo: postId,
            )
            .limit(10)
            .get(),
      ]);

      final List<DocumentSnapshot<Map<String, dynamic>>>
          documents = [
        ...results[0].docs,
        ...results[1].docs,
      ];

      if (documents.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _recoveryId = '';
          _recoveryStatus = '';
          _recoveryOwnerId = '';
          _recoveryFinderId = '';
          _ownerConfirmed = false;
          _finderConfirmed = false;
        });

        return;
      }

      DocumentSnapshot<Map<String, dynamic>>?
          selectedDocument;

      // Prefer a pending recovery.
      for (final document in documents) {
        final Map<String, dynamic>? data =
            document.data();

        if (data == null) {
          continue;
        }

        final String status =
            data['status']?.toString() ?? '';

        if (status == 'pending') {
          selectedDocument = document;
          break;
        }
      }

      // If there is no pending recovery, use completed.
      selectedDocument ??= documents.firstWhere(
        (document) {
          final String status =
              document.data()?['status']
                      ?.toString() ??
                  '';

          return status == 'completed';
        },
        orElse: () => documents.first,
      );

      final Map<String, dynamic>? recoveryData =
          selectedDocument.data();

      if (recoveryData == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _recoveryId = selectedDocument!.id;

        _recoveryStatus =
            recoveryData['status']
                    ?.toString() ??
                '';

        _recoveryOwnerId =
            recoveryData['ownerId']
                    ?.toString() ??
                '';

        _recoveryFinderId =
            recoveryData['finderId']
                    ?.toString() ??
                '';

        _ownerConfirmed =
            recoveryData['ownerConfirmed'] == true;

        _finderConfirmed =
            recoveryData['finderConfirmed'] == true;
      });
    } catch (e) {
      debugPrint(
        'Load recovery error: $e',
      );

      // Recovery information is supplementary.
      // Do not prevent the post details screen from loading.
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get _currentUser =>
      _auth.currentUser;

  String get _currentUserId =>
      _currentUser?.uid ?? '';

  String get _postUserId =>
      _post['userId']?.toString() ?? '';

  bool get _isPostOwner {
    final User? user = _currentUser;

    return user != null &&
        user.uid == _postUserId;
  }

  // ============================================================
  // POST TYPE / CATEGORY
  // ============================================================

  String get _postType =>
      _post['postType']?.toString() ?? '';

  String get _category =>
      _post['category']?.toString() ?? '';

  bool get _isLostPost =>
      _postType == 'Lost';

  bool get _isFoundPost =>
      _postType == 'Found';

  bool get _isValuableFoundPost {
    return _isFoundPost &&
        _category == 'Valuable Items';
  }

  bool get _isCompleted {
    return _post['isCompleted'] == true ||
        _post['status']?.toString() ==
            'completed' ||
        _post['recoveryStatus']?.toString() ==
            'completed' ||
        _recoveryStatus == 'completed';
  }

  // ============================================================
  // VERIFICATION ACCESS
  // ============================================================

  bool get _isVerifiedForCurrentUser {
    return _ownerVerified &&
        _verifiedUserId.isNotEmpty &&
        _verifiedUserId == _currentUserId;
  }

  bool get _canViewPrivateFinderDetails {
    return !_isValuableFoundPost ||
        _isPostOwner ||
        _isVerifiedForCurrentUser;
  }

  // ============================================================
  // RECOVERY STATE
  // ============================================================

  bool get _hasRecovery =>
      _recoveryId.isNotEmpty;

  bool get _hasPendingRecovery =>
      _hasRecovery &&
      _recoveryStatus == 'pending';

  bool get _hasCompletedRecovery =>
      _hasRecovery &&
      _recoveryStatus == 'completed';

  bool get _isCurrentRecoveryOwner {
    return _recoveryOwnerId.isNotEmpty &&
        _recoveryOwnerId == _currentUserId;
  }

  bool get _isCurrentRecoveryFinder {
    return _recoveryFinderId.isNotEmpty &&
        _recoveryFinderId == _currentUserId;
  }

  String get _itemName =>
      _post['itemName']?.toString() ??
      'Unnamed Item';

  String get _location =>
      _post['location']?.toString() ?? '';

  String get _description =>
      _post['description']?.toString() ?? '';

  String get _phone =>
      _post['phone']?.toString() ?? '';

  String get _email =>
      _post['email']?.toString() ?? '';

  String get _imageUrl =>
      _post['imageUrl']?.toString() ?? '';

  String get _reward =>
      _post['reward']?.toString() ?? '';

  // ============================================================
  // NORMALIZE ANSWER
  // ============================================================

  String _normalizeAnswer(String value) {
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
            _normalizeAnswer(answer),
          ),
        )
        .toString();
  }

  // ============================================================
  // VERIFY OWNERSHIP
  // ============================================================

  Future<void> _verifyOwnership() async {
    if (_isVerifying) {
      return;
    }

    if (_currentUser == null) {
      _showMessage(
        'Please log in before starting verification.',
      );
      return;
    }

    if (_isPostOwner) {
      _showMessage(
        'You are the person who created this found post.',
      );
      return;
    }

    if (_ownerVerified &&
        _verifiedUserId.isNotEmpty &&
        _verifiedUserId != _currentUserId) {
      _showMessage(
        'This item has already been verified by another account.',
      );
      return;
    }

    if (_verificationAttempts >=
        _maxVerificationAttempts) {
      _showMessage(
        'Maximum verification attempts reached.',
      );
      return;
    }

    bool allAnswered = true;

    for (final controller in _answerControllers) {
      if (controller.text.trim().isEmpty) {
        allAnswered = false;
        break;
      }
    }

    if (!allAnswered) {
      _showMessage(
        'Please answer all 5 verification questions.',
      );
      return;
    }

    final String postId =
        _post['postId']?.toString() ?? '';

    if (postId.isEmpty) {
      _showMessage(
        'This post does not have a valid post ID.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          verificationSnapshot =
          await _firestore
              .collection('post_verification')
              .doc(postId)
              .get();

      if (!verificationSnapshot.exists ||
          verificationSnapshot.data() == null) {
        throw Exception(
          'Verification information is unavailable for this post.',
        );
      }

      final Map<String, dynamic> verificationData =
          verificationSnapshot.data()!;

      final dynamic rawHashes =
          verificationData['answerHashes'];

      if (rawHashes is! List) {
        throw Exception(
          'Verification answers are unavailable.',
        );
      }

      final List<String> storedHashes =
          rawHashes
              .map(
                (value) => value.toString(),
              )
              .toList();

      if (storedHashes.length < 5) {
        throw Exception(
          'Verification information is incomplete.',
        );
      }

      final List<String> submittedHashes =
          _answerControllers
              .map(
                (controller) =>
                    _hashAnswer(
                  controller.text.trim(),
                ),
              )
              .toList();

      int correctAnswers = 0;

      for (int i = 0; i < 5; i++) {
        if (submittedHashes[i] ==
            storedHashes[i]) {
          correctAnswers++;
        }
      }

      _verificationAttempts++;

      if (correctAnswers == 5) {
        await _markOwnerVerified(
          postId,
        );
      } else {
        _clearAnswers();

        if (_verificationAttempts >=
            _maxVerificationAttempts) {
          await _markVerificationFailed(
            postId,
          );

          if (!mounted) {
            return;
          }

          _showVerificationFailure(
            'Verification failed. '
            'You have used all 3 attempts.',
          );
        } else {
          await _saveVerificationAttempts(
            postId,
          );

          if (!mounted) {
            return;
          }

          final int remaining =
              _maxVerificationAttempts -
                  _verificationAttempts;

          _showVerificationFailure(
            'Verification failed. '
            'The answers did not match.\n\n'
            '$remaining attempt${remaining == 1 ? '' : 's'} remaining.',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Ownership verification error: $e',
      );

      if (mounted) {
        _showMessage(
          'Verification could not be completed.\n$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // MARK VERIFIED
  // ============================================================

  Future<void> _markOwnerVerified(
    String postId,
  ) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'ownerVerified': true,
      'verificationStatus': 'verified',
      'verificationAttempts':
          _verificationAttempts,
      'verifiedUserId':
          _currentUser!.uid,
      'verifiedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _ownerVerified = true;
      _verifiedUserId =
          _currentUser!.uid;
    });

    _clearAnswers();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Ownership verified successfully. Finder details are now available.',
        ),
        duration: Duration(
          seconds: 4,
        ),
      ),
    );
  }

  // ============================================================
  // SAVE VERIFICATION ATTEMPTS
  // ============================================================

  Future<void> _saveVerificationAttempts(
    String postId,
  ) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({
        'verificationAttempts':
            _verificationAttempts,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Unable to save verification attempts: $e',
      );
    }
  }

  // ============================================================
  // MARK VERIFICATION FAILED
  // ============================================================

  Future<void> _markVerificationFailed(
    String postId,
  ) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({
        'verificationStatus':
            'failed',
        'verificationAttempts':
            _verificationAttempts,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Unable to save verification failure: $e',
      );
    }
  }

  // ============================================================
  // CLEAR ANSWERS
  // ============================================================

  void _clearAnswers() {
    for (final controller
        in _answerControllers) {
      controller.clear();
    }
  }

  // ============================================================
  // START / CONTINUE ITEM RETURN
  // ============================================================

  Future<void> _continueItemReturn() async {
    if (_isStartingRecovery) {
      return;
    }

    if (_currentUser == null) {
      _showMessage(
        'Please log in before continuing.',
      );
      return;
    }

    if (_hasPendingRecovery) {
      await _openRecoveryConfirmation(
        _recoveryId,
      );
      return;
    }

    if (_hasCompletedRecovery) {
      _showMessage(
        'This item recovery has already been completed.',
      );
      return;
    }

    if (_isValuableFoundPost &&
        !_isVerifiedForCurrentUser) {
      _showMessage(
        'Please complete owner verification first.',
      );
      return;
    }

    setState(() {
      _isStartingRecovery = true;
    });

    try {
      String? lostPostId;
      String? foundPostId;

      if (_isLostPost && _isPostOwner) {
        // Lost post owner selects the found post.
        foundPostId =
            await _selectFoundPost();

        if (foundPostId == null) {
          return;
        }

        lostPostId =
            _post['postId']?.toString();
      } else if (_isFoundPost &&
          !_isPostOwner) {
        // Person claiming the found item selects
        // their own lost post.
        lostPostId =
            await _selectLostPost();

        if (lostPostId == null) {
          return;
        }

        foundPostId =
            _post['postId']?.toString();
      } else {
        _showMessage(
          'The item return can only be started by the Lost Item owner or the verified claimant.',
        );
        return;
      }

      if (lostPostId == null ||
          lostPostId.isEmpty ||
          foundPostId == null ||
          foundPostId.isEmpty) {
        _showMessage(
          'Valid Lost and Found posts are required.',
        );
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>>
          lostSnapshot =
          await _firestore
              .collection('posts')
              .doc(lostPostId)
              .get();

      final DocumentSnapshot<Map<String, dynamic>>
          foundSnapshot =
          await _firestore
              .collection('posts')
              .doc(foundPostId)
              .get();

      if (!lostSnapshot.exists ||
          lostSnapshot.data() == null) {
        throw Exception(
          'The selected lost item could not be found.',
        );
      }

      if (!foundSnapshot.exists ||
          foundSnapshot.data() == null) {
        throw Exception(
          'The selected found item could not be found.',
        );
      }

      final Map<String, dynamic> lostPost =
          lostSnapshot.data()!;

      final Map<String, dynamic> foundPost =
          foundSnapshot.data()!;

      if (lostPost['postType']?.toString() !=
          'Lost') {
        throw Exception(
          'The selected post is not a Lost Item post.',
        );
      }

      if (foundPost['postType']?.toString() !=
          'Found') {
        throw Exception(
          'The selected post is not a Found Item post.',
        );
      }

      final String ownerId =
          lostPost['userId']?.toString() ??
              '';

      final String finderId =
          foundPost['userId']?.toString() ??
              '';

      if (ownerId.isEmpty ||
          finderId.isEmpty) {
        throw Exception(
          'Owner or finder information is missing.',
        );
      }

      // The user starting the recovery must be
      // one of the two recovery participants.
      final bool isOwnerStarting =
          ownerId == _currentUserId;

      final bool isFinderStarting =
          finderId == _currentUserId;

      if (!isOwnerStarting &&
          !isFinderStarting) {
        throw Exception(
          'Only the lost-item owner or found-item claimant can start the item return.',
        );
      }

      // Valuable found items must always have
      // successful ownership verification.
      final bool selectedFoundIsValuable =
          foundPost['postType']
                      ?.toString() ==
                  'Found' &&
              foundPost['category']
                      ?.toString() ==
                  'Valuable Items';

      if (selectedFoundIsValuable) {
        final String verifiedUserId =
            foundPost['verifiedUserId']
                    ?.toString() ??
                '';

        final bool verified =
            foundPost['ownerVerified'] ==
                    true &&
                verifiedUserId ==
                    _currentUserId;

        if (!verified) {
          throw Exception(
            'This Valuable Item requires successful ownership verification before the return can begin.',
          );
        }
      }

      final QuerySnapshot<Map<String, dynamic>>
          existing =
          await _recoveryService
              .getRecoveryByPosts(
        lostPostId: lostPostId,
        foundPostId: foundPostId,
      );

      String recoveryId = '';

      if (existing.docs.isNotEmpty) {
        for (final document in existing.docs) {
          final Map<String, dynamic>? data =
              document.data();

          final String status =
              data?['status']?.toString() ??
                  '';

          if (status == 'pending' ||
              status == 'completed') {
            recoveryId = document.id;
            break;
          }
        }
      }

      if (recoveryId.isEmpty) {
        recoveryId =
            await _recoveryService
                .createRecoveryRequest(
          lostPostId:
              lostPostId,
          foundPostId:
              foundPostId,
          ownerId: ownerId,
          finderId: finderId,
        );
      }

      if (!mounted) {
        return;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          recoverySnapshot =
          await _recoveryService
              .getRecovery(
        recoveryId,
      );

      final Map<String, dynamic>?
          recoveryData =
          recoverySnapshot.data();

      final String status =
          recoveryData?['status']
                  ?.toString() ??
              'pending';

      if (status == 'completed') {
        _showMessage(
          'This item recovery has already been completed.',
        );

        await _loadPost();
        return;
      }

      await _openRecoveryConfirmation(
        recoveryId,
      );
    } catch (e) {
      debugPrint(
        'Continue item return error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to start item return.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRecovery = false;
        });
      }
    }
  }

  // ============================================================
  // SELECT LOST POST
  // ============================================================

  Future<String?> _selectLostPost() async {
    if (_currentUser == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('posts')
              .where(
                'userId',
                isEqualTo: _currentUser!.uid,
              )
              .limit(100)
              .get();

      final List<DocumentSnapshot<Map<String, dynamic>>>
          lostPosts =
          snapshot.docs.where((document) {
        final Map<String, dynamic>? data =
            document.data();

        return data != null &&
            data['postType']?.toString() ==
                'Lost' &&
            data['isCompleted'] != true &&
            data['status']?.toString() !=
                'completed';
      }).toList();

      if (lostPosts.isEmpty) {
        _showMessage(
          'You do not have an active Lost Item post to associate with this found item.',
        );
        return null;
      }

      if (!mounted) {
        return null;
      }

      return showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Select Your Lost Item',
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the Lost Item that belongs to this recovery. The app will not automatically match posts.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount:
                          lostPosts.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),
                      itemBuilder:
                          (context, index) {
                        final Map<String, dynamic>? postData =
                            lostPosts[index].data();

                        if (postData == null) {
                          return const SizedBox.shrink();
                        }

                        final Map<String, dynamic> data =
                            postData;

                        final String name =
                            data['itemName']
                                    ?.toString() ??
                                'Unnamed Item';

                        final String category =
                            data['category']
                                    ?.toString() ??
                                '';

                        final String location =
                            data['location']
                                    ?.toString() ??
                                '';

                        return ListTile(
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons
                                  .search_off_outlined,
                            ),
                          ),
                          title:
                              Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          subtitle:
                              Text(
                            [
                              category,
                              location,
                            ]
                                .where(
                                  (value) =>
                                      value
                                          .isNotEmpty,
                                )
                                .join(' • '),
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(
                              dialogContext,
                              lostPosts[index]
                                  .id,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Select lost post error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to load your Lost Items.\n$e',
        );
      }

      return null;
    }
  }

  // ============================================================
  // SELECT FOUND POST
  // ============================================================

  Future<String?> _selectFoundPost() async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('posts')
              .where(
                'postType',
                isEqualTo: 'Found',
              )
              .limit(100)
              .get();

      final List<DocumentSnapshot<Map<String, dynamic>>>
          foundPosts =
          snapshot.docs.where((document) {
        final Map<String, dynamic>? data =
            document.data();

        return data != null &&
            data['postType']?.toString() ==
                'Found' &&
            data['isCompleted'] != true &&
            data['status']?.toString() !=
                'completed';
      }).toList();

      if (foundPosts.isEmpty) {
        _showMessage(
          'No active Found Item posts are available.',
        );
        return null;
      }

      if (!mounted) {
        return null;
      }

      return showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Select Found Item',
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the Found Item that belongs to this recovery. The app will not automatically match posts.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount:
                          foundPosts.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),
                      itemBuilder:
                          (context, index) {
                        final Map<String, dynamic>? postData =
                            foundPosts[index].data();

                        if (postData == null) {
                          return const SizedBox.shrink();
                        }

                        final Map<String, dynamic> data =
                            postData;

                        final String name =
                            data['itemName']
                                    ?.toString() ??
                                'Unnamed Item';

                        final String category =
                            data['category']
                                    ?.toString() ??
                                '';

                        final String location =
                            data['location']
                                    ?.toString() ??
                                '';

                        final bool isValuable =
                            category ==
                                'Valuable Items';

                        return ListTile(
                          leading:
                              CircleAvatar(
                            child: Icon(
                              isValuable
                                  ? Icons
                                      .lock_outline
                                  : Icons
                                      .inventory_2_outlined,
                            ),
                          ),
                          title:
                              Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          subtitle:
                              Text(
                            [
                              category,
                              location,
                            ]
                                .where(
                                  (value) =>
                                      value
                                          .isNotEmpty,
                                )
                                .join(' • '),
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(
                              dialogContext,
                              foundPosts[index]
                                  .id,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Select found post error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to load Found Items.\n$e',
        );
      }

      return null;
    }
  }

  // ============================================================
  // OPEN RECOVERY CONFIRMATION
  // ============================================================

  Future<void> _openRecoveryConfirmation(
    String recoveryId,
  ) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RecoveryConfirmationScreen(
          recoveryId: recoveryId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadPost();
  }

  // ============================================================
  // SHOW VERIFICATION FAILURE
  // ============================================================

  void _showVerificationFailure(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade600,
            size: 42,
          ),
          title: const Text(
            'Verification Failed',
          ),
          content: Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Item Details',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Item Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPost,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),

              const SizedBox(
                height: 18,
              ),

              _buildBasicInformation(),

              const SizedBox(
                height: 18,
              ),

              if (_isValuableFoundPost &&
                  !_canViewPrivateFinderDetails)
                _buildPrivateValuableCard()
              else ...[
                if (_imageUrl.isNotEmpty)
                  _buildImageCard(),

                if (_imageUrl.isNotEmpty)
                  const SizedBox(
                    height: 18,
                  ),

                _buildDescriptionCard(),

                const SizedBox(
                  height: 18,
                ),

                _buildContactCard(),
              ],

              // --------------------------------------------------
              // VALUABLE ITEM VERIFICATION
              // --------------------------------------------------

              if (_isValuableFoundPost &&
                  !_isPostOwner &&
                  !_isVerifiedForCurrentUser &&
                  !_hasRecovery &&
                  _verificationAttempts <
                      _maxVerificationAttempts) ...[
                const SizedBox(
                  height: 4,
                ),
                _buildVerificationCard(),
              ],

              // --------------------------------------------------
              // VERIFIED VALUABLE ITEM
              // --------------------------------------------------

              if (_isValuableFoundPost &&
                  !_isPostOwner &&
                  _isVerifiedForCurrentUser &&
                  !_hasPendingRecovery &&
                  !_hasCompletedRecovery) ...[
                const SizedBox(
                  height: 4,
                ),
                _buildVerifiedFinderCard(),

                const SizedBox(
                  height: 18,
                ),

                _buildStartReturnCard(
                  valuableVerified: true,
                ),
              ],

              // --------------------------------------------------
              // NON-VALUABLE FOUND ITEM
              // --------------------------------------------------

              if (_isFoundPost &&
                  !_isPostOwner &&
                  !_isValuableFoundPost &&
                  !_hasRecovery) ...[
                const SizedBox(
                  height: 18,
                ),
                _buildStartReturnCard(
                  valuableVerified: false,
                ),
              ],

              // --------------------------------------------------
              // LOST ITEM OWNER
              // --------------------------------------------------

              if (_isLostPost &&
                  _isPostOwner &&
                  !_hasRecovery &&
                  !_isCompleted) ...[
                const SizedBox(
                  height: 18,
                ),
                _buildStartReturnCard(
                  valuableVerified: false,
                ),
              ],

              // --------------------------------------------------
              // FINDER SIDE / OWNER SIDE RECOVERY STATUS
              // --------------------------------------------------

              if (_hasPendingRecovery) ...[
                const SizedBox(
                  height: 18,
                ),
                _buildRecoveryStatusCard(),
              ],

              // --------------------------------------------------
              // COMPLETED
              // --------------------------------------------------

              if (_hasCompletedRecovery ||
                  _isCompleted) ...[
                const SizedBox(
                  height: 18,
                ),
                _buildCompletedCard(),
              ],

              const SizedBox(
                height: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard() {
    final bool isFound =
        _postType == 'Found';

    final Color statusColor =
        isFound
            ? Colors.green.shade700
            : Colors.orange.shade700;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(
              alpha: 0.14,
            ),
            statusColor.withValues(
              alpha: 0.04,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _itemName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: statusColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  isFound
                      ? 'FOUND'
                      : 'LOST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (_category.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              _category,
              style: TextStyle(
                fontSize: 14,
                color:
                    Colors.grey.shade700,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],

          if (_isValuableFoundPost) ...[
            const SizedBox(
              height: 12,
            ),
            _buildPrivacyBadge(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PRIVACY BADGE
  // ============================================================

  Widget _buildPrivacyBadge() {
    final bool verified =
        _isPostOwner ||
            _isVerifiedForCurrentUser;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: verified
            ? Colors.green.withValues(
                alpha: 0.10,
              )
            : Colors.orange.withValues(
                alpha: 0.10,
              ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified_user_outlined
                : Icons.lock_outline,
            size: 17,
            color: verified
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            verified
                ? 'Owner verified'
                : 'Finder details protected',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: verified
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformation() {
    return _buildSectionCard(
      title: 'Item Information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.category_outlined,
            'Category',
            _category,
          ),

          if (_location.isNotEmpty)
            _buildInfoRow(
              Icons.location_on_outlined,
              'Location',
              _location,
            ),

          if (_post['date'] != null)
            _buildInfoRow(
              Icons.calendar_today_outlined,
              _postType == 'Found'
                  ? 'Found Date'
                  : 'Lost Date',
              _formatDate(
                _post['date'],
              ),
            ),

          if (_reward.isNotEmpty)
            _buildInfoRow(
              Icons.card_giftcard_outlined,
              'Reward',
              '₹$_reward',
              valueColor:
                  Colors.green.shade700,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _buildImageCard() {
    return _buildSectionCard(
      title: 'Item Image',
      icon: Icons.image_outlined,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.network(
          _imageUrl,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return _buildImagePlaceholder(
              height: 260,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionCard() {
    final String description =
        _description.isNotEmpty
            ? _description
            : 'No description provided.';

    return _buildSectionCard(
      title: 'Description',
      icon: Icons.description_outlined,
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color:
              Colors.grey.shade800,
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT CARD
  // ============================================================

  Widget _buildContactCard() {
    return _buildSectionCard(
      title: _isValuableFoundPost
          ? 'Finder Details'
          : 'Contact Information',
      icon: Icons.contact_phone_outlined,
      child: Column(
        children: [
          if (_phone.isNotEmpty)
            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              _phone,
            ),

          if (_email.isNotEmpty)
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              _email,
            ),

          if (_phone.isEmpty &&
              _email.isEmpty)
            Text(
              'No contact information available.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIVATE VALUABLE CARD
  // ============================================================

  Widget _buildPrivateValuableCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .admin_panel_settings_outlined,
            size: 52,
            color: Colors.orange.shade700,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Finder Details Protected',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'The finder has protected the item image, description, and contact details to prevent false ownership claims.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.teal,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'If you believe this is your item, complete the ownership verification questions below.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFICATION CARD
  // ============================================================

  Widget _buildVerificationCard() {
    final int remaining =
        _maxVerificationAttempts -
            _verificationAttempts;

    final bool attemptsAvailable =
        _verificationAttempts <
            _maxVerificationAttempts;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.teal.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color:
                    Colors.teal.shade700,
              ),
              const SizedBox(
                width: 9,
              ),
              const Expanded(
                child: Text(
                  'Owner Verification',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Answer all 5 questions exactly as accurately as possible. All five answers must match.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              attemptsAvailable
                  ? 'Attempts remaining: $remaining / $_maxVerificationAttempts'
                  : 'Maximum verification attempts reached.',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color: attemptsAvailable
                    ? Colors.teal.shade800
                    : Colors.red.shade700,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          ...List.generate(
            5,
            (index) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 14,
                ),
                child:
                    TextFormField(
                  controller:
                      _answerControllers[
                          index],
                  enabled:
                      !_isVerifying &&
                          attemptsAvailable,
                  textCapitalization:
                      TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
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
                          Colors.teal
                              .shade100,
                      child: Text(
                        '${index + 1}',
                        style:
                            TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: Colors
                              .teal
                              .shade800,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 4,
          ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  (!attemptsAvailable ||
                          _isVerifying)
                      ? null
                      : _verifyOwnership,
              icon: _isVerifying
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
                          .verified_user_outlined,
                    ),
              label: Text(
                _isVerifying
                    ? 'Verifying...'
                    : 'Verify Ownership',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFIED FINDER CARD
  // ============================================================

  Widget _buildVerifiedFinderCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color:
                    Colors.green.shade700,
              ),
              const SizedBox(
                width: 8,
              ),
              const Expanded(
                child: Text(
                  'Ownership Verified',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'The ownership verification was successful. The finder details are now available.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          if (_imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: Image.network(
                _imageUrl,
                width:
                    double.infinity,
                height: 230,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _buildImagePlaceholder(
                    height: 230,
                  );
                },
              ),
            ),

          if (_imageUrl.isNotEmpty)
            const SizedBox(
              height: 16,
            ),

          if (_description.isNotEmpty)
            _buildPrivateDetail(
              'Finder Description',
              _description,
              Icons.description_outlined,
            ),

          if (_phone.isNotEmpty)
            _buildPrivateDetail(
              'Finder Phone',
              _phone,
              Icons.phone_outlined,
            ),

          if (_email.isNotEmpty)
            _buildPrivateDetail(
              'Finder Email',
              _email,
              Icons.email_outlined,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // START RETURN CARD
  // ============================================================

  Widget _buildStartReturnCard({
    required bool valuableVerified,
  }) {
    final bool isLostOwner =
        _isLostPost && _isPostOwner;

    final String description;

    if (valuableVerified) {
      description =
          'Ownership is verified. Continue only when you are ready to start the item return process.';
    } else if (isLostOwner) {
      description =
          'Select the Found Item that belongs to your Lost Item. The app will not automatically match posts.';
    } else {
      description =
          'If this is your Lost Item, select your Lost Item post to start the return process. The app will not automatically match posts.';
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.teal.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color:
                    Colors.teal.shade700,
              ),
              const SizedBox(
                width: 9,
              ),
              const Expanded(
                child: Text(
                  'Item Return',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isStartingRecovery
                      ? null
                      : _continueItemReturn,
              icon: _isStartingRecovery
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
                          .arrow_forward_rounded,
                    ),
              label: Text(
                _isStartingRecovery
                    ? 'Starting Return...'
                    : valuableVerified
                        ? 'Continue Item Return'
                        : 'Start Item Return',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOVERY STATUS CARD
  // ============================================================

  Widget _buildRecoveryStatusCard() {
    final bool isOwner =
        _isCurrentRecoveryOwner;

    final bool isFinder =
        _isCurrentRecoveryFinder;

    final bool ownerDone =
        _ownerConfirmed;

    final bool finderDone =
        _finderConfirmed;

    String title;
    String description;
    String buttonText;

    if (isFinder) {
      if (finderDone) {
        title = 'Return Confirmation Submitted';
        description =
            'You confirmed that the item has been returned. The owner must also confirm that the item was received.';
        buttonText =
            'View Recovery Confirmation';
      } else {
        title = 'Item Return in Progress';
        description =
            'The owner has started the return process. Confirm when the item has been returned to the owner.';
        buttonText =
            'Confirm Item Returned';
      }
    } else if (isOwner) {
      if (ownerDone) {
        title = 'Receipt Confirmation Submitted';
        description =
            'You confirmed that you received the item. The finder must also confirm the return.';
        buttonText =
            'View Recovery Confirmation';
      } else {
        title = 'Item Return in Progress';
        description =
            'The recovery request has started. Confirm after you receive the item from the finder.';
        buttonText =
            'Confirm Item Received';
      }
    } else {
      title = 'Recovery in Progress';
      description =
          'This recovery request is currently waiting for the owner and finder to complete their confirmations.';
      buttonText =
          'View Recovery Confirmation';
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync_alt_rounded,
                color:
                    Colors.blue.shade700,
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _buildConfirmationStatusRow(
            icon: Icons.person_outline,
            label: 'Owner',
            confirmed: ownerDone,
          ),

          const SizedBox(
            height: 8,
          ),

          _buildConfirmationStatusRow(
            icon: Icons.person_search_outlined,
            label: 'Finder',
            confirmed: finderDone,
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  _isStartingRecovery
                      ? null
                      : () =>
                          _openRecoveryConfirmation(
                        _recoveryId,
                      ),
              icon: const Icon(
                Icons.open_in_new_rounded,
              ),
              label: Text(
                buttonText,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRMATION STATUS ROW
  // ============================================================

  Widget _buildConfirmationStatusRow({
    required IconData icon,
    required String label,
    required bool confirmed,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: confirmed
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: confirmed
                ? Colors.green.shade700
                : Colors.grey.shade600,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Icon(
            confirmed
                ? Icons.check_circle
                : Icons.schedule,
            size: 19,
            color: confirmed
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            confirmed
                ? 'Confirmed'
                : 'Waiting',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: confirmed
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED CARD
  // ============================================================

  Widget _buildCompletedCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 34,
            color:
                Colors.green.shade700,
          ),
          const SizedBox(
            width: 12,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Both users confirmed the item return. This recovery has been completed.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIVATE DETAIL
  // ============================================================

  Widget _buildPrivateDetail(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.green.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Colors.green.shade700,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    Colors.teal.shade700,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color:
                Colors.grey.shade600,
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color: valueColor ??
                    Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildImagePlaceholder({
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 50,
        color: Colors.grey.shade500,
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}