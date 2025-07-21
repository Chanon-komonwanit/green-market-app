import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../models/category.dart';
import 'category_products_screen.dart';

class CategoryScreen extends StatelessWidget {
  final _categoryService = CategoryService();

  CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หมวดหมู่สินค้า')),
      body: StreamBuilder<List<Category>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีหมวดหมู่'));
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryProductsScreen(category: category),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
