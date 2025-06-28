// lib/models/user_role.dart

/// Defines the possible roles a user can have within the application.
enum UserRole {
  admin,
  seller,
  buyer,
  unknown, // Fallback for errors or unauthenticated users
}

/// Utility extension to handle conversion between String and UserRole.
extension UserRoleExtension on String {
  UserRole toUserRole() {
    switch (this) {
      case 'admin':
        return UserRole.admin;
      case 'seller':
        return UserRole.seller;
      default:
        return UserRole.buyer; // Default to buyer if role is not admin/seller
    }
  }
}
