# Green Market - Code Documentation

## 📚 Architecture Overview

### MVVM Pattern
```
View (Screens/Widgets)
    ↕
ViewModel (Providers)
    ↕
Model (Services/Data)
```

### State Management: Provider Pattern
```dart
// main.dart
MultiProvider(
  providers: [
    Provider<FirebaseService>(create: (_) => _firebaseService),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    // ... other providers
  ],
  child: MyApp(),
)
```

## 🏗️ Core Components

### 1. Firebase Service (services/firebase_service.dart)
Central service for all Firebase operations.

```dart
class FirebaseService {
  // Authentication
  Future<User?> signInWithGoogle()
  Future<User?> signInWithEmailAndPassword(String email, String password)
  Future<void> signOut()
  
  // Database Operations
  Stream<List<Product>> getProducts()
  Stream<List<Order>> getOrdersByUserId(String userId)
  Future<void> createOrder(Order order)
  
  // User Management
  Future<AppUser?> getAppUser(String uid)
  Future<void> createAppUser(AppUser user)
}
```

### 2. User Provider (providers/user_provider.dart)
Manages user state and authentication.

```dart
class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  
  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSeller => _currentUser?.isSeller ?? false;
  
  // Methods
  Future<void> loadUserData(String uid)
  Future<void> refreshUserData()
  void clearUser()
}
```

### 3. Cart Provider (providers/cart_provider.dart)
Manages shopping cart state.

```dart
class CartProvider extends ChangeNotifier {
  Map<String, CartItem> _items = {};
  
  // Getters
  Map<String, CartItem> get items => {..._items};
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItemsInCart => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  // Methods
  void addItem(Product product, {int quantity = 1})
  void removeItem(String productId)
  void updateItemQuantity(String productId, int quantity)
  void clearCart()
}
```

## 📱 Screen Components

### 1. MyHomeScreen (screens/my_home_screen.dart)
User dashboard with real-time data.

```dart
class _MyActivityTab extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, FirebaseService>(
      builder: (context, userProvider, firebaseService, child) {
        // Real-time user data display
        return StreamBuilder<List<Order>>(
          stream: firebaseService.getOrdersByUserId(user.uid),
          builder: (context, snapshot) {
            // UI based on real data
          },
        );
      },
    );
  }
}
```

### 2. NotificationsCenterScreen (screens/notifications_center_screen.dart)
Real-time notifications with categories.

```dart
class NotificationsCenterScreen extends StatefulWidget {
  Widget _buildAllNotificationsTab() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotificationsStream(_userId!),
      builder: (context, snapshot) {
        // Real-time notifications
      },
    );
  }
}
```

## 🔧 Utility Functions

### 1. Date Formatting
```dart
String _formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  
  if (diff.inDays > 0) {
    return '${diff.inDays} วันที่แล้ว';
  } else if (diff.inHours > 0) {
    return '${diff.inHours} ชั่วโมงที่แล้ว';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes} นาทีที่แล้ว';
  } else {
    return 'เมื่อสักครู่';
  }
}
```

### 2. Order Status Helpers
```dart
Color _getOrderStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return Colors.orange;
    case 'confirmed': return Colors.blue;
    case 'shipping': return Colors.purple;
    case 'delivered': return Colors.green;
    case 'cancelled': return Colors.red;
    default: return Colors.grey;
  }
}

String _getOrderStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return 'รอดำเนินการ';
    case 'confirmed': return 'ยืนยันแล้ว';
    case 'shipping': return 'กำลังจัดส่ง';
    case 'delivered': return 'จัดส่งแล้ว';
    case 'cancelled': return 'ยกเลิกแล้ว';
    default: return status;
  }
}
```

## 🔄 Data Flow Examples

### 1. User Login Flow
```
1. User taps login button
2. FirebaseService.signInWithGoogle()
3. AuthProvider updates auth state
4. UserProvider.loadUserData() called
5. UI updates via Consumer widgets
```

### 2. Order Creation Flow
```
1. User adds items to cart (CartProvider)
2. User proceeds to checkout
3. OrderService.createOrder()
4. Firestore document created
5. Real-time update via StreamBuilder
```

### 3. Notification Flow
```
1. Backend event triggers notification
2. NotificationService.createNotification()
3. Firestore writes notification document
4. StreamBuilder updates UI automatically
5. Push notification sent (if enabled)
```

## 🎨 UI Patterns

### 1. Error Boundary Pattern
```dart
class _TabErrorBoundary extends StatefulWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorWidget(_error);
    }
    
    try {
      return widget.child;
    } catch (e) {
      setState(() => _error = e);
      return const SizedBox.shrink();
    }
  }
}
```

### 2. Loading State Pattern
```dart
Widget _buildContent() {
  return StreamBuilder<List<Data>>(
    stream: service.getDataStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      
      if (snapshot.hasError) {
        return ErrorWidget(snapshot.error);
      }
      
      final data = snapshot.data ?? [];
      
      if (data.isEmpty) {
        return const EmptyStateWidget();
      }
      
      return DataListWidget(data: data);
    },
  );
}
```

### 3. Responsive Design Pattern
```dart
Widget _buildResponsiveLayout() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        return DesktopLayout();
      } else if (constraints.maxWidth > 600) {
        return TabletLayout();
      } else {
        return MobileLayout();
      }
    },
  );
}
```

## 📝 Best Practices

### 1. Provider Usage
```dart
// ✅ Good - Use Consumer for specific rebuilds
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    return Text(userProvider.currentUser?.name ?? 'Guest');
  },
)

// ❌ Bad - Using context.watch() everywhere
final userProvider = context.watch<UserProvider>();
```

### 2. Stream Management
```dart
// ✅ Good - Use StreamBuilder for real-time data
StreamBuilder<List<Order>>(
  stream: firebaseService.getOrdersStream(),
  builder: (context, snapshot) { ... },
)

// ❌ Bad - Manual stream subscription management
```

### 3. Error Handling
```dart
// ✅ Good - Comprehensive error handling
try {
  final result = await service.performOperation();
  _handleSuccess(result);
} catch (e) {
  print('[ERROR] Operation failed: $e');
  _handleError(e);
}

// ❌ Bad - No error handling
final result = await service.performOperation();
```

---

**Documentation Version**: 1.0.0  
**Last Updated**: 3 กรกฎาคม 2025
