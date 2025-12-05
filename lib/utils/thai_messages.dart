// lib/utils/thai_messages.dart
// ไลบรารีสำหรับข้อความภาษาไทยทั้งหมดในระบบ
// รวม error messages, success messages, validation messages

class ThaiMessages {
  // ============================================================================
  // AUTHENTICATION MESSAGES
  // ============================================================================
  static const authLoginRequired = 'กรุณาเข้าสู่ระบบก่อนทำรายการ';
  static const authLoginSuccess = 'เข้าสู่ระบบสำเร็จ';
  static const authLogoutSuccess = 'ออกจากระบบเรียบร้อยแล้ว';
  static const authEmailRequired = 'กรุณากรอกอีเมล';
  static const authPasswordRequired = 'กรุณากรอกรหัสผ่าน';
  static const authInvalidEmail = 'รูปแบบอีเมลไม่ถูกต้อง';
  static const authWeakPassword = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
  static const authEmailInUse = 'อีเมลนี้ถูกใช้งานแล้ว';
  static const authUserNotFound = 'ไม่พบบัญชีผู้ใช้นี้';
  static const authWrongPassword = 'รหัสผ่านไม่ถูกต้อง';
  static const authNetworkError = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';

  // ============================================================================
  // PROFILE MESSAGES
  // ============================================================================
  static const profileUpdateSuccess = 'อัปเดตโปรไฟล์เรียบร้อยแล้ว';
  static const profileUpdateError = 'ไม่สามารถอัปเดตโปรไฟล์ได้';
  static const profileLoadError = 'เกิดข้อผิดพลาดในการโหลดโปรไฟล์';
  static const profilePictureChangeSuccess = 'เปลี่ยนรูปโปรไฟล์เรียบร้อยแล้ว';
  static const profilePictureChangeError = 'ไม่สามารถเปลี่ยนรูปโปรไฟล์ได้';
  static const coverPhotoChangeSuccess = 'เปลี่ยนรูปภาพปกเรียบร้อยแล้ว';
  static const coverPhotoChangeError = 'ไม่สามารถอัปโหลดรูปภาพปกได้';
  static const profileIncomplete = 'กรุณากรอกข้อมูลโปรไฟล์ให้ครบถ้วน';

  // ============================================================================
  // FOLLOW SYSTEM MESSAGES
  // ============================================================================
  static const followSuccess = 'ติดตามแล้ว';
  static const unfollowSuccess = 'เลิกติดตามแล้ว';
  static const followError = 'ไม่สามารถดำเนินการได้';
  static const cannotFollowSelf = 'ไม่สามารถติดตามตัวเองได้';

  // ============================================================================
  // POST MESSAGES
  // ============================================================================
  static const postCreateSuccess = 'โพสต์เรียบร้อยแล้ว';
  static const postCreateError = 'ไม่สามารถโพสต์ได้';
  static const postUpdateSuccess = 'อัปเดตโพสต์เรียบร้อยแล้ว';
  static const postUpdateError = 'ไม่สามารถอัปเดตโพสต์ได้';
  static const postDeleteSuccess = 'ลบโพสต์เรียบร้อยแล้ว';
  static const postDeleteError = 'ไม่สามารถลบโพสต์ได้';
  static const postLoadError = 'ไม่สามารถโหลดโพสต์ได้';
  static const postContentRequired = 'กรุณากรอกเนื้อหาโพสต์';
  static const postSaveSuccess = 'บันทึกโพสต์แล้ว';
  static const postUnsaveSuccess = 'ยกเลิกการบันทึกโพสต์แล้ว';
  static const postReportSuccess = 'รายงานโพสต์เรียบร้อยแล้ว';

  // ============================================================================
  // MEDIA UPLOAD MESSAGES
  // ============================================================================
  static const mediaSelectImage = 'เลือกรูปภาพ';
  static const mediaSelectVideo = 'เลือกวิดีโอ';
  static const mediaSelectError = 'ไม่สามารถเลือกไฟล์ได้';
  static const mediaUploadSuccess = 'อัปโหลดสำเร็จ';
  static const mediaUploadError = 'ไม่สามารถอัปโหลดได้';
  static const mediaUploadProgress = 'กำลังอัปโหลด...';
  static const mediaImageTooLarge = 'รูปภาพใหญ่เกินไป (ไม่เกิน 10 MB)';
  static const mediaVideoTooLarge = 'วิดีโอใหญ่เกินไป (ไม่เกิน 100 MB)';
  static const mediaVideoTooLong = 'วิดีโอยาวเกินไป (ไม่เกิน 60 วินาที)';
  static const mediaTooManyImages = 'เลือกรูปภาพได้ไม่เกิน 10 รูป';
  static const mediaCompressionError = 'ไม่สามารถบีบอัดไฟล์ได้';
  static const mediaDeleteSuccess = 'ลบไฟล์เรียบร้อยแล้ว';

  // ============================================================================
  // VIDEO PLAYER MESSAGES
  // ============================================================================
  static const videoLoadError = 'ไม่สามารถโหลดวิดีโอได้';
  static const videoPlayError = 'ไม่สามารถเล่นวิดีโอได้';
  static const videoBuffering = 'กำลังโหลด...';
  static const videoPaused = 'หยุดชั่วคราว';

  // ============================================================================
  // COMMENT MESSAGES
  // ============================================================================
  static const commentAddSuccess = 'แสดงความคิดเห็นแล้ว';
  static const commentAddError = 'ไม่สามารถแสดงความคิดเห็นได้';
  static const commentDeleteSuccess = 'ลบความคิดเห็นแล้ว';
  static const commentDeleteError = 'ไม่สามารถลบความคิดเห็นได้';
  static const commentRequired = 'กรุณากรอกความคิดเห็น';
  static const commentLoadError = 'ไม่สามารถโหลดความคิดเห็นได้';

  // ============================================================================
  // LIKE MESSAGES
  // ============================================================================
  static const likeSuccess = 'ถูกใจแล้ว';
  static const unlikeSuccess = 'ยกเลิกการถูกใจแล้ว';
  static const likeError = 'ไม่สามารถกดถูกใจได้';

  // ============================================================================
  // SHARE MESSAGES
  // ============================================================================
  static const shareSuccess = 'แชร์เรียบร้อยแล้ว';
  static const shareError = 'ไม่สามารถแชร์ได้';
  static const shareCopyLink = 'คัดลอกลิงก์แล้ว';

  // ============================================================================
  // STORY MESSAGES
  // ============================================================================
  static const storyCreateSuccess = 'เพิ่มสториเรียบร้อยแล้ว';
  static const storyCreateError = 'ไม่สามารถเพิ่มสториได้';
  static const storyDeleteSuccess = 'ลบสториเรียบร้อยแล้ว';
  static const storyLoadError = 'ไม่สามารถโหลดสториได้';

  // ============================================================================
  // GROUP/COMMUNITY MESSAGES
  // ============================================================================
  static const groupCreateSuccess = 'สร้างกลุ่มเรียบร้อยแล้ว';
  static const groupCreateError = 'ไม่สามารถสร้างกลุ่มได้';
  static const groupJoinSuccess = 'เข้าร่วมกลุ่มแล้ว';
  static const groupLeaveSuccess = 'ออกจากกลุ่มแล้ว';
  static const groupSearchEmpty = 'ไม่พบกลุ่ม';
  static const groupNameRequired = 'กรุณากรอกชื่อกลุ่ม';

  // ============================================================================
  // CHAT MESSAGES
  // ============================================================================
  static const chatSendSuccess = 'ส่งข้อความแล้ว';
  static const chatSendError = 'ไม่สามารถส่งข้อความได้';
  static const chatLoadError = 'ไม่สามารถโหลดแชทได้';
  static const chatMessageRequired = 'กรุณากรอกข้อความ';
  static const chatDeleteSuccess = 'ลบข้อความแล้ว';

  // ============================================================================
  // SEARCH MESSAGES
  // ============================================================================
  static const searchNoResults = 'ไม่พบผลการค้นหา';
  static const searchError = 'ไม่สามารถค้นหาได้';
  static const searchQueryRequired = 'กรุณากรอกคำค้นหา';

