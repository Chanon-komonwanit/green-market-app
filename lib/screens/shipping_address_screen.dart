// lib/screens/shipping_address_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/shipping_address.dart';
import 'package:green_market/screens/checkout_summary_screen.dart';
import 'package:green_market/services/firebase_service.dart'; // For fetching/saving address
import 'package:green_market/utils/constants.dart'; // For AppColors, AppTextStyles
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoadingAddress = true; // Start with true to load address
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadCurrentUserAddress());
  }

  Future<void> _loadCurrentUserAddress() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // If no user, no address to load, stop loading.
      if (mounted) setState(() => _isLoadingAddress = false);
      return;
    }
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final addressMap =
          await firebaseService.getUserShippingAddress(currentUser.uid);
      if (mounted && addressMap != null) {
        final savedAddress = ShippingAddress.fromMap(
            addressMap); // Convert map to ShippingAddress object
        _fullNameController.text = savedAddress.fullName;
        _phoneNumberController.text = savedAddress.phoneNumber;
        _addressLine1Controller.text = savedAddress.addressLine1;
        _subDistrictController.text = savedAddress.subDistrict;
        _districtController.text = savedAddress.district;
        _provinceController.text = savedAddress.province;
        _zipCodeController.text = savedAddress.zipCode;
        _noteController.text = savedAddress.note ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // ignore: use_build_context_synchronously
          SnackBar(content: Text('ไม่สามารถโหลดที่อยู่: ${e.toString()}')),
        );
      }
    } finally {
      // Ensure loading indicator is turned off
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _submitAddress() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final shippingAddress = ShippingAddress(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        subDistrict: _subDistrictController.text.trim(),
        district: _districtController.text.trim(),
        province: _provinceController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final firebaseService =
              Provider.of<FirebaseService>(context, listen: false);
          await firebaseService.saveUserShippingAddress(
              currentUser.uid, shippingAddress.toMap());

          if (mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              // Pass the shippingAddress.toMap() as CheckoutSummaryScreen expects a Map
              // ignore: use_build_context_synchronously // Context is still valid here
              builder: (context) => CheckoutSummaryScreen(
                  shippingAddress: shippingAddress.toMap()),
            ));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              // ignore: use_build_context_synchronously
              SnackBar(
                  content: Text(
                      'เกิดข้อผิดพลาดในการบันทึกที่อยู่: ${e.toString()}')),
            );
          }
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // ignore: use_build_context_synchronously
            const SnackBar(content: Text('ไม่พบผู้ใช้งานปัจจุบัน')),
          );
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _addressLine1Controller.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _zipCodeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0)), // Rounded border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: AppColors.primaryTeal,
              width: 2.0), // Use new primary color
        ),
      ),
      style: AppTextStyles.body,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ที่อยู่สำหรับจัดส่ง',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal, // Use new primary color
        iconTheme:
            const IconThemeData(color: AppColors.white), // Back button color
      ),
      body: _isLoadingAddress
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextFormField(
                      controller: _fullNameController,
                      labelText: 'ชื่อ-นามสกุลผู้รับ*',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อ-นามสกุล';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _phoneNumberController,
                      labelText: 'เบอร์โทรศัพท์*',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกเบอร์โทรศัพท์';
                        }
                        if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value.trim())) {
                          return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง (9-10 หลัก)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _addressLine1Controller,
                      labelText: 'บ้านเลขที่, ถนน, หมู่บ้าน, อาคาร, ซอย*',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกที่อยู่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _subDistrictController,
                            labelText: 'แขวง/ตำบล*',
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'กรุณากรอกแขวง/ตำบล'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _districtController,
                            labelText: 'เขต/อำเภอ*',
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'กรุณากรอกเขต/อำเภอ'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _provinceController,
                            labelText: 'จังหวัด*',
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'กรุณากรอกจังหวัด'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _zipCodeController,
                            labelText: 'รหัสไปรษณีย์*',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกรหัสไปรษณีย์';
                              }
                              if (!RegExp(r'^[0-9]{5}$')
                                  .hasMatch(value.trim())) {
                                return 'รูปแบบรหัสไปรษณีย์ไม่ถูกต้อง (5 หลัก)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'หมายเหตุ (ถ้ามี)',
                        hintText: 'เช่น สถานที่ใกล้เคียง, เวลาที่สะดวกรับของ',
                        labelStyle: AppTextStyles.body
                            .copyWith(color: AppColors.modernGrey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                              color: AppColors.primaryTeal, width: 2.0),
                        ),
                      ),
                      style: AppTextStyles.body,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submitAddress,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          textStyle: AppTextStyles.subtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold)),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text('บันทึกและดำเนินการต่อ',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
