import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_preferences_provider.dart';
import '../../models/notification_preferences.dart';
import '../../theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationPreferencesProvider>().initialize();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าการแจ้งเตือน'), elevation: 0),
      body: Consumer<NotificationPreferencesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final prefs = provider.preferences;
          if (prefs == null) {
            return const Center(child: Text('ไม่สามารถโหลดการตั้งค่าได้'));
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChannelsSection(prefs),
              const SizedBox(height: 24),
              _buildCategoriesSection(prefs),
              const SizedBox(height: 24),
              _buildQuietHoursSection(prefs),
              const SizedBox(height: 24),
              _buildAdvancedSection(prefs),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildChannelsSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ช่องทางการแจ้งเตือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildChannelSwitch(' Push Notification', prefs.channels.pushNotifications),
            _buildChannelSwitch(' Email', prefs.channels.emailNotifications),
            _buildChannelSwitch(' SMS', prefs.channels.smsNotifications),
            _buildChannelSwitch(' In-App', prefs.channels.inAppNotifications),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChannelSwitch(String label, bool value) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: null,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildCategoriesSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('หมวดหมู่การแจ้งเตือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCategoryCard(' คำสั่งซื้อ', prefs.categories.orderUpdates),
            _buildCategoryCard(' โปรโมชั่น', prefs.categories.promotions),
            _buildCategoryCard(' Eco Rewards', prefs.categories.ecoRewards),
            _buildCategoryCard(' Flash Sales', prefs.categories.flashSales),
            _buildCategoryCard(' สินค้าใหม่', prefs.categories.newProducts),
            _buildCategoryCard(' ข้อความจากผู้ขาย', prefs.categories.sellerMessages),
            _buildCategoryCard(' ประกาศระบบ', prefs.categories.systemAnnouncements),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(String label, bool enabled) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: enabled ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
      child: SwitchListTile(
        title: Text(label, style: TextStyle(fontWeight: enabled ? FontWeight.bold : FontWeight.normal)),
        value: enabled,
        onChanged: null,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
  
  Widget _buildQuietHoursSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(' โหมดเงียบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('เปิดใช้งานโหมดเงียบ'),
              subtitle: Text(prefs.quietHours.enabled 
                ? 'เวลา ${_formatTimeOfDay(prefs.quietHours.startTime)} - ${_formatTimeOfDay(prefs.quietHours.endTime)}'
                : 'ปิดใช้งาน'),
              trailing: Switch(
                value: prefs.quietHours.enabled,
                onChanged: null,
                activeColor: AppColors.primary,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdvancedSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(' ตั้งค่าขั้นสูง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('จำนวนสูงสุดต่อวัน'),
              subtitle: Text('${prefs.frequency.maxPerDay} ครั้ง'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('จำนวนสูงสุดต่อชั่วโมง'),
              subtitle: Text('${prefs.frequency.maxPerHour} ครั้ง'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('รวมการแจ้งเตือน'),
              subtitle: Text(prefs.frequency.bundleMode ? 'เปิดใช้งาน' : 'ปิดใช้งาน'),
              trailing: Switch(
                value: prefs.frequency.bundleMode,
                onChanged: null,
                activeColor: AppColors.primary,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}