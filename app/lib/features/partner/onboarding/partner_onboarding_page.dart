/// Partner onboarding flow - 3 step process
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/config/constants.dart';
import '../../../routes/app_router.dart';
import '../../../core/network/api_client.dart';

/// Partner onboarding page with 3 steps
class PartnerOnboardingPage extends StatefulWidget {
  const PartnerOnboardingPage({super.key});

  @override
  State<PartnerOnboardingPage> createState() => _PartnerOnboardingPageState();
}

class _PartnerOnboardingPageState extends State<PartnerOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Business Details
  final _businessNameController = TextEditingController();
  String _selectedCategory = 'FOOD';
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Step 2: GST Verification
  final _gstinController = TextEditingController();
  final _legalNameController = TextEditingController();
  bool _gstConsent = false;

  // Step 3: Commercial Setup
  int _selectedDiscountSlab = 6; // Default 6%
  String _settlementMode = 'PLATFORM'; // PLATFORM or DIRECT

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _legalNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      context.go(AppRoutes.userHome);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _businessNameController.text.isNotEmpty &&
            _cityController.text.isNotEmpty &&
            _stateController.text.isNotEmpty &&
            _pincodeController.text.length == 6;
      case 1:
        return _gstinController.text.length == 15 &&
            _legalNameController.text.isNotEmpty &&
            _gstConsent;
      case 2:
        return true; // Always valid
      default:
        return false;
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = context.read<ApiClient>();

      final categoryMap = {
        'FOOD': 'RESTAURANT',
        'STAY': 'HOTEL',
        'SERVICE': 'OTHER',
        'RETAIL': 'RETAIL',
      };

      final Map<String, dynamic> onboardingData = {
        'businessName': _businessNameController.text.trim(),
        'category': categoryMap[_selectedCategory] ?? 'OTHER',
        'description': 'Partner business',
        'businessPhone': '+919876543210',
        'businessEmail': 'business@test.com',
        'address': {
          'line1': 'Test Street',
          'line2': '',
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'discountRate': _selectedDiscountSlab.toDouble(),
        'gstNumber': _gstinController.text.trim().toUpperCase(),
        'panNumber': '',
      };

      debugPrint('🚀 Submitting onboarding data: $onboardingData');

      final response = await apiClient.post(
        '/partners/onboard',
        body: onboardingData,
        requiresAuth: true,
      );

      if (!mounted) return;

      debugPrint('✅ Response - Success: ${response.success}, Status: ${response.statusCode}');

      if (response.success && (response.statusCode == 201 || response.statusCode == 200)) {
        debugPrint('📦 Response data: ${response.data}');

        final authProvider = context.read<AuthProvider>();

        if (!authProvider.hasRole(UserRole.partner)) {
          authProvider.addRole(UserRole.partner);
        }
        await authProvider.switchRole(UserRole.partner);

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Partner registration completed successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          context.go(AppRoutes.partnerDashboard);
        }
      } else {
        final errorMessage = response.error?.message ?? 'Onboarding failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Onboarding failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );

      debugPrint('❌ Onboarding error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: const Text('Partner Registration'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1BusinessDetails(),
                _buildStep2GstVerification(),
                _buildStep3CommercialSetup(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted || isCurrent
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                      '${index + 1}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isCurrent
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BusinessDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Details',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _businessNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Business Name',
              hintText: 'Enter your business name',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          Text(
            'Business Category',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('FOOD', 'Food & Dining', Icons.restaurant),
              _buildCategoryChip('STAY', 'Hotel & Stay', Icons.hotel),
              _buildCategoryChip('SERVICE', 'Services', Icons.miscellaneous_services),
              _buildCategoryChip('RETAIL', 'Retail', Icons.shopping_bag),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Business Address',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _cityController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'Enter city',
              prefixIcon: Icon(Icons.location_city),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'State',
                    hintText: 'Enter state',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: AppColors.textPrimary),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    hintText: '000000',
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildStep2GstVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GST Verification',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'GST registration is mandatory for all partners',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _gstinController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 15,
            style: const TextStyle(
              color: AppColors.textPrimary,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              labelText: 'GSTIN',
              hintText: '22AAAAA0000A1Z5',
              prefixIcon: Icon(Icons.verified_outlined),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _legalNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Legal Business Name',
              hintText: 'As per GST certificate',
              prefixIcon: Icon(Icons.business),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Why GST is required?',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Enables proper tax invoicing for customers\n'
                      '• Required for platform settlement\n'
                      '• Ensures compliance with regulations',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          InkWell(
            onTap: () {
              setState(() {
                _gstConsent = !_gstConsent;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _gstConsent,
                    onChanged: (value) {
                      setState(() {
                        _gstConsent = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I confirm that the GST details provided are accurate and I am authorized to register this business.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3CommercialSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commercial Setup',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your discount and settlement preferences',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Discount Slab',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Higher discounts attract more customers',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDiscountOption(3),
              const SizedBox(width: 12),
              _buildDiscountOption(6),
              const SizedBox(width: 12),
              _buildDiscountOption(9),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Settlement Mode',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettlementOption(
            'PLATFORM',
            'Platform Settlement',
            'Funds settled to your bank account within T+1 day',
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildSettlementOption(
            'DIRECT',
            'Direct Settlement',
            'Razorpay settles directly (requires Razorpay account)',
            Icons.flash_on,
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Platform Fee',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '1% per transaction',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform fee is deducted from the discounted amount you receive.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.partnerAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.partnerAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.partnerAccent,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Business', _businessNameController.text),
                _buildSummaryRow('Category', _getCategoryLabel(_selectedCategory)),
                _buildSummaryRow('Discount', '$_selectedDiscountSlab%'),
                _buildSummaryRow(
                  'Settlement',
                  _settlementMode == 'PLATFORM' ? 'Platform (T+1)' : 'Direct',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountOption(int percent) {
    final isSelected = _selectedDiscountSlab == percent;
    return Expanded(
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedDiscountSlab = percent;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$percent%',
                  style: AppTextStyles.h2.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OFF',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementOption(
      String value,
      String title,
      String description,
      IconData icon,
      ) {
    final isSelected = _settlementMode == value;
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _settlementMode = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'FOOD':
        return 'Food & Dining';
      case 'STAY':
        return 'Hotel & Stay';
      case 'SERVICE':
        return 'Services';
      case 'RETAIL':
        return 'Retail';
      default:
        return category;
    }
  }

  Widget _buildBottomAction() {
    final isValid = _validateCurrentStep();
    final isLastStep = _currentStep == 2;

    return Container(
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
            onPressed: isValid && !_isLoading ? _nextStep : null,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(isLastStep ? 'Complete Registration' : 'Continue'),
          ),
        ),
      ),
    );
  }
}