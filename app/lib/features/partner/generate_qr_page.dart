/// Generate QR page - create bill and display QR for customer payment
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';
import '../bills/bills_service.dart';

/// Generate QR page for partner bill creation
class GenerateQrPage extends StatefulWidget {
  const GenerateQrPage({super.key});

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDiscountController = TextEditingController();
  bool _isGenerating = false;
  bool _qrGenerated = false;
  BillData? _billData;
  int _expirySeconds = 300; // 5 minutes
  Timer? _expiryTimer;
  String? _errorMessage;

  // Discount rate selected by merchant (dynamic per bill)
  double _selectedDiscount = 5.0; // Default 5%
  bool _showCustomDiscount = false;

  late BillsService _billsService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiClient = context.read<ApiClient>();
    _billsService = BillsService(apiClient: apiClient);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customDiscountController.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  // Calculate amounts based on current input
  double get _discountAmount => _amount * _selectedDiscount / 100;
  double get _finalAmount => _amount - _discountAmount;

  double get _amount {
    return double.tryParse(_amountController.text) ?? 0;
  }

  Future<void> _generateQr() async {
    if (_amount <= 0) return;
    if (_selectedDiscount < 0 || _selectedDiscount > 50) {
      setState(() {
        _errorMessage = 'Discount must be between 0% and 50%';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    // Create bill via API with selected discount
    final result = await _billsService.createBill(
      amount: _amount,
      discountRate: _selectedDiscount,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      expiryMinutes: 5,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() {
        _isGenerating = false;
        _qrGenerated = true;
        _billData = result.data;
        _expirySeconds = result.data!.expiryMinutes * 60;
      });

      _startExpiryTimer();
    } else {
      setState(() {
        _isGenerating = false;
        _errorMessage = result.errorMessage ?? 'Failed to create bill';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to generate QR'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySeconds > 0) {
        setState(() {
          _expirySeconds--;
        });
      } else {
        timer.cancel();
        _resetQr();
      }
    });
  }

  void _resetQr() {
    _expiryTimer?.cancel();
    setState(() {
      _qrGenerated = false;
      _billData = null;
      _amountController.clear();
      _descriptionController.clear();
      _customDiscountController.clear();
      _selectedDiscount = 5.0;
      _showCustomDiscount = false;
      _errorMessage = null;
    });
  }

  String _formatExpiry() {
    final minutes = _expirySeconds ~/ 60;
    final seconds = _expirySeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.partnerDashboard),
        ),
        title: const Text('Generate Bill'),
        centerTitle: true,
      ),
      body: _qrGenerated ? _buildQrDisplay() : _buildAmountInput(),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Bill Amount',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the total bill amount to generate payment QR',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Amount input
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u20B9',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 48,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: AppTextStyles.h1.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 48,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description input (optional)
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g., Lunch for 2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Discount selector
                const SizedBox(height: 8),
                Text(
                  'Select Discount',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Preset discount buttons
                Row(
                  children: [
                    _buildDiscountChip(5),
                    const SizedBox(width: 8),
                    _buildDiscountChip(10),
                    const SizedBox(width: 8),
                    _buildDiscountChip(15),
                    const SizedBox(width: 8),
                    _buildCustomDiscountChip(),
                  ],
                ),

                // Custom discount input
                if (_showCustomDiscount) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customDiscountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Custom Discount %',
                      hintText: 'Enter 0-50',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'),
                      ),
                    ],
                    onChanged: (value) {
                      final discount = double.tryParse(value) ?? 0;
                      if (discount >= 0 && discount <= 50) {
                        setState(() {
                          _selectedDiscount = discount;
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // Preview breakdown
                if (_amount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildPreviewRow(
                          'Bill Amount',
                          CurrencyFormatter.format(_amount),
                        ),
                        const Divider(height: 16),
                        _buildPreviewRow(
                          'Discount (${_selectedDiscount.toStringAsFixed(_selectedDiscount % 1 == 0 ? 0 : 1)}%)',
                          '-${CurrencyFormatter.format(_discountAmount)}',
                          valueColor: AppColors.success,
                        ),
                        const Divider(height: 16),
                        _buildPreviewRow(
                          'Customer Pays',
                          CurrencyFormatter.format(_finalAmount),
                          isBold: true,
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom action
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _amount > 0 && !_isGenerating ? _generateQr : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.partnerAccent,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Generate QR Code'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
              .copyWith(
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.h4 : AppTextStyles.bodyMedium)
              .copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildDiscountChip(double discount) {
    final isSelected = !_showCustomDiscount && _selectedDiscount == discount;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDiscount = discount;
            _showCustomDiscount = false;
            _customDiscountController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            '${discount.toInt()}%',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDiscountChip() {
    final isSelected = _showCustomDiscount;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showCustomDiscount = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            'Custom',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrDisplay() {
    if (_billData == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Expiry timer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _expirySeconds < 60
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: _expirySeconds < 60
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${_formatExpiry()}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: _expirySeconds < 60
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Real QR code using qr_flutter
                      QrImageView(
                        data: _billData!.qrToken,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan to Pay',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bill ID: ${_billData!.billId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Bill Amount',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(_billData!.amounts.original),
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_billData!.amounts.discountPercent.toStringAsFixed(0)}% Discount Applied',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Customer pays: ${CurrencyFormatter.format(_billData!.amounts.final_)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Show this QR to the customer\n'
                        '2. Customer scans with Travellers Triibe app\n'
                        '3. Payment is processed with discount\n'
                        '4. You receive confirmation',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetQr,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'New Bill',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.partnerDashboard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.partnerAccent,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
