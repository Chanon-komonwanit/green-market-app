// lib/screens/seller/product_variation_management_screen.dart
// Product Variation Management Screen - จัดการตัวเลือกสินค้า (Size, Color, etc.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:green_market/models/product_variation.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:logger/logger.dart';

class ProductVariationManagementScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductVariationManagementScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductVariationManagementScreen> createState() =>
      _ProductVariationManagementScreenState();
}

class _ProductVariationManagementScreenState
    extends State<ProductVariationManagementScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _logger = Logger();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Options Data
  List<ProductVariationOption> _options = [];
  final _optionNameController = TextEditingController();
  final List<TextEditingController> _valueControllers = [];

  // Variations Data
  List<ProductVariation> _variations = [];
  List<List<String>> _variationCombinations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _optionNameController.dispose();
    for (var controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load variation options
      final optionsData =
          await _firebaseService.getProductVariationOptions(widget.productId);
      if (optionsData != null) {
        _options = (optionsData['options'] as List?)
                ?.map((o) => ProductVariationOption.fromMap(o))
                .toList() ??
            [];
      }

      // Load existing variations
      final variationsData =
          await _firebaseService.getProductVariations(widget.productId);
      _variations =
          variationsData.map((v) => ProductVariation.fromMap(v)).toList();

      // Generate combinations if options exist
      if (_options.isNotEmpty) {
        _generateVariationCombinations();
      }
    } catch (e) {
      _logger.e('Error loading variation data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateVariationCombinations() {
    if (_options.isEmpty) {
      _variationCombinations = [];
      return;
    }

    // Generate all possible combinations
    List<List<String>> combinations = [[]];

    for (var option in _options) {
      List<List<String>> newCombinations = [];
      for (var combination in combinations) {
        for (var value in option.values) {
          newCombinations.add([...combination, value]);
        }
      }
      combinations = newCombinations;
    }

    _variationCombinations = combinations;
  }

  Future<void> _saveOptions() async {
    if (_options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มตัวเลือกอย่างน้อย 1 ตัว')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firebaseService.saveProductVariationOptions(
        widget.productId,
        {'options': _options.map((o) => o.toMap()).toList()},
      );

      _generateVariationCombinations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกตัวเลือกสำเร็จ')),
        );
        _tabController.animateTo(1); // Switch to Variations tab
      }
    } catch (e) {
      _logger.e('Error saving options: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateAllVariations() async {
    if (_variationCombinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาสร้างตัวเลือกก่อน')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สร้าง Variations'),
        content: Text(
            'จะสร้าง ${_variationCombinations.length} Variations\nราคาและสต็อกจะตั้งเป็น 0 (คุณสามารถแก้ไขภายหลังได้)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      for (var i = 0; i < _variationCombinations.length; i++) {
        final combination = _variationCombinations[i];

        // Build attributes map
        final attributes = <String, String>{};
        for (var j = 0; j < _options.length; j++) {
          attributes[_options[j].name] = combination[j];
        }

        // Check if variation already exists
        final exists = _variations.any((v) {
          return _attributesMatch(v.attributes, attributes);
        });

        if (!exists) {
          final variationData = {
            'productId': widget.productId,
            'attributes': attributes,
            'price': 0.0,
            'stock': 0,
            'sku': null,
            'imageUrl': null,
            'isActive': true,
          };

          final newId =
              await _firebaseService.addProductVariation(variationData);

          _variations.add(ProductVariation.fromMap({
            ...variationData,
            'id': newId,
          }));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้าง Variations สำเร็จ')),
        );
        setState(() {});
      }
    } catch (e) {
      _logger.e('Error generating variations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้าง Variations ไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _attributesMatch(Map<String, String> attr1, Map<String, String> attr2) {
    if (attr1.length != attr2.length) return false;
    for (var key in attr1.keys) {
      if (attr1[key] != attr2[key]) return false;
    }
    return true;
  }

  Future<void> _updateVariation(
      ProductVariation variation, Map<String, dynamic> updates) async {
    try {
      await _firebaseService.updateProductVariation(variation.id, updates);

      final index = _variations.indexWhere((v) => v.id == variation.id);
      if (index != -1) {
        setState(() {
          _variations[index] = variation.copyWith(
            price: updates['price'],
            stock: updates['stock'],
            sku: updates['sku'],
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตสำเร็จ')),
      );
    } catch (e) {
      _logger.e('Error updating variation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _deleteVariation(ProductVariation variation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบ Variation'),
        content: Text('ต้องการลบ ${variation.attributesDisplay} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.deleteProductVariation(variation.id);
      setState(() {
        _variations.removeWhere((v) => v.id == variation.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสำเร็จ')),
      );
    } catch (e) {
      _logger.e('Error deleting variation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('จัดการตัวเลือกสินค้า'),
            Text(
              widget.productName,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'ตัวเลือก'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Variations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOptionsTab(),
                _buildVariationsTab(),
              ],
            ),
    );
  }

  Widget _buildOptionsTab() {
    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'วิธีใช้งาน',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('1. เพิ่มตัวเลือก เช่น "ขนาด", "สี"'),
              Text('2. ใส่ค่าในแต่ละตัวเลือก เช่น "S, M, L"'),
              Text('3. บันทึก แล้วไปที่แท็บ Variations เพื่อตั้งราคา/สต็อก'),
            ],
          ),
        ),

        // Options List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _options.length + 1,
            itemBuilder: (context, index) {
              if (index == _options.length) {
                return _buildAddOptionButton();
              }
              return _buildOptionCard(_options[index], index);
            },
          ),
        ),

        // Save Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('บันทึกตัวเลือก',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddOptionButton() {
    return Card(
      child: InkWell(
        onTap: _showAddOptionDialog,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.add_circle_outline, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'เพิ่มตัวเลือกใหม่',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(ProductVariationOption option, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditOptionDialog(option, index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteOption(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.values.map((value) {
                return Chip(
                  label: Text(value),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptionDialog() {
    _optionNameController.clear();
    _valueControllers.clear();
    _valueControllers.add(TextEditingController());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เพิ่มตัวเลือกใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _optionNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อตัวเลือก',
                    hintText: 'เช่น ขนาด, สี, วัสดุ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ค่าต่างๆ:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_valueControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _valueControllers[index],
                            decoration: InputDecoration(
                              labelText: 'ค่าที่ ${index + 1}',
                              hintText: 'เช่น S, M, L',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_valueControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                _valueControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      _valueControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มค่า'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _optionNameController.text.trim();
                final values = _valueControllers
                    .map((c) => c.text.trim())
                    .where((v) => v.isNotEmpty)
                    .toList();

                if (name.isEmpty || values.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                  );
                  return;
                }

                setState(() {
                  _options.add(ProductVariationOption(
                    name: name,
                    values: values,
                  ));
                });

                Navigator.pop(context);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOptionDialog(ProductVariationOption option, int optionIndex) {
    _optionNameController.text = option.name;
    _valueControllers.clear();
    for (var value in option.values) {
      final controller = TextEditingController(text: value);
      _valueControllers.add(controller);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('แก้ไขตัวเลือก'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _optionNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อตัวเลือก',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ค่าต่างๆ:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_valueControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _valueControllers[index],
                            decoration: InputDecoration(
                              labelText: 'ค่าที่ ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_valueControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                _valueControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      _valueControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มค่า'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _optionNameController.text.trim();
                final values = _valueControllers
                    .map((c) => c.text.trim())
                    .where((v) => v.isNotEmpty)
                    .toList();

                if (name.isEmpty || values.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                  );
                  return;
                }

                setState(() {
                  _options[optionIndex] = ProductVariationOption(
                    name: name,
                    values: values,
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  Widget _buildVariationsTab() {
    if (_options.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่มีตัวเลือก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('กรุณาไปที่แท็บ "ตัวเลือก" เพื่อเพิ่มตัวเลือกก่อน'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.arrow_back),
              label: const Text('ไปที่แท็บตัวเลือก'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header Stats
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Variations ทั้งหมด',
                  '${_variationCombinations.length}',
                  Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'สร้างแล้ว',
                  '${_variations.length}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ),

        // Generate Button (if not all created)
        if (_variations.length < _variationCombinations.length)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _generateAllVariations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                    'สร้าง Variations อัตโนมัติ (${_variationCombinations.length})'),
              ),
            ),
          ),

        // Variations List
        Expanded(
          child: _variations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('ยังไม่มี Variations'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _generateAllVariations,
                        child: const Text('สร้าง Variations'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _variations.length,
                  itemBuilder: (context, index) {
                    return _buildVariationCard(_variations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationCard(ProductVariation variation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          variation.attributesDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text('฿${variation.price.toStringAsFixed(2)}'),
            const SizedBox(width: 16),
            Text('สต็อก: ${variation.stock}'),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: variation.hasStock ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variation.stockStatus,
                style: const TextStyle(color: Colors.white, fontSize: 10),
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
                _buildVariationField(
                  'ราคา',
                  variation.price.toString(),
                  Icons.attach_money,
                  (value) async {
                    final price = double.tryParse(value);
                    if (price != null) {
                      await _updateVariation(variation, {'price': price});
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildVariationField(
                  'สต็อก',
                  variation.stock.toString(),
                  Icons.inventory,
                  (value) async {
                    final stock = int.tryParse(value);
                    if (stock != null) {
                      await _updateVariation(variation, {'stock': stock});
                    }
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildVariationField(
                  'SKU',
                  variation.sku ?? '',
                  Icons.qr_code,
                  (value) async {
                    await _updateVariation(variation, {'sku': value});
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteVariation(variation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('ลบ Variation นี้'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationField(
    String label,
    String initialValue,
    IconData icon,
    Function(String) onSubmit, {
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: initialValue);

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: onSubmit,
          ),
        ),
      ],
    );
  }
}
