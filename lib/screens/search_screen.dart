// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Stream<List<Product>>? _searchResultsStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.trim() != _query) {
        // Only update if query actually changed to avoid unnecessary rebuilds
        // Debouncing could be added here for better performance on rapid typing
        setState(() {
          _query = _searchController.text.trim();
          _searchResultsStream =
              Provider.of<FirebaseService>(context, listen: false)
                  .searchProducts(_query);
        });
      }
    });
    // Initialize with an empty stream or based on an initial query if needed
    _searchResultsStream = Stream.value([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ค้นหาสินค้า Green Market...',
            hintStyle: AppTextStyles.body
                // ignore: deprecated_member_use
                .copyWith(color: AppColors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.white),
                    onPressed: () {
                      _searchController.clear();
                      // setState(() { // Already handled by listener
                      //   _query = '';
                      //   _searchResultsStream = Stream.value([]);
                      // });
                    },
                  )
                : null,
          ),
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
          cursorColor: AppColors.lightTeal,
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _query.isEmpty
          ? Center(
              child: Text('พิมพ์เพื่อค้นหาสินค้าที่คุณสนใจ',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
            )
          : StreamBuilder<List<Product>>(
              stream: _searchResultsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _query.isNotEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: AppTextStyles.body));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('ไม่พบสินค้าที่ตรงกับคำค้นหา "$_query"',
                          style: AppTextStyles.body));
                }

                final products = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
    );
  }
}
