// d:/Development/green_market/lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/product_detail_screen.dart';
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
  Stream<List<Product>>? _searchResultsStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.trim() != _query) {
        setState(() {
          _query = _searchController.text.trim();
          if (_query.isNotEmpty) {
            _searchResultsStream =
                Provider.of<FirebaseService>(context, listen: false)
                    .searchProducts(_query);
          } else {
            _searchResultsStream = null;
          }
        });
      }
    });
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
        backgroundColor: AppColors.white,
        elevation: 1,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ค้นหาสินค้า...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.modernGrey),
          ),
          style: const TextStyle(color: AppColors.primaryDarkGreen),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: AppColors.lightGrey),
            SizedBox(height: 16),
            Text('เริ่มค้นหาสินค้าที่คุณสนใจ'),
          ],
        ),
      );
    }

    return StreamBuilder<List<Product>>(
      stream: _searchResultsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่พบสินค้าที่ตรงกับการค้นหา'));
        }

        final products = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              )),
            );
          },
        );
      },
    );
  }
}
