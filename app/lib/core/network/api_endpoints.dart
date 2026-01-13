/// File: api_endpoints.dart
/// Purpose: All API endpoint constants
/// Context: Single source of truth for API routes
library;

class ApiEndpoints {
  // ============== AUTH ==============
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String me = '/auth/me';
  static const String firebaseAuth = '/auth/firebase';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';


  // ============== USER ==============
  static const String userProfile = '/users/profile';
  static const String userSavings = '/users/savings';

  // ============== ORDERS ==============
  static const String orders = '/orders';
  static String orderDetail(String orderId) => '/orders/$orderId';

  // ============== PAYMENTS ==============
  static const String paymentCreate = '/payments/create';
  static const String paymentVerify = '/payments/verify';
  static const String paymentHistory = '/payments/history';

  // ============== BILLS (QR CODE) ==============
  static const String billCreate = '/bills/create';
  static const String billActive = '/bills/active';
  static const String billValidate = '/bills/validate';
  static const String billPay = '/bills/pay';
  static String billCancel(String billId) => '/bills/$billId';

  // ============== PARTNER ==============
  static const String partnerOnboard = '/partners/onboard';
  static const String partnerProfile = '/partners/profile';
  static const String partnerAnalytics = '/partners/analytics';
  static const String partnerOrders = '/orders/partner/list';
  static const String partnerOrderStats = '/orders/partner/stats';

  // ============== ADMIN ==============
  static const String adminDashboard = '/admin/dashboard';
  static const String adminMerchants = '/admin/merchants';
  static String adminMerchantDetail(String merchantId) => '/admin/merchants/$merchantId';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminSettlements = '/admin/settlements';
  static const String adminSettlementsCreate = '/admin/settlements/create';
}
