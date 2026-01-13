# Partner Feature Context

## Purpose
Handles merchant-facing functionality - onboarding, bill generation, QR codes, order management, and analytics.

## Responsibilities
- Partner onboarding (3-step process)
- Generate bills and QR codes for payments
- View and manage partner orders
- Track analytics and earnings
- Manage partner profile and settings

## Does NOT Handle
- User payments (handled in user feature)
- Admin approvals (handled in admin feature)
- Direct discount calculations (server-side only)

## Key Files
- `onboarding/business_details_page.dart` - Step 1: Business info
- `onboarding/gst_page.dart` - Step 2: GST verification (MANDATORY)
- `onboarding/commercials_page.dart` - Step 3: Discount slab & settlement
- `partner_dashboard_page.dart` - Main dashboard with stats
- `generate_qr_page.dart` - Bill amount input and QR display
- `partner_orders_page.dart` - Order list for partner
- `analytics_page.dart` - Earnings and statistics
- `partner_profile_page.dart` - Business profile management

## Onboarding Flow (CRITICAL)
```
User selects "Become Partner"
  → Step 1: Business Details
    - Business Name
    - Category (Food/Stay/Service/Retail)
    - Address (City, State, Pincode)
  → Step 2: GST Verification (MANDATORY)
    - GSTIN input (15 chars)
    - Legal Business Name
    - Consent checkbox
  → Step 3: Commercial Setup
    - Discount slab (3% / 6% / 9%)
    - Settlement mode (Platform / Direct)
    - Platform fee display (read-only)
  → Success → Partner Dashboard
```

## Key APIs Used
- POST /partner/onboard (submit onboarding)
- GET /partner/dashboard (today's stats)
- POST /partner/bill (create bill with QR)
- GET /partner/orders (partner's orders)
- GET /partner/analytics (earnings data)

## Demo Mode
- Onboarding succeeds immediately
- QR codes generated with mock tokens
- Orders appear with sample data
- Analytics show demo figures

## Business Rules
- GST verification is MANDATORY (no bypass)
- Discount slabs: 3%, 6%, 9% only
- Settlement modes: Platform (T+1) or Direct
- Platform fee: 1% of transaction value
