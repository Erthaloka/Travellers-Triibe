# User Feature Context

## Purpose
Handles all customer-facing functionality - payments, order history, savings tracking, and profile management.

## Responsibilities
- Scan QR codes to initiate payments
- View payment preview with discount details (READ-ONLY)
- Process payments via Razorpay
- View order history with filtering
- Track savings (today, month, lifetime)
- Manage profile and switch to Partner mode

## Does NOT Handle
- Partner/Admin functionality
- Discount calculations (server-side only)
- Direct merchant management

## Key Files
- `user_home_page.dart` - Main landing with Scan & Pay CTA
- `scan_page.dart` - QR code scanner
- `payment_preview_page.dart` - Shows bill breakdown before payment
- `payment_success_page.dart` - Success screen with savings highlight
- `orders_page.dart` - Order history list
- `order_detail_page.dart` - Single order details
- `user_profile_page.dart` - Profile management

## Key APIs Used
- GET /orders (user's orders)
- GET /orders/:id (order detail)
- POST /payment/validate-qr
- POST /payment/prepare
- GET /me (user profile)

## Payment Flow (CRITICAL)
```
User Home
  → Scan QR (camera)
    → Validate QR token
      → Payment Preview (READ-ONLY)
        - Merchant info
        - Original bill
        - Discount amount (from server)
        - Final payable
        → Pay Now
          → Razorpay SDK
            → Success → Payment Success page
            → Failure → Show error, stay on preview
```

## Demo Mode
- All payments succeed with mock data
- Savings accumulate locally
- Orders appear in history

## Cache Strategy
- Recent merchants: SQLite cache, 15-30 min TTL
- Invalidate on payment success
- Never cache financial data
