// lib/screens/admin/admin_rewards_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:green_market/models/eco_reward.dart';
import 'package:green_market/models/reward_redemption.dart'
    as reward_redemption;
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';

class AdminRewardsManagementScreen extends StatefulWidget {
  const AdminRewardsManagementScreen({super.key});

  @override
  State<AdminRewardsManagementScreen> createState() =>
      _AdminRewardsManagementScreenState();
}

class _AdminRewardsManagementScreenState
    extends State<AdminRewardsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text(
          'จัดการรางวัล Eco Coins',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF6F00),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: 'เพิ่มรางวัล'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'จัดการรางวัล'),
            Tab(icon: Icon(Icons.history), text: 'การแลกรางวัล'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddRewardTab(),
          _buildManageRewardsTab(),
          _buildRedemptionsTab(),
        ],
      ),
    );
  }

  Widget _buildAddRewardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AddRewardForm(),
    );
  }

  Widget _buildManageRewardsTab() {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return StreamBuilder<List<EcoReward>>(
      stream: firebaseService.getEcoRewards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีรางวัลในระบบ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _buildManageRewardCard(reward);
          },
        );
      },
    );
  }

  Widget _buildManageRewardCard(EcoReward reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปรางวัล
          if (reward.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                reward.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reward.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: reward.isAvailable,
                      onChanged: (value) =>
                          _toggleRewardAvailability(reward, value),
                      activeColor: const Color(0xFF43A047),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reward.description,
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFB8860B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFFB8860B),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.requiredCoins} เหรียญ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB8860B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (reward.quantity > 0)
                      Text(
                        'เหลือ ${reward.remainingQuantity}/${reward.quantity}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editReward(reward),
                        icon: const Icon(Icons.edit),
                        label: const Text('แก้ไข'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteReward(reward),
                        icon: const Icon(Icons.delete),
                        label: const Text('ลบ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionsTab() {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return StreamBuilder<List<dynamic>>(
      stream: firebaseService.getAllRedemptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final redemptions = (snapshot.data ?? [])
            .map(
              (item) => item is reward_redemption.RewardRedemption
                  ? item
                  : reward_redemption.RewardRedemption.fromMap(
                      item as Map<String, dynamic>,
                      item['id'] ?? '',
                    ),
            )
            .toList();

        if (redemptions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีการแลกรางวัล',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final redemption = redemptions[index];
            return _buildAdminRedemptionCard(redemption);
          },
        );
      },
    );
  }

  Widget _buildAdminRedemptionCard(
    reward_redemption.RewardRedemption redemption,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(redemption.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(redemption.status),
            color: _getStatusColor(redemption.status),
            size: 20,
          ),
        ),
        title: Text(
          redemption.rewardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ผู้ใช้: ${redemption.userId}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleRedemptionAction(redemption, action),
          itemBuilder: (context) => [
            if (redemption.status == 'pending') ...[
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('อนุมัติ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('ยกเลิก'),
                  ],
                ),
              ),
            ],
            if (redemption.status == 'approved')
              const PopupMenuItem(
                value: 'deliver',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('ส่งแล้ว'),
                  ],
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, size: 16, color: Color(0xFFB8860B)),
                    const SizedBox(width: 4),
                    Text('เหรียญที่ใช้: ${redemption.coinsUsed}'),
                    const Spacer(),
                    Text('วันที่: ${_formatDate(redemption.redeemedAt)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'สถานะ: ${_getStatusText(redemption.status)}',
                  style: TextStyle(
                    color: _getStatusColor(redemption.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (redemption.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'หมายเหตุ: ${redemption.notes}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRewardAvailability(
    EcoReward reward,
    bool isAvailable,
  ) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      await firebaseService.updateEcoReward(reward.id, {
        'isAvailable': isAvailable,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable ? 'เปิดใช้งานรางวัลแล้ว' : 'ปิดใช้งานรางวัลแล้ว',
          ),
          backgroundColor: const Color(0xFF43A047),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editReward(EcoReward reward) {
    // TODO: Navigate to edit reward screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขรางวัล'),
        content: const Text('ฟีเจอร์แก้ไขรางวัลจะเพิ่มในเวอร์ชันต่อไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReward(EcoReward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบรางวัล "${reward.title}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebaseService = Provider.of<FirebaseService>(
          context,
          listen: false,
        );
        await firebaseService.deleteEcoReward(reward.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรางวัลสำเร็จ'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRedemptionAction(
    reward_redemption.RewardRedemption redemption,
    String action,
  ) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );

      switch (action) {
        case 'approve':
          await firebaseService.updateRedemptionStatus(
            redemption.id,
            'approved',
          );
          break;
        case 'cancel':
          await firebaseService.updateRedemptionStatus(
            redemption.id,
            'cancelled',
          );
          // คืนเหรียญให้ผู้ใช้
          await firebaseService.addEcoCoins(
            redemption.userId,
            redemption.coinsUsed.toDouble(),
            'คืนเหรียญจากการยกเลิกรางวัล: ${redemption.rewardTitle}',
          );
          break;
        case 'deliver':
          await firebaseService.updateRedemptionStatus(
            redemption.id,
            'delivered',
          );
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตสถานะสำเร็จ'),
          backgroundColor: Color(0xFF43A047),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'approved':
        return const Color(0xFF2196F3);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'delivered':
        return 'ส่งแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Widget สำหรับเพิ่มรางวัลใหม่
class _AddRewardForm extends StatefulWidget {
  @override
  State<_AddRewardForm> createState() => _AddRewardFormState();
}

class _AddRewardFormState extends State<_AddRewardForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requiredCoinsController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedType = 'physical';
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUnlimited = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requiredCoinsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String> _uploadImage() async {
    if (_selectedImage == null) return '';

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('eco_rewards')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await _uploadImage();

      final reward = EcoReward(
        id: '', // จะถูกสร้างใน Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        requiredCoins: double.parse(_requiredCoinsController.text),
        rewardType: _selectedType,
        quantity: _isUnlimited ? 0 : int.parse(_quantityController.text),
        redeemedCount: 0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      await firebaseService.createEcoReward(reward);

      // ล้างฟอร์ม
      _titleController.clear();
      _descriptionController.clear();
      _requiredCoinsController.clear();
      _quantityController.clear();
      setState(() {
        _selectedImage = null;
        _selectedType = 'physical';
        _isUnlimited = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มรางวัลสำเร็จ'),
          backgroundColor: Color(0xFF43A047),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปรางวัล
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : InkWell(
                    onTap: _pickImage,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'เพิ่มรูปรางวัล',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit),
                label: const Text('เปลี่ยนรูป'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ชื่อรางวัล
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'ชื่อรางวัล *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty == true) return 'กรุณากรอกชื่อรางวัล';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // คำอธิบาย
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'คำอธิบายรางวัล *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty == true) return 'กรุณากรอกคำอธิบาย';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // จำนวนเหรียญที่ต้องใช้
          TextFormField(
            controller: _requiredCoinsController,
            decoration: const InputDecoration(
              labelText: 'จำนวนเหรียญที่ต้องใช้ *',
              border: OutlineInputBorder(),
              suffixText: 'เหรียญ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty == true) return 'กรุณากรอกจำนวนเหรียญ';
              if (int.tryParse(value!) == null) return 'กรุณากรอกตัวเลข';
              if (int.parse(value) <= 0) return 'จำนวนเหรียญต้องมากกว่า 0';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ประเภทรางวัล
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'ประเภทรางวัล',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'physical', child: Text('ของจริง')),
              DropdownMenuItem(value: 'digital', child: Text('ดิจิทัล')),
              DropdownMenuItem(value: 'discount', child: Text('ส่วนลด')),
              DropdownMenuItem(value: 'service', child: Text('บริการ')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // จำนวนรางวัล
          Row(
            children: [
              Checkbox(
                value: _isUnlimited,
                onChanged: (value) {
                  setState(() {
                    _isUnlimited = value!;
                    if (_isUnlimited) {
                      _quantityController.clear();
                    }
                  });
                },
              ),
              const Text('จำนวนไม่จำกัด'),
            ],
          ),

          if (!_isUnlimited) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'จำนวนรางวัล *',
                border: OutlineInputBorder(),
                suffixText: 'ชิ้น',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (!_isUnlimited) {
                  if (value?.isEmpty == true) return 'กรุณากรอกจำนวนรางวัล';
                  if (int.tryParse(value!) == null) return 'กรุณากรอกตัวเลข';
                  if (int.parse(value) <= 0) return 'จำนวนต้องมากกว่า 0';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 32),

          // ปุ่มบันทึก
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'เพิ่มรางวัล',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
