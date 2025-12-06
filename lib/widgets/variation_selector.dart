// lib/widgets/variation_selector.dart
// Variation Selector Widget - สำหรับลูกค้าเลือก Variation ในหน้า Product Detail

import 'package:flutter/material.dart';
import 'package:green_market/models/product_variation.dart';
import 'package:green_market/theme/app_colors.dart';

class VariationSelector extends StatefulWidget {
  final List<ProductVariationOption> options;
  final List<ProductVariation> variations;
  final Function(ProductVariation?) onVariationSelected;
  final ProductVariation? initialVariation;

  const VariationSelector({
    super.key,
    required this.options,
    required this.variations,
    required this.onVariationSelected,
    this.initialVariation,
  });

  @override
  State<VariationSelector> createState() => _VariationSelectorState();
}

class _VariationSelectorState extends State<VariationSelector> {
  Map<String, String> _selectedAttributes = {};
  ProductVariation? _selectedVariation;

  @override
  void initState() {
    super.initState();
    if (widget.initialVariation != null) {
      _selectedAttributes = Map.from(widget.initialVariation!.attributes);
      _selectedVariation = widget.initialVariation;
    }
  }

  void _selectValue(String optionName, String value) {
    setState(() {
      _selectedAttributes[optionName] = value;
      _updateSelectedVariation();
    });
  }

  void _updateSelectedVariation() {
    // Check if all options are selected
    bool allSelected = widget.options.every(
      (option) => _selectedAttributes.containsKey(option.name),
    );

    if (!allSelected) {
      _selectedVariation = null;
      widget.onVariationSelected(null);
      return;
    }

    // Find matching variation
    final matchingVariation = widget.variations.firstWhere(
      (variation) =>
          _attributesMatch(variation.attributes, _selectedAttributes),
      orElse: () => widget.variations.first,
    );

    _selectedVariation = matchingVariation;
    widget.onVariationSelected(matchingVariation);
  }

  bool _attributesMatch(Map<String, String> attr1, Map<String, String> attr2) {
    if (attr1.length != attr2.length) return false;
    for (var key in attr1.keys) {
      if (attr1[key] != attr2[key]) return false;
    }
    return true;
  }

  /// Check if a value is available (has stock)
  bool _isValueAvailable(String optionName, String value) {
    // Create temporary attributes with this value selected
    final tempAttributes = Map<String, String>.from(_selectedAttributes);
    tempAttributes[optionName] = value;

    // Check if any variation with these attributes has stock
    return widget.variations.any((variation) {
      // Check if this variation matches the temp attributes (partially or fully)
      bool matches = tempAttributes.entries.every((entry) {
        return variation.attributes[entry.key] == entry.value;
      });
      return matches && variation.hasStock;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.options.map((option) => _buildOptionSelector(option)),

        // Selected variation info
        if (_selectedVariation != null) ...[
          const Divider(height: 32),
          _buildSelectedVariationInfo(),
        ],
      ],
    );
  }

  Widget _buildOptionSelector(ProductVariationOption option) {
    final selectedValue = _selectedAttributes[option.name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                option.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedValue != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedValue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: option.values.map((value) {
              final isSelected = selectedValue == value;
              final isAvailable = _isValueAvailable(option.name, value);

              return _buildValueButton(
                value: value,
                isSelected: isSelected,
                isAvailable: isAvailable,
                onTap:
                    isAvailable ? () => _selectValue(option.name, value) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildValueButton({
    required String value,
    required bool isSelected,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    TextDecoration? decoration;

    if (!isAvailable) {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[400]!;
      borderColor = Colors.grey[300]!;
      decoration = TextDecoration.lineThrough;
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      borderColor = AppColors.primary;
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.black87;
      borderColor = Colors.grey[300]!;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: decoration,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedVariationInfo() {
    if (_selectedVariation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'เลือกแล้ว:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedVariation!.attributesDisplay,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.attach_money,
                label: 'ราคา',
                value: '฿${_selectedVariation!.price.toStringAsFixed(2)}',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.inventory,
                label: 'สต็อก',
                value: '${_selectedVariation!.stock}',
                color:
                    _selectedVariation!.stock < 10 ? Colors.red : Colors.green,
              ),
            ],
          ),
          if (_selectedVariation!.sku != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'SKU: ${_selectedVariation!.sku}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Variation Summary - แสดงสรุปสั้นๆ ของ Variations
class VariationSummaryBadge extends StatelessWidget {
  final ProductWithVariations productWithVariations;

  const VariationSummaryBadge({
    super.key,
    required this.productWithVariations,
  });

  @override
  Widget build(BuildContext context) {
    if (!productWithVariations.hasVariations) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '${productWithVariations.variationCount} ตัวเลือก',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
