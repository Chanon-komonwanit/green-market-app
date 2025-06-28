// d:/Development/green_market/lib/screens/submit_investment_project_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SubmitInvestmentProjectScreen extends StatefulWidget {
  final InvestmentProject? project; // Optional: for editing existing project

  const SubmitInvestmentProjectScreen({super.key, this.project});

  @override
  State<SubmitInvestmentProjectScreen> createState() =>
      _SubmitInvestmentProjectScreenState();
}

class _SubmitInvestmentProjectScreenState
    extends State<SubmitInvestmentProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _expectedReturnRateController = TextEditingController();

  // --- CORRECTED: Use RiskLevel enum instead of String ---
  RiskLevel? _selectedRiskLevel = RiskLevel.medium;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _loadProjectData(widget.project!);
    }
  }

  void _loadProjectData(InvestmentProject project) {
    _titleController.text = project.title;
    _descriptionController.text = project.description;
    _imageUrlController.text = project.imageUrl;
    _targetAmountController.text = project.goalAmount.toString();
    _expectedReturnRateController.text = project.expectedReturnRate.toString();
    // --- CORRECTED: Assign enum directly ---
    _selectedRiskLevel = project.riskLevel;
    _selectedStartDate = project.startDate;
    _selectedEndDate = project.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetAmountController.dispose();
    _expectedReturnRateController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedStartDate == null || _selectedEndDate == null) {
      showAppSnackBar(context, 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด',
          isError: true);
      return;
    }

    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      showAppSnackBar(context, 'วันที่สิ้นสุดต้องอยู่หลังวันที่เริ่มต้น',
          isError: true);
      return;
    }

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      showAppSnackBar(context, 'กรุณาเข้าสู่ระบบเพื่อส่งโครงการ',
          isError: true);
      return;
    }

    try {
      // Show loading indicator
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(
                child: CircularProgressIndicator(),
              ));

      // --- CORRECTED: Assembling the InvestmentProject object ---
      final projectToSave = InvestmentProject(
        id: widget.project?.id ??
            firebaseService.generateNewDocId('investment_projects'),
        title: _titleController.text.trim(), // Added missing title
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        goalAmount: double.parse(_targetAmountController.text),
        currentAmount: widget.project?.currentAmount ?? 0.0,
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
        projectOwnerId: currentUser.id,
        projectOwnerName: currentUser.displayName ?? currentUser.email,
        expectedReturnRate: double.parse(_expectedReturnRateController.text),
        riskLevel: _selectedRiskLevel!, // Use the enum directly
        submissionStatus:
            widget.project?.submissionStatus ?? ProjectSubmissionStatus.pending,
        isActive: widget.project?.isActive ?? false,
        rejectionReason: widget.project?.rejectionReason,
        createdAt: widget.project?.createdAt,
      );

      if (widget.project == null) {
        await firebaseService.addInvestmentProject(projectToSave);
      } else {
        await firebaseService.updateInvestmentProject(projectToSave);
      }

      // Pop loading indicator
      if (context.mounted) Navigator.of(context).pop();

      showAppSnackBar(context, 'ส่งโครงการสำเร็จ! รอการอนุมัติจากแอดมิน',
          isSuccess: true);
      if (context.mounted) {
        Navigator.of(context).pop(); // Go back after submission
      }
    } catch (e) {
      // Pop loading indicator
      if (context.mounted) Navigator.of(context).pop();
      showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.project == null
                ? 'ส่งโครงการลงทุนใหม่'
                : 'แก้ไขโครงการลงทุน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                  controller: _titleController,
                  decoration: buildInputDecoration(context, 'ชื่อโครงการ'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อโครงการ' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _descriptionController,
                  decoration: buildInputDecoration(context, 'คำอธิบายโครงการ'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _imageUrlController,
                  decoration: buildInputDecoration(context, 'URL รูปภาพหลัก'),
                  keyboardType: TextInputType.url,
                  validator: (v) => v!.isEmpty ? 'กรุณากรอก URL รูปภาพ' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _targetAmountController,
                  decoration:
                      buildInputDecoration(context, 'จำนวนเงินเป้าหมาย (บาท)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ||
                          double.tryParse(v) == null ||
                          double.parse(v) <= 0
                      ? 'กรุณากรอกจำนวนเงินเป้าหมายที่ถูกต้อง'
                      : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _expectedReturnRateController,
                  decoration: buildInputDecoration(
                      context, 'อัตราผลตอบแทนที่คาดหวัง (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ||
                          double.tryParse(v) == null ||
                          double.parse(v) <= 0
                      ? 'กรุณากรอกอัตราผลตอบแทนที่ถูกต้อง'
                      : null),
              const SizedBox(height: 10),
              // --- CORRECTED: Dropdown works with RiskLevel enum ---
              DropdownButtonFormField<RiskLevel>(
                value: _selectedRiskLevel,
                decoration: buildInputDecoration(context, 'ระดับความเสี่ยง'),
                items: RiskLevel.values
                    .map((RiskLevel level) => DropdownMenuItem<RiskLevel>(
                          value: level,
                          child: Text(level.name), // Display enum name
                        ))
                    .toList(),
                onChanged: (RiskLevel? newValue) {
                  setState(() {
                    _selectedRiskLevel = newValue;
                  });
                },
                validator: (v) =>
                    v == null ? 'กรุณาเลือกระดับความเสี่ยง' : null,
              ),
              const SizedBox(height: 10),
              _buildDatePicker(
                context,
                'วันที่เริ่มต้น',
                _selectedStartDate,
                (date) => setState(() => _selectedStartDate = date),
              ),
              const SizedBox(height: 10),
              _buildDatePicker(
                context,
                'วันที่สิ้นสุด',
                _selectedEndDate,
                (date) => setState(() => _selectedEndDate = date),
                minDate: _selectedStartDate,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitProject,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(widget.project == null
                      ? 'ส่งโครงการเพื่อขออนุมัติ'
                      : 'บันทึกการแก้ไขโครงการ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label,
      DateTime? selectedDate, Function(DateTime?) onDateSelected,
      {DateTime? minDate}) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: minDate ?? DateTime(2020),
          lastDate: DateTime(2101),
        );
        onDateSelected(pickedDate);
      },
      child: InputDecorator(
        decoration: buildInputDecoration(context, label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? DateFormat('dd MMMM yyyy').format(selectedDate)
                  : 'เลือกวันที่',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
