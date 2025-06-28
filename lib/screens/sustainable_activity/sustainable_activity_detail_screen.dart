// lib/screens/sustainable_activity/sustainable_activity_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/models/app_user.dart'; // Import AppUser
import 'package:green_market/models/activity_report.dart';
import 'package:green_market/models/activity_review.dart'; // Import ActivityReview
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase User
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SustainableActivityDetailScreen extends StatefulWidget {
  final SustainableActivity activity;

  const SustainableActivityDetailScreen({super.key, required this.activity});

  @override
  State<SustainableActivityDetailScreen> createState() =>
      _SustainableActivityDetailScreenState();
}

class _SustainableActivityDetailScreenState
    extends State<SustainableActivityDetailScreen> {
  @override // Corrected: Use currentUser
  Widget build(BuildContext context) {
    return _SustainableActivityDetailScreenContent(
        activity: widget.activity, user: FirebaseAuth.instance.currentUser);
  }
}

class _SustainableActivityDetailScreenContent extends StatefulWidget {
  final SustainableActivity activity;
  final User? user; // Corrected: Use Firebase User

  const _SustainableActivityDetailScreenContent(
      {required this.activity, this.user});

  @override
  State<_SustainableActivityDetailScreenContent> createState() =>
      _SustainableActivityDetailScreenContentState();
}

class _SustainableActivityDetailScreenContentState
    extends State<_SustainableActivityDetailScreenContent> {
  bool _isJoining = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    if (widget.user == null) return;
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final joined = await firebaseService.hasJoinedSustainableActivity(
        widget.activity.id, widget.user!.uid);
    if (mounted) {
      setState(() {
        _hasJoined = joined;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider =
        Provider.of<UserProvider>(context); // Corrected: Use currentUser

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('เข้าร่วมกิจกรรม'),
          onPressed: userProvider.currentUser !=
                      null && // Corrected: Use currentUser
                  !_isJoining &&
                  !_hasJoined
              ? () async {
                  setState(() {
                    _isJoining = true;
                  });
                  try {
                    await firebaseService.joinSustainableActivity(
                        // Corrected: Already correct
                        widget.activity.id,
                        userProvider.currentUser!.id);
                    if (mounted) {
                      setState(() {
                        _hasJoined = true;
                        _isJoining = false;
                      });
                      showAppSnackBar(context, 'เข้าร่วมกิจกรรมสำเร็จ!',
                          isSuccess: true);
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isJoining = false;
                      });
                      showAppSnackBar(context,
                          'เกิดข้อผิดพลาดในการเข้าร่วม: ${e.toString()}',
                          isError: true);
                    }
                  }
                }
              : null, // Disable button if not logged in, already joined, or loading
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _hasJoined ? Colors.grey : theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.activity.title,
                style: const TextStyle(
                  shadows: [
                    Shadow(blurRadius: 8.0, color: Colors.black54),
                  ],
                ),
              ),
              background: Image.network(
                widget.activity.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child:
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text('จัดโดย: ${widget.activity.organizerName}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoChips(context, widget.activity),
                  const Divider(height: 32),
                  _buildDetailSection(
                      context, 'เกี่ยวกับกิจกรรม', widget.activity.description),
                  const SizedBox(height: 24),
                  _buildParticipantsSection(context),
                  const SizedBox(height: 24),
                  _buildReviewsSection(context),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.flag_outlined, color: Colors.red),
                      label: const Text('รายงานกิจกรรมนี้',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => _showReportDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips(BuildContext context, SustainableActivity activity) {
    final theme = Theme.of(context);
    final daysLeft = activity.endDate.difference(DateTime.now()).inDays;
    final daysLeftText = daysLeft >= 0 ? '$daysLeft วัน' : 'สิ้นสุดแล้ว';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoChip(context, 'จังหวัด', activity.province,
            Icons.location_on_outlined, theme.colorScheme.primary),
        _buildInfoChip(
            context,
            'วันที่',
            '${DateFormat('dd MMM').format(activity.startDate)} - ${DateFormat('dd MMM yyyy').format(activity.endDate)}',
            Icons.calendar_today_outlined,
            theme.colorScheme.primary),
        _buildInfoChip(context, 'เหลือ', daysLeftText, Icons.timer_outlined,
            theme.colorScheme.primary),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value,
      IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(content, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildParticipantsSection(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return Column(
      // Corrected: Already correct
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ผู้เข้าร่วมกิจกรรม', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8), // Corrected: Already correct
        StreamBuilder<List<AppUser>>(
          // Corrected: Change to AppUser
          stream:
              firebaseService.getParticipantsForActivity(widget.activity.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('ยังไม่มีผู้เข้าร่วมกิจกรรมนี้');
            }
            final participants = snapshot.data!;
            return Wrap(
              spacing: 8.0,
              runSpacing: 8.0, // Corrected: Already correct
              children: participants.map((user) {
                return Chip(
                  avatar: CircleAvatar(
                    // Corrected: Already correct
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(user.displayName?.substring(0, 1) ?? '?',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ),
                  label: Text(user.displayName ?? user.email),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context,
        listen: false); // Corrected: Use currentUser
    final TextEditingController reasonController = TextEditingController();

    if (userProvider.currentUser == null) {
      showAppSnackBar(context, 'กรุณาเข้าสู่ระบบเพื่อรายงานกิจกรรม',
          isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('รายงานกิจกรรม'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'เหตุผลในการรายงาน',
              hintText: 'เช่น กิจกรรมไม่เหมาะสม, ข้อมูลไม่ถูกต้อง',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isNotEmpty) {
                  try {
                    await firebaseService.addActivityReport({
                      'activityId': widget.activity.id,
                      'activityTitle': widget.activity.title,
                      'reporterId': userProvider.currentUser!.id,
                      'reporterName': userProvider.currentUser!.displayName ??
                          userProvider.currentUser!.email,
                      'reason': reasonController.text.trim(),
                      'status': 'pending',
                      'createdAt': Timestamp.now(),
                    });
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    showAppSnackBar(context, 'รายงานกิจกรรมสำเร็จ',
                        isSuccess: true);
                  } catch (e) {
                    showAppSnackBar(
                        context, 'เกิดข้อผิดพลาดในการรายงาน: ${e.toString()}',
                        isError: true);
                  }
                } else {
                  showAppSnackBar(context, 'กรุณากรอกเหตุผลในการรายงาน',
                      isError: true);
                }
              },
              child: const Text('ส่งรายงาน'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('รีวิวกิจกรรม', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () => _showReviewDialog(context),
              child: const Text('เขียนรีวิว'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Stream.fromFuture(
              firebaseService.getReviewsForActivity(widget.activity.id)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('ยังไม่มีรีวิวสำหรับกิจกรรมนี้');
            }
            final reviews = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review['userName'] ?? 'ไม่ระบุผู้ใช้',
                                style: theme.textTheme.titleMedium),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  // Corrected: Already correct
                                  i < (review['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(review['comment'] ?? '',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                            DateFormat('dd MMM yyyy').format(
                                (review['createdAt'] as Timestamp).toDate()),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showReviewDialog(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context,
        listen: false); // Corrected: Use currentUser
    final TextEditingController reviewController = TextEditingController();
    int rating = 3; // Default rating

    if (userProvider.currentUser == null) {
      showAppSnackBar(context, 'กรุณาเข้าสู่ระบบเพื่อเขียนรีวิว',
          isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('เขียนรีวิวกิจกรรม'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      decoration: const InputDecoration(
                        labelText: 'ความคิดเห็นของคุณ',
                        hintText: 'แบ่งปันประสบการณ์ของคุณเกี่ยวกับกิจกรรมนี้',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reviewController.text.trim().isNotEmpty) {
                      try {
                        // Corrected: Already correct
                        await firebaseService.addActivityReview({
                          'activityId': widget.activity.id,
                          'userId': userProvider.currentUser!.id,
                          'userName': userProvider.currentUser!
                                  .displayName ?? // Corrected: Use null-aware operator
                              userProvider.currentUser!.email,
                          'rating': rating.toDouble(),
                          'comment': reviewController.text.trim(),
                          'createdAt': Timestamp.now(),
                        });
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        showAppSnackBar(context, 'ส่งรีวิวสำเร็จ!',
                            isSuccess: true);
                      } catch (e) {
                        showAppSnackBar(context,
                            'เกิดข้อผิดพลาดในการส่งรีวิว: ${e.toString()}',
                            isError: true);
                      }
                    } else {
                      showAppSnackBar(context, 'กรุณากรอกความคิดเห็นของคุณ',
                          isError: true);
                    }
                  },
                  child: const Text('ส่งรีวิว'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