  // ============================================================================
  // NETWORK MESSAGES
  // ============================================================================
  static const networkError = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
  static const networkTimeout = 'หมดเวลาการเชื่อมต่อ';
  static const networkRetry = 'กรุณาลองใหม่อีกครั้ง';

  // ============================================================================
  // GENERAL MESSAGES
  // ============================================================================
  static const success = 'สำเร็จ';
  static const error = 'เกิดข้อผิดพลาด';
  static const loading = 'กำลังโหลด...';
  static const saving = 'กำลังบันทึก...';
  static const processing = 'กำลังดำเนินการ...';
  static const cancel = 'ยกเลิก';
  static const confirm = 'ยืนยัน';
  static const delete = 'ลบ';
  static const edit = 'แก้ไข';
  static const save = 'บันทึก';
  static const retry = 'ลองใหม่';
  static const done = 'เสร็จสิ้น';
  static const unknownError = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  static const comingSoon = 'เร็วๆ นี้';
  static const featureComingSoon = 'ฟีเจอร์นี้กำลังพัฒนา';
  static const noData = 'ไม่มีข้อมูล';
  static const tryAgain = 'ลองอีกครั้ง';

  // ============================================================================
  // VALIDATION MESSAGES
  // ============================================================================
  static const validationRequired = 'กรุณากรอกข้อมูลให้ครบถ้วน';
  static const validationEmailInvalid = 'รูปแบบอีเมลไม่ถูกต้อง';
  static const validationPhoneInvalid = 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
  static const validationUrlInvalid = 'รูปแบบ URL ไม่ถูกต้อง';
  static const validationTooShort = 'ข้อมูลสั้นเกินไป';
  static const validationTooLong = 'ข้อมูลยาวเกินไป';

  // ============================================================================
  // PERMISSION MESSAGES
  // ============================================================================
  static const permissionCameraRequired = 'ต้องการสิทธิ์เข้าถึงกล้อง';
  static const permissionStorageRequired = 'ต้องการสิทธิ์เข้าถึงที่เก็บข้อมูล';
  static const permissionDenied = 'ไม่ได้รับอนุญาตให้เข้าถึง';
  static const permissionSettingsRedirect = 'กรุณาเปิดสิทธิ์ในการตั้งค่า';

  // ============================================================================
  // ECO COINS MESSAGES
  // ============================================================================
  static const ecoCoinsEarned = 'ได้รับ Eco Coins';
  static const ecoCoinsSpent = 'ใช้ Eco Coins';
  static const ecoCoinsInsufficient = 'Eco Coins ไม่เพียงพอ';
  static const ecoCoinsLoginReward = 'รับ Eco Coins จากการเข้าสู่ระบบ';

  // ============================================================================
  // PRODUCT MESSAGES
  // ============================================================================
  static const productAddSuccess = 'เพิ่มสินค้าเรียบร้อยแล้ว';
  static const productAddError = 'ไม่สามารถเพิ่มสินค้าได้';
  static const productDeleteSuccess = 'ลบสินค้าเรียบร้อยแล้ว';
  static const productOutOfStock = 'สินค้าหมด';
  static const productAddToCartSuccess = 'เพิ่มลงตะกร้าแล้ว';

  // ============================================================================
  // ORDER MESSAGES
  // ============================================================================
  static const orderPlaceSuccess = 'สั่งซื้อเรียบร้อยแล้ว';
  static const orderPlaceError = 'ไม่สามารถสั่งซื้อได้';
  static const orderCancelSuccess = 'ยกเลิกคำสั่งซื้อแล้ว';
  static const orderStatusUpdated = 'อัปเดตสถานะคำสั่งซื้อแล้ว';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// สร้างข้อความ error พร้อมรายละเอียด
  static String errorWithDetails(String message, String details) {
    return '$message: $details';
  }

  /// สร้างข้อความแสดงขนาดไฟล์
  static String fileSize(double sizeMB) {
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeMB.toStringAsFixed(2)} MB';
  }

  /// สร้างข้อความแสดงความยาววิดีโอ
  static String videoDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} นาที';
  }

  /// สร้างข้อความนับจำนวน
  static String countItems(int count, String itemName) {
    return '$itemName ($count)';
  }
}
