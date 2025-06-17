// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  String? _sellerApplicationStatus; // 'none', 'pending', 'approved', 'rejected'
  String? _userEmail;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _userEmail = FirebaseAuth.instance.currentUser?.email;
    if (_currentUserId != null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userData = await firebaseService.getUserData(_currentUserId!);
      if (mounted && userData != null) {
        _displayNameController.text = userData['displayName'] as String? ?? '';
        _phoneNumberController.text = userData['phoneNumber'] as String? ?? '';
        _sellerApplicationStatus =
            userData['sellerApplicationStatus'] as String? ?? 'none';
      } else if (mounted) {
        _sellerApplicationStatus = 'none'; // Default if no data or status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์: ${e.toString()}')),
        );
        _sellerApplicationStatus = 'none'; // Default on error
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.updateUserProfile(
        _currentUserId!,
        _displayNameController.text.trim(),
        _phoneNumberController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกโปรไฟล์สำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('เกิดข้อผิดพลาดในการบันทึกโปรไฟล์: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestToBeSeller() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.requestToBeSeller(_currentUserId!);
      // Reload profile to get updated status
      await _loadUserProfile(); // This will set _isLoading to false eventually
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('ส่งคำขอเปิดร้านค้าเรียบร้อยแล้ว โปรดรอการอนุมัติ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'เกิดข้อผิดพลาดในการส่งคำขอเปิดร้านค้า: ${e.toString()}')),
        );
      }
      // Ensure isLoading is reset even on error if _loadUserProfile isn't called or fails early
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    // No finally block for _isLoading here, as _loadUserProfile handles it.
    // If _requestToBeSeller itself fails before calling _loadUserProfile,
    // the catch block above will handle setting _isLoading to false.
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Widget _buildSellerStatusSection() {
    // If profile is still loading initial data, show a small loader.
    // Note: _isLoading is also true during _requestToBeSeller and _updateUserProfile.
    // We might need a more specific loading state for the seller status section if
    // _loadUserProfile is the only time this section should show a loader.
    // For now, this check is broad.
    if (_isLoading && _sellerApplicationStatus == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
            child: SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator())),
      );
    }

    switch (_sellerApplicationStatus) {
      case 'approved':
        return Text('สถานะร้านค้า: คุณเป็นผู้ขายแล้ว',
            style: AppTextStyles
                .bodyGreen); // Ensure AppTextStyles.bodyGreen exists or use TextStyle(color: Colors.green)
      case 'pending':
        return Text('สถานะคำขอเปิดร้าน: รอการอนุมัติ',
            style: AppTextStyles
                .bodyYellow); // Ensure AppTextStyles.bodyYellow exists or use TextStyle(color: Colors.orange)
      case 'rejected':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สถานะคำขอเปิดร้าน: ถูกปฏิเสธ',
                style: AppTextStyles
                    .bodyRed), // Ensure AppTextStyles.bodyRed exists or use TextStyle(color: Colors.red)
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestToBeSeller,
              child: const Text('ส่งคำขอเปิดร้านใหม่อีกครั้ง'),
            ),
          ],
        );
      case 'none':
      default: // Catches null or any other unexpected status
        return ElevatedButton(
          onPressed: _isLoading ? null : _requestToBeSeller,
          child: const Text('สมัครเป็นผู้ขาย'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      // This case should ideally be handled by routing logic before reaching this screen
      // if authentication is required.
      return Scaffold(
        appBar: AppBar(
            title: const Text('โปรไฟล์ผู้ใช้งาน', style: AppTextStyles.title),
            backgroundColor:
                AppColors.lightGrey), // Consider using theme's AppBar color
        body: Center(
            child: Text('กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์',
                style: AppTextStyles.body)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'โปรไฟล์ผู้ใช้งาน'), // Removed style for consistency with theme
        // backgroundColor: AppColors.lightGrey, // Use theme's AppBar color
        // iconTheme: IconThemeData(color: AppColors.darkGrey), // Use theme's icon color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Use theme's icon color
            onPressed: () async {
              // Show confirmation dialog before logging out
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('ออกจากระบบ'),
                    content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('ยกเลิก'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text('ยืนยัน',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                // Use UserProvider for sign out to ensure state is managed centrally
                await Provider.of<FirebaseService>(context, listen: false)
                    .signOut();
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (context) => AuthScreen()), // Replace with your Auth/Login Screen
                //   (Route<dynamic> route) => false,
                // );
              }
            },
          ),
        ],
      ),
      body: _isLoading &&
              _sellerApplicationStatus ==
                  null // Show main loader only if initial data hasn't loaded
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ข้อมูลบัญชี',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.primaryGreen)),
                    const SizedBox(height: 16),
                    Text('อีเมล: ${_userEmail ?? "N/A"}',
                        style: AppTextStyles.body),
                    const SizedBox(height: 12),
                    _buildSellerStatusSection(), // Seller status or request button
                    const SizedBox(height: 24),
                    Text('ข้อมูลโปรไฟล์',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.primaryGreen)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อที่แสดง',
                        // border: OutlineInputBorder() // Using theme's default
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อที่แสดง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        // border: OutlineInputBorder() // Using theme's default
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[0-9]{9,10}$')
                              .hasMatch(value.trim())) {
                            return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง (9-10 หลัก)';
                          }
                        }
                        return null; // Phone number can be optional
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateUserProfile,
                        // style: ElevatedButton.styleFrom(
                        //     backgroundColor: AppColors.primaryGreen), // Use theme's button style
                        child: _isLoading &&
                                _sellerApplicationStatus !=
                                    null // Show smaller loader on button if not initial load
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.white),
                              )
                            : Text('บันทึกโปรไฟล์',
                                style: AppTextStyles
                                    .subtitle // Removed color to use theme
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
