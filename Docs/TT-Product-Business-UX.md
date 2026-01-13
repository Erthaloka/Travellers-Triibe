# TRAVELLERS TRIIBE - PRODUCT, BUSINESS LOGIC & USER EXPERIENCE

**Offline Discount Payments Platform - Complete Specification**

---

# TABLE OF CONTENTS

1. [Product Requirements Document (PRD)](#1-product-requirements-document-prd)
2. [Payment Methods, Flows & Settlement Design](#2-payment-methods-flows--settlement-design)
3. [UI/UX Specification](#3-uiux-specification)
4. [UI Flows & Navigation Design](#4-ui-flows--navigation-design)
5. [Screen & Component Specification](#5-screen--component-specification)
6. [UX Research & Behavioral Design](#6-ux-research--behavioral-design)
7. [Unicode Safety & GST Verification](#7-unicode-safety--gst-verification)

---

# 1. PRODUCT REQUIREMENTS DOCUMENT (PRD)

## 1.1 Product Overview

### Problem Statement

Offline merchants want to give small discounts to attract customers, but:
- Aggregators take 30–50% commissions
- Prices are inflated
- Discounts feel fake or delayed
- Users don't trust coupons or cashback

### Solution

A **privacy-first, offline payment platform** where:
- Merchants fund small discounts (3%, 6%, 9%)
- Users see discounts **before paying**
- Payments happen via QR scan (default)
- Platform earns via a small merchant convenience fee
- No forced phone number sharing
- No price inflation

---

## 1.2 Goals & Success Metrics

### Business Goals
- Fast merchant onboarding
- High trust in discounts
- Low checkout friction
- Scalable offline adoption

### User Goals
- Pay easily
- See real savings instantly
- No privacy compromise

### Merchant Goals
- Attract customers
- Simple billing
- Predictable settlements

### Success Metrics (MVP)
- % payments completed after QR scan
- Avg. discount redeemed per user
- Merchant activation rate
- Failed payment rate < 2%

---

## 1.3 User Roles & Permissions

### Roles
- **User (Customer)**
- **Partner (Merchant)**
- **Admin**

> One account can have multiple roles. Roles unlock capabilities, not identities.

### Role Capabilities

**User**
- Scan QR
- View bill & discount
- Pay
- View savings history

**Partner (Merchant)**
- Complete onboarding
- Generate bills
- Show QR
- View transactions & settlements

**Admin**
- List / edit / delete merchants
- Approve merchants (with or without GST)
- Override settlement modes
- View all transactions
- Act as a normal user if needed

---

## 1.4 Authentication & Account Model

### Account
- Email
- Phone number
- OTP / password authentication

### Role Handling
- Default role: USER
- PARTNER role added after onboarding
- ADMIN role added internally

### Role Switching
- In-app role switcher
- No re-login required

---

## 1.5 Payment Initiation Strategy

### Primary (Default)
✅ **Option 2 – QR Scan**
- Merchant generates dynamic QR
- User scans QR in app
- No phone number shared
- No privacy risk

### Secondary (Optional, Disabled by Default)
⚠️ **Option 1 – Phone Number Bill Push**
- Enabled only for selected merchants
- Requires user consent
- Admin-controlled toggle

> MVP launches with QR Scan only

---

## 1.6 User Flow (Primary)

### Scan & Pay Flow
1. User opens app
2. Taps "Scan & Pay"
3. Scans merchant QR
4. Sees bill + discount
5. Confirms payment
6. Payment success
7. Savings recorded

### Mandatory UX Rule
User must see:
```
Original Bill
Discount Amount
Final Payable
```
**before** payment authorization.

---

## 1.7 Merchant Onboarding (M4 – IN APP)

### Business Details
- Shop name
- Category
- Address
- Contact details

### GST Verification
- GSTIN mandatory
- Verified via public records or admin review
- Admin can approve with manual verification

### Commercial Setup
- Discount slab: 3% / 6% / 9%
- Platform convenience fee (read-only)
- Settlement cycle

### Payment Enablement (Dual Mode)

**Mode A – Platform Managed (Default)**
- Payments go to platform account
- Weekly manual settlements

**Mode B – Direct Settlement (Optional)**
- Merchant completes KYC
- Split settlement enabled

### Auto-Fallback Rule
If direct settlement fails → fallback to platform mode automatically.

---

## 1.8 Merchant Daily Flow

1. Merchant enters bill amount
2. Merchant generates QR
3. User scans & pays
4. Merchant views transaction

Merchant does **not**:
- Apply discounts manually
- Handle payment logic
- Collect user phone numbers (default flow)

---

## 1.9 Discount Engine

- Discount calculated server-side
- Based on merchant's fixed slab
- Gateway only receives net payable amount
- No UI-side discount logic

---

## 1.10 Transaction Ledger (Single Source of Truth)

Each transaction stores:
- User
- Merchant
- Original bill
- Discount amount
- Platform fee
- Net paid
- Settlement mode
- Status

Ledger is immutable.

---

## 1.11 Savings & Reporting

### User Side
- Savings per transaction
- Daily / Monthly / Lifetime totals

### Merchant Side
- Discount invested
- Net revenue
- Customers via platform

### Admin Side
- Full transaction visibility
- Exportable settlement data

---

## 1.12 UI/UX Strategy

### Dual Color Palette
- **User Palette**: calm, trust-focused
- **Merchant Palette**: bold, growth-focused

Palette switches by **active role**, not account.

---

## 1.13 Non-Functional Requirements

### Performance
- QR generation < 1s
- Payment confirmation < 3s (gateway dependent)

### Security
- HTTPS everywhere
- Gateway webhook verification
- Role-based API access
- QR expiry (2–5 min)

### Privacy
- No phone number required for default flow
- No merchant access to user data
- Explicit consent for secondary flow

---

## 1.14 Out of Scope (MVP)

- Loyalty points
- Subscriptions
- Multiple gateways
- Item-level billing
- Automated refunds

---

## 1.15 Launch Criteria

MVP is ready when:
- QR Scan payment works end-to-end
- Discount visible before payment
- Merchant onboarding completes fully in app
- Admin can manage merchants & transactions
- Savings reflected correctly

---

## 1.16 Final Product Philosophy

> Users save instantly
> 
> **Merchants invest discounts**
> 
> **Admins enforce trust**
> 
> **Backend decides truth**
> 
> **Payments stay simple**

---

# 2. PAYMENT METHODS, FLOWS & SETTLEMENT DESIGN

## 2.1 Payment Roles

### Roles Involved
- **User (Customer)** → pays money
- **Merchant (Partner)** → receives money (directly or via admin)
- **Admin (Platform Operator)** → controls settlement, fallback, overrides
- **Payment Gateway** → executes payment

> Admin is the financial orchestrator when merchants don't have gateway accounts.

---

## 2.2 Payment Methods Supported (MVP)

### User → Platform
- UPI (primary)
- Cards (optional)
- Wallets (optional)

> All via Razorpay. Order-based payments only.

---

## 2.3 Payment Initiation Flows

### ✅ DEFAULT FLOW – QR SCAN (Option 2)

```
Merchant enters bill
→ Platform creates order
→ QR displayed
→ User scans
→ Discount shown
→ User pays
```

No phone number sharing. No merchant data handling.

### ⚠️ SECONDARY FLOW – Phone Number Bill Push (Optional)

*(Disabled by default, admin-controlled)*

```
Merchant enters bill
→ Merchant enters user phone
→ Bill pushed to user app
→ User approves & pays
```

Same payment engine. Higher consent controls.

---

## 2.4 Core Payment Engine

Regardless of initiation:

```
Input:
- merchant_id
- bill_amount
- discount_slab

Backend:
- calculate discount
- compute net payable
- create Razorpay order (net amount)
- wait for user authorization
- verify webhook
- lock transaction ledger
```

> Gateway NEVER sees the discount logic, only the final amount.

---

## 2.5 Settlement Modes

Every merchant operates in **one of two settlement modes**.

### 🟢 MODE A – PLATFORM-MANAGED SETTLEMENT (DEFAULT / FALLBACK)

**When used:**
- Merchant does NOT want to create Razorpay account
- Merchant prefers weekly / periodic payout
- Early-stage merchants
- Small shops

**💰 MONEY FLOW (MODE A)**

```
User → Pays via Razorpay
Razorpay → Platform Account
Platform → Holds merchant balance
Admin → Settles merchant periodically
```

💡 This is **NOT illegal escrow** – it is **aggregator settlement** with clear records.

**📘 LEDGER RECORDING (MODE A)**

For each order:
```
Gross Bill
- Discount (merchant-funded)
- Platform Fee
= Merchant Receivable
```

Merchant balance accumulates.

**⏱️ SETTLEMENT CYCLES**

Configurable per merchant:
- Weekly
- Bi-weekly
- On-demand (admin-triggered)

**👨‍💼 ADMIN RESPONSIBILITIES (MODE A)**

Admin can:
- View pending merchant balances
- Generate settlement statements
- Trigger payouts (manual / bulk)
- Mark settlements as completed
- Handle disputes

Admin **must**:
- Verify transaction success
- Keep audit logs
- Maintain payout records

---

### 🟢 MODE B – DIRECT SETTLEMENT (OPTIONAL)

**When used:**
- Merchant opts in
- Merchant completes Razorpay KYC
- Wants auto-settlement

**💰 MONEY FLOW (MODE B)**

```
User → Razorpay
Razorpay → Splits payment
   → Merchant account (net)
   → Platform account (fee)
```

Admin does **not** hold merchant funds.

**AUTO-FALLBACK TO MODE A**

If:
- KYC fails
- Account suspended
- Split payout fails

Then:
```
Auto-switch to PLATFORM mode
```

Payment **never fails**.

---

## 2.6 Admin as Settlement Operator

### Admin Dashboard Must Show

**Merchant Wallet View**
```
Merchant Name
Total Earned
Pending Balance
Last Settlement Date
Next Settlement Due
Settlement Mode
```

### Admin Settlement Actions

Admin can:
- Select one or multiple merchants
- View detailed order breakdown
- Trigger payout
- Upload payout reference
- Mark as settled

### Settlement Record (Mandatory)

Each payout stores:
```
merchant_id
amount
period
payment_method (bank/UPI)
reference_id
admin_id
timestamp
```

---

## 2.7 Admin Payments to Users (Edge Cases)

### Refunds / Adjustments

Admin can:
- Manually credit user wallet (if supported)
- Reimburse failed transactions
- Resolve disputes

> Refunds go User ← Platform, not merchant directly.

---

## 2.8 User Payment Status Flows

### Success
```
Payment Successful
Savings Applied
Order Complete
```

### Failure
```
Payment Failed
No money deducted
Retry available
```

### Pending
```
Payment Processing
Please wait
```

User never sees:
- Internal settlement mode
- Platform vs merchant flow

UX is clean.

---

## 2.9 Merchant Payment Visibility

### Merchant Sees (MODE A)
- Orders completed
- Discount invested
- Net receivable
- Pending settlement amount

### Merchant Sees (MODE B)
- Orders completed
- Net received
- Razorpay settlement ID

Merchant does **not** manage payouts.

---

## 2.10 Safety, Controls & Compliance

### Mandatory Controls
- Server-side calculation only
- Webhook signature verification
- Idempotent settlement triggers
- Payout approval limits
- Admin audit logs

### Fraud Prevention
- QR expiry
- One bill per scan
- Velocity checks
- Manual admin overrides

---

## 2.11 Failure & Fallback Scenarios

| Scenario | Result |
|----------|--------|
| User pays, webhook delayed | Mark payment as pending |
| Merchant KYC incomplete | Use PLATFORM mode |
| Split payout fails | Fallback to PLATFORM |
| Admin payout fails | Retry / manual intervention |
| Dispute raised | Freeze settlement |

---

## 2.12 Why This Model Works

- Zero merchant friction at launch
- No forced KYC
- No blocked payments
- Admin retains control
- Scales to direct settlement later
- Matches real aggregator models

---

## 2.13 Final Payment Mental Model

> Users always pay the platform
> 
> **Merchants may or may not receive directly**
> 
> **Admin always knows where money is**
> 
> **Discount is locked before payment**
> 
> **Settlement is a controlled operation**

---

# 3. UI/UX SPECIFICATION

## 3.0 Global UI & UX Rules

### Core Rules
1. **Single app, single login**
2. **Role-based UI switching**
3. **No duplicate pages per role**
4. **Same transaction = different perspective**
5. **History = Orders (food, stay, service, etc.)**
6. **Profile data is incremental, not forced**

---

## 3.1 Information Architecture (High Level)

```
AUTH
 ├── Login
 ├── OTP Verification

USER MODE
 ├── Home (Scan & Pay)
 ├── Scan QR
 ├── Payment Preview
 ├── Payment Success
 ├── Orders (History)
 ├── Order Detail
 ├── Savings
 ├── Profile

PARTNER MODE
 ├── Onboarding
 ├── Dashboard
 ├── Generate Bill / QR
 ├── Orders (History)
 ├── Order Detail
 ├── Analytics
 ├── Profile

ADMIN MODE
 ├── Dashboard
 ├── Merchants
 ├── Users
 ├── Orders (Global)
 ├── Settings
```

---

## 3.2 User Mode – Screens & Components

### 3.2.1 User Home (Scan & Pay)

**Purpose:** Primary entry point

**Components**
- AppBar (logo + profile icon)
- Primary CTA: `Scan & Pay`
- Savings Summary Card
- Optional: Nearby Partners (later)

**Data displayed**
- Monthly savings
- Total lifetime savings

**Data collected**
- None

---

### 3.2.2 QR Scanner Page

**Components**
- Camera view
- Torch toggle
- Cancel button

**Input**
- QR payload

**Output**
- merchant_id
- order/bill reference

---

### 3.2.3 Payment Preview Page (CRITICAL)

**Components**
- Merchant Info Card
- Amount Breakdown Card
- Primary Pay Button
- Cancel Button

**Fields shown**
```
Merchant Name
Category (optional)
GST badge (optional)

Bill Amount
Discount %
Discount Amount
Final Payable
```

**Rules**
- Read-only
- No editing
- Must load < 1 second

---

### 3.2.4 Payment Success Page

**Components**
- Success Icon
- Savings Highlight
- Order Summary
- Action buttons

**Fields shown**
```
Amount Paid
Savings Gained
Merchant Name
Date/Time
```

---

### 3.2.5 Orders (User History)

> This is NOT called "Transactions". For users → **Orders**

**Order Types**
- Food
- Stay (hotel)
- Service
- Retail

*(Type comes from merchant category)*

**List View**
- Merchant Name
- Order Type
- Amount Paid
- Date
- Status

**Filter**
- All / Food / Stay / Service
- Date range

---

### 3.2.6 User Order Detail Page

**Fields**
```
Order ID
Merchant Name
Order Category
Original Bill
Discount Applied
Amount Paid
Payment Mode
Date & Time
```

---

### 3.2.7 User Savings Page

**Components**
- Total Savings Card
- Monthly Savings Chart
- Savings by Category

---

### 3.2.8 User Profile Page

**Fields collected**
- Name
- Phone (verified)
- Email
- Optional: Gender
- Optional: DOB

**Actions**
- Switch role
- Become Partner
- Logout

---

## 3.3 Partner Mode – Screens & Components

### 3.3.1 Partner Onboarding Pages

**Step 1: Business Details**

**Fields**
```
Business Name
Category (Food / Stay / Service / Retail)
Address
City
State
```

**Step 2: GST (Mandatory)**

**Fields**
```
GSTIN
Upload GST certificate
```

**Step 3: Commercial Setup**

**Fields**
```
Discount Slab (3 / 6 / 9%)
Settlement Mode (Platform / Direct)
```

(Read-only platform fee shown)

---

### 3.3.2 Partner Dashboard

**Cards**
- Today's Orders
- Today's Revenue
- Discount Given
- Settlement Status

**Primary CTA**
- Generate Bill / QR

---

### 3.3.3 Generate Bill / QR Page

**Fields**
```
Bill Amount (numeric)
```

**Components**
- Amount input
- Generate QR button
- Dynamic QR view
- Timer

---

### 3.3.4 Partner Orders (History)

> For partner, history is also "Orders". Same data, business view.

**List Fields**
- Order ID
- Order Type
- Bill Amount
- Discount Given
- Net Received
- Status
- Date

---

### 3.3.5 Partner Order Detail Page

**Fields**
```
Order ID
User ID (masked)
Order Category
Original Bill
Discount Given
Platform Fee
Net Receivable
Settlement Mode
Status
```

---

### 3.3.6 Partner Analytics Page

**Metrics**
- Total Orders
- Repeat Users
- Discount Invested
- Net Revenue
- Avg Order Value

---

### 3.3.7 Partner Profile Page

**Fields**
```
Business Name
Category
GST Status
Discount Slab
Settlement Mode
```

---

## 3.4 Admin Mode – Screens & Components

### 3.4.1 Admin Dashboard

- GMV
- Total Discounts
- Active Merchants
- Orders Today

---

### 3.4.2 Merchant Management

**List Fields**
- Merchant Name
- Category
- GST Status
- Discount Slab
- Settlement Mode
- Status

**Actions**
- Approve
- Edit
- Suspend
- Delete
- Override GST requirement

---

### 3.4.3 User Management

**Fields**
- User ID
- Phone
- Email
- Total Orders
- Savings

---

### 3.4.4 Admin Orders (Global)

> This is the master ledger

Filters:
- User
- Merchant
- Order Type
- Date
- Settlement Mode

---

## 3.5 History Model (Important Clarification)

### Naming
- **User side:** Orders
- **Partner side:** Orders
- **Admin side:** Orders / Ledger

### Why "Orders"?

Because:
- Food → order
- Stay → booking
- Service → appointment
- Retail → purchase

Internally:
```
order_type ENUM (FOOD, STAY, SERVICE, RETAIL)
```

---

## 3.6 Common UI Components (Reusable)

- RoleSwitcher
- AmountBreakdownCard
- OrderListItem
- OrderStatusBadge
- SavingsCard
- QRScanner
- QRDisplay
- ProfileField

---

## 3.7 Data Collection Policy

### Collected Always
- Phone
- Email
- Order data

### Optional
- GST
- Gender
- DOB

### Never Collected (by default)
- Customer phone at merchant
- Card details
- Personal identifiers beyond need

---

## 3.8 Page Count Summary (MVP)

### User
- 9 pages

### Partner
- 9 pages

### Admin
- 6–7 pages

**Total Screens (including shared): ~18–20**

---

## 3.9 Final Clarity Statement

- History = Orders
- Orders categorized by merchant type
- Same order shown differently per role
- Profile data collected progressively
- QR flow is default
- Privacy preserved

---

# 4. UI FLOWS & NAVIGATION DESIGN

## 4.0 Core Navigation Principles

1. **Single app, single navigation system**
2. **Role decides available routes**
3. **No duplicate flows**
4. **Always one primary action per screen**
5. **Payments are linear, never branching**
6. **Admin flows are isolated but accessible**
7. **Back button behavior is deterministic**

---

## 4.1 App Entry & Auth Flow

### App Launch Flow

```
App Launch
 → Check auth token
   → Token valid → Go to Last Active Role
   → Token invalid → Login Screen
```

### Login Flow

```
Login Screen
 → Verify credentials
 → Receive JWT + roles[]
 → If first login:
      → Role Selection Screen
   Else:
      → Redirect to last active role home
```

### Role Selection (First-time only)

```
Choose:
 → Continue as User
 → Register as Partner
```

⚠️ This only sets **initial navigation**, not permissions.

---

## 4.2 Global Navigation Structure

### Navigation Model
- **Single root Navigator**
- Role-based route guards
- No nested navigation chaos

### Global Components (Always Present)
- AppBar (title / role indicator)
- Profile icon
- Role Switcher (from profile)

---

## 4.3 User Mode – Full Flow Map

### User Primary Flow (Happy Path)

```
User Home
 → Scan QR
   → Payment Preview
     → Pay
       → Payment Success
         → View Order OR Go Home
```

This is the **most optimized path** – no distractions.

### User Home Navigation

```
User Home
 ├── Scan & Pay (primary CTA)
 ├── Orders
 ├── Savings
 └── Profile
```

User Home uses:
- Bottom navigation OR
- Top-level tabs (your choice)

But **Scan & Pay must be the easiest tap**.

### Scan Flow

```
Scan Screen
 → QR detected
   → Validate QR
     → Payment Preview
```

Error paths:
```
QR expired → Error message → Back to Scan
Invalid QR → Error message → Back to Scan
```

### Payment Flow (STRICT, LINEAR)

```
Payment Preview
 → Pay (Razorpay)
   → Success → Payment Success Screen
   → Failure → Failure Screen → Retry/Back
```

🚫 No other navigation allowed here.

### Post-Payment Flow

```
Payment Success
 ├── View Order → Order Detail
 └── Go Home → User Home
```

### User Orders Flow

```
Orders List
 → Order Detail
   → Back to Orders
```

No edits. No actions.

### User Profile Flow

```
Profile
 ├── Edit Profile
 ├── View Savings
 ├── Become Partner
 ├── Switch Role
 └── Logout
```

### User → Partner Conversion Flow

```
User Profile
 → Become Partner
   → Partner Onboarding
     → Partner Dashboard
```

---

## 4.4 Partner Mode – Full Flow Map

### Partner Primary Flow

```
Partner Dashboard
 → Generate Bill / QR
   → QR Display
     → Waiting for Payment
```

This flow must be **fast and repeatable**.

### Partner Dashboard Navigation

```
Partner Dashboard
 ├── Generate QR (primary)
 ├── Orders
 ├── Analytics
 └── Profile
```

### Generate Bill Flow

```
Generate Bill
 → Enter Bill Amount
 → Generate QR
 → QR Display (timer)
   → Payment Success (auto)
     → Back to Dashboard
```

Merchant does NOT confirm payment – backend does.

### Partner Orders Flow

```
Partner Orders
 → Order Detail
   → Back to Orders
```

Orders are **read-only**.

### Partner Analytics Flow

```
Analytics
 → View Metrics
   → Back to Dashboard
```

No drill-down actions for MVP.

### Partner Profile Flow

```
Profile
 ├── View Business Info
 ├── View Discount Slab
 ├── View Settlement Mode
 ├── Switch to User
 └── Logout
```

---

## 4.5 Admin Mode – Full Flow Map

> Admin is a role overlay, not a different app.

### Admin Entry Flow

```
Any Screen
 → Profile
   → Switch Role
     → Admin Dashboard
```

### Admin Dashboard Navigation

```
Admin Dashboard
 ├── Merchants
 ├── Orders (Global)
 ├── Settlements
 ├── Users
 └── Settings
```

### Admin Merchant Flow

```
Merchants List
 → Merchant Detail
   ├── Approve/Suspend
   ├── Edit Details
   ├── Override Settlement Mode
   └── Back to List
```

### Admin Orders Flow

```
Orders (Global)
 → Order Detail
   → Back
```

Admin **never edits orders**.

### Admin Settlement Flow

```
Settlements
 → Pending Merchants
   → Select Merchant
     → View Orders
       → Trigger Settlement
         → Mark Paid
```

### Admin Users Flow

```
Users List
 → User Detail
   ├── View Orders
   ├── Block/Unblock
   └── Back
```

---

## 4.6 Role Switching Flow (Critical)

```
Profile
 → Role Switcher
   → Select Role
     → Redirect to Role Home
```

Rules:
- No logout
- No re-auth
- Navigation stack is reset

---

## 4.7 Back Button Behavior

### Global Rules

- Back NEVER:
  - Cancels payment silently
  - Skips confirmation screens
- Back ALWAYS:
  - Returns to previous logical step

### Payment Flow Back Rules

```
Payment Preview
 → Back → Scan Screen
Payment Success
 → Back → User Home
```

### QR Screen Back Rules

```
QR Screen
 → Back → Home
```

---

## 4.8 Error & Exception Flows

### Common Errors
- Network failure
- QR expired
- Payment failed

### Error Flow Pattern

```
Show error message
 → Single CTA (Retry OR Go Back)
```

Never show multiple confusing options.

---

## 4.9 Offline & Slow Network Flow

```
App Launch
 → Show cached home (SQLite)
 → Show offline banner
 → Disable Scan & Pay
```

Once online:
```
Auto-refresh
 → Enable Scan & Pay
```

---

## 4.10 Full End-to-End Flow Summary

### User
```
Login → Home → Scan → Preview → Pay → Success → Order History
```

### Merchant
```
Login → Dashboard → Bill → QR → Payment → Orders → Settlement
```

### Admin
```
Login → Dashboard → Merchants/Orders/Settlements → Control
```

---

## 4.11 Final Navigation Mental Model

> One app.
> One way forward.
> No confusion.
> No loops during payment.

If a user or merchant ever asks: *"What should I tap next?"* — then the navigation failed.

---

# 5. SCREEN & COMPONENT SPECIFICATION

## 5.0 Scope

- What screens exist
- What components are inside each
- What data is shown / collected
- What actions happen
- What backend calls trigger

---

## 5.1 Auth & Role Entry

### 1️⃣ Login Screen

**Purpose:** Authenticate **all roles** (User / Partner / Admin)

**Components:**
- Email input (required)
- Phone number input (required)
- OTP / Password input
- Login button
- Error text (inline)

**Functional Rules:**
- Login method is same for all roles
- Backend returns `roles[]`
- After login → redirect based on last active role

**API:**
```
POST /auth/login
```

---

### 2️⃣ Role Selection Screen (First-time only)

**Purpose:** Let user choose **initial mode** (non-binding)

**Components:**
- Button: Continue as User
- Button: Register as Partner
- Info text (can switch later)

**Logic:**
- No data stored permanently
- Only controls first redirect

---

## 5.2 User Mode Screens

### 3️⃣ User Home Screen

**Purpose:** Primary landing for users

**Components:**
- Header (App title + Profile icon)
- Primary CTA: Scan & Pay (button)
- Recent Section:
  - Previously Ordered (Food)
  - Previously Stayed (Stay)
  - Previously Used (Service)
- Savings Summary Card

**Data Shown:**
- Cached recent merchants (from SQLite)
- Total savings (API)

**Actions:**
- Tap Scan → Scanner screen
- Tap merchant → optional future deep-link

**APIs:**
```
GET /user/home/recents
GET /user/savings/summary
```

---

### 4️⃣ QR Scanner Screen

**Purpose:** Scan merchant-generated QR

**Components:**
- Camera view
- Torch toggle
- Cancel button
- QR detection overlay

**Logic:**
- QR must be platform-generated
- On scan → validate QR payload
- If expired → show error

**API:**
```
POST /qr/validate
```

---

### 5️⃣ Payment Preview Screen (MOST CRITICAL)

**Purpose:** Show **bill + discount BEFORE payment**

**Components:**
- Merchant Info Card
  - Merchant Name
  - Category
  - GST badge (if any)
- Amount Breakdown Card
  - Original Bill
  - Discount %
  - Discount Amount
  - Final Payable
- Button: Pay Now
- Button: Cancel

**Rules:**
- All values are **read-only**
- Discount is server-calculated only

**Actions:**
- Pay → payment gateway
- Cancel → return to home

**API:**
```
POST /payment/prepare
```

---

### 6️⃣ Payment Processing Screen

**Purpose:** Handle gateway interaction

**Components:**
- Loading indicator
- Gateway webview / native SDK

**Logic:**
- On success → Payment Success screen
- On failure → error screen

---

### 7️⃣ Payment Success Screen

**Purpose:** Confirm payment & reinforce savings

**Components:**
- Success icon
- Text: "You saved ₹X"
- Order Summary Card
- Button: View Order
- Button: Go to Home

**API:**
- None (data passed from previous step)

---

### 8️⃣ User Orders (History) Screen

**Purpose:** Unified order history

**Components:**
- Tab / filter:
  - All
  - Food
  - Stay
  - Service
- Orders List
  - Merchant Name
  - Category
  - Amount Paid
  - Date
  - Status badge

**Logic:**
- Sorted by most recent
- Pagination / lazy load

**API:**
```
GET /user/orders
```

---

### 9️⃣ User Order Detail Screen

**Purpose:** Detailed view of a single order

**Components:**
- Merchant Info
- Order Info
  - Order ID
  - Date & Time
  - Category
- Payment Info
  - Original Bill
  - Discount
  - Net Paid
  - Payment Method

**API:**
```
GET /orders/{order_id}
```

---

### 🔟 User Profile Screen

**Purpose:** View & manage personal info

**Components:**
- Name
- Phone (read-only verified)
- Email
- Optional fields:
  - Gender
  - DOB
- Button: Become Partner
- Button: Switch Role
- Logout button

**APIs:**
```
GET /user/profile
PUT /user/profile
```

---

## 5.3 Partner (Merchant) Mode Screens

### 1️⃣1️⃣ Partner Onboarding – Step 1 (Business Details)

**Components:**
- Business Name
- Category selector (Food / Stay / Service / Retail)
- Address fields
- Continue button

**API:**
```
POST /partner/onboarding/business
```

---

### 1️⃣2️⃣ Partner Onboarding – Step 2 (GST)

**Components:**
- GSTIN input
- Upload document
- Continue button

**API:**
```
POST /partner/onboarding/gst
```

---

### 1️⃣3️⃣ Partner Onboarding – Step 3 (Commercial Setup)

**Components:**
- Discount slab selector (3 / 6 / 9)
- Settlement mode selector:
  - Platform Managed (default)
  - Direct Settlement (optional)
- Platform fee (read-only)

**API:**
```
POST /partner/onboarding/commercials
```

---

### 1️⃣4️⃣ Partner Dashboard

**Purpose:** Merchant overview

**Components:**
- Cards:
  - Today's Orders
  - Today's Revenue
  - Discount Given
  - Pending Settlement
- Primary CTA: Generate Bill / QR

**API:**
```
GET /partner/dashboard
```

---

### 1️⃣5️⃣ Generate Bill / QR Screen

**Components:**
- Bill Amount input
- Generate QR button
- QR Display
- Expiry timer

**Logic:**
- Only one active bill at a time
- QR expires after X minutes

**API:**
```
POST /partner/bill/create
```

---

### 1️⃣6️⃣ Partner Orders Screen

**Components:**
- Orders list:
  - Order ID
  - User (masked)
  - Bill
  - Discount
  - Net receivable
  - Status
- Filter:
  - Date
  - Category

**API:**
```
GET /partner/orders
```

---

### 1️⃣7️⃣ Partner Order Detail Screen

**Components:**
- Order Info
- User (masked)
- Financial breakdown
- Settlement info

---

### 1️⃣8️⃣ Partner Analytics Screen

**Components:**
- Total orders
- Discount invested
- Net earnings
- Repeat customers

**API:**
```
GET /partner/analytics
```

---

### 1️⃣9️⃣ Partner Profile Screen

**Components:**
- Business Info
- Category
- GST status
- Discount slab
- Settlement mode
- Switch to User

---

## 5.4 Admin Mode Screens

### 2️⃣0️⃣ Admin Dashboard

**Components:**
- Total GMV
- Total Orders
- Active Merchants
- Pending Settlements

**API:**
```
GET /admin/dashboard
```

---

### 2️⃣1️⃣ Admin Merchant Management

**Components:**
- Merchant List
- Actions:
  - Approve
  - Edit
  - Suspend
  - Delete
  - Override GST
  - Change settlement mode

**API:**
```
GET /admin/merchants
PUT /admin/merchants/{id}
```

---

### 2️⃣2️⃣ Admin Orders (Global)

**Components:**
- Full order table
- Filters:
  - User
  - Merchant
  - Category
  - Date
  - Settlement mode

**API:**
```
GET /admin/orders
```

---

### 2️⃣3️⃣ Admin Settlements

**Purpose:** Manual payouts

**Components:**
- Merchant balances
- Settlement period picker
- Payout trigger
- Status tracking

**API:**
```
POST /admin/settlements/create
GET /admin/settlements
```

---

### 2️⃣4️⃣ Admin Users

**Components:**
- User list
- Order count
- Savings
- Block / unblock

---

## 5.5 Global Components (Reusable)

- Role Switcher
- Order List Item
- Amount Breakdown Card
- QR Scanner
- QR Display
- Status Badge
- Error Dialog
- Loading Overlay

---

## 5.6 Final Implementation Rules

1. Orders = single source of truth
2. Discounts always server-side
3. QR scan is default
4. Cache only for UX (SQLite)
5. Admin controls settlement
6. No financial data cached locally

---

# 6. UX RESEARCH & BEHAVIORAL DESIGN

## 6.1 Core UX Philosophy

### Fundamental Truth

> People do not fear paying – they fear uncertainty.

So UX must eliminate:
- Doubt
- Surprise
- Loss of control
- Feeling "tricked"

Every UX decision must answer **one question:**
> "Is the user confident before tapping Pay?"

---

## 6.2 Primary User Personas

### 👤 User Persona: "Everyday Offline Payer"

- Uses UPI daily
- Scans QR instinctively
- Distrusts cashback & coupons
- Wants **instant clarity**
- Hates signup friction

🧠 Mental model:
> "Show me the final amount clearly and don't take my data."

---

### 🪙 Merchant Persona: "Margin-Protective Shop Owner"

- Thin margins
- Fear of aggregators
- Wants customers, not complexity
- Avoids tech friction
- Wants predictable money flow

🧠 Mental model:
> "Don't touch my pricing. Don't slow my counter."

---

### 🧑‍💼 Admin Persona: "Risk Controller"

- Wants scale **without chaos**
- Fears fraud more than churn
- Needs override power
- Needs audit trail

🧠 Mental model:
> "Everything should be traceable."

---

## 6.3 Why Option 2 (QR Scan) is UX-Optimal

### User Psychology
- QR scan is **muscle memory**
- No decision fatigue
- No identity exposure
- No verbal interaction needed

### Merchant Psychology
- Same as standard UPI flow
- No customer data handling
- No compliance fear

### UX Insight

> When behavior is habitual, don't redesign it – enhance it.

So:
- Default = QR scan
- Discount shown **after scan, before pay**

This matches **natural UPI flow** with **added value**, not disruption.

---

## 6.4 Why Phone Number Bill Push is Secondary

### User Side Concerns
- "Why does this shop need my number?"
- "Will I get spam?"
- "Did I consent?"

### Merchant Side Risks
- Accidental misuse
- Data protection responsibilities
- Customer distrust

### UX Decision

> Convenience must never override consent.

So:
- Phone-based flow is **optional**
- Explicit permission
- Admin-controlled

---

## 6.5 Discount Visibility – Most Critical UX Moment

### UX Research Insight

> If discount appears after payment → it feels fake.

### Required Sequence

```
Scan →
Identify merchant →
Show bill →
Show discount →
Show final payable →
Pay
```

### Emotional State

- "I saved money" BEFORE payment
- Not "I might get cashback later"

This transforms:
❌ Incentive-based behavior

into

✅ Trust-based habit

---

## 6.6 Why Users Never Edit Bill Amount

Allowing users to edit:
- Creates doubt
- Invites fraud
- Breaks merchant trust

UX Rule:
> Users do not negotiate with the bill. They verify it.

So:
- Bill = read-only
- Cancel option available
- Trust preserved

---

## 6.7 Role-Based UX – Same App, Different Feel

### Research Insight

> Same person, different intent = different cognitive mode

**User Mode:**
- Calm
- Focused
- Low stimulation

**Merchant Mode:**
- Busy
- Action-oriented
- Performance focused

**Admin Mode:**
- Analytical
- Risk aware
- Serious

Thus:
- Same app
- Same login
- **Different palettes, layouts, emphasis**

This prevents **role confusion**.

---

## 6.8 Why History is Called "Orders"

### Research

"Transaction" is:
- Technical
- Cold
- Bank-like

"Order" is:
- Human
- Contextual
- Understandable

### Cognitive Mapping

- Food → Order
- Stay → Booking
- Service → Appointment
- Retail → Purchase

So UX shows:
> Orders, grouped by category

This increases:
- Recall
- Trust
- Emotional clarity

---

## 6.9 User History UX – What Users Actually Check

Users rarely check:
- Payment IDs
- Gateway references

Users often check:
- Where they paid
- How much they paid
- How much they saved
- When it happened

So history emphasizes:
1. Merchant name
2. Amount paid
3. Savings
4. Date/time

Everything else is secondary.

---

## 6.10 Merchant History UX – Business Thinking

Merchants think in:
- Revenue
- Discounts invested
- Net outcome
- Patterns

They **don't** think in "payments".

So partner UX emphasizes:
- Net received
- Discount cost
- Customer count
- Settlement clarity

> Language reframes discount as investment, not loss.

---

## 6.11 Why QR Expiry is UX-Friendly

Expired QR:
- Prevents accidental payments
- Prevents wrong-user scans
- Creates clarity

UX Message:
> "This bill is no longer active. Ask merchant to regenerate."

This avoids:
- Confusion
- Disputes
- Panic payments

---

## 6.12 Admin as User – UX Research Decision

Admins:
- Need real-world experience
- Need to test flows
- Need empathy for users

So admin:
- Can pay like a user
- Can view platform as customer

But admin actions are:
- Clearly separated
- Visually distinct
- Logged

This avoids **power misuse confusion**.

---

## 6.13 Why We Don't Force Profile Completion

Research shows:
> Forced data entry reduces trust in payments.

So:
- Profile grows gradually
- Only phone/email required
- Optional fields later

This keeps:
- Conversion high
- Drop-off low

---

## 6.14 Error States UX

### Principles
- Never blame user
- Never expose system errors
- Always give next step

Examples:
- "QR expired – please rescan"
- "Payment not completed – no money deducted"
- "Try again"

Error UX = **trust repair**, not messaging.

---

## 6.15 Emotional Peaks & Memory

### UX Research Rule

> Users remember peaks & endings, not flows.

So you optimize:
- **Peak:** Seeing discount before pay
- **Ending:** Savings confirmation after payment

These two moments create **habit memory**.

---

## 6.16 What We Intentionally Do NOT Optimize

- Loyalty gimmicks
- Gamification
- Animated overload
- Aggressive upsells

Why?
> Payments UX should be boring, predictable, and honest.

Excitement comes from **money saved**, not animations.

---

## 6.17 Final UX Principles

1. Clarity over cleverness
2. Trust over incentives
3. Habit over novelty
4. Privacy over convenience
5. Simplicity over features

---

## 6.18 UX Mental Model (One Line)

> "Scan like UPI. See savings early. Pay confidently."

That is the entire experience.

---

# 7. UNICODE SAFETY & GST VERIFICATION

## 7.1 Unicode Safety & Normalization Strategy

### Why Unicode Issues Happen

Unicode problems usually come from:
- Copy-pasted merchant names
- Emojis / smart quotes
- Mixed encodings (UTF-8 vs UTF-16)
- Invisible characters (ZWJ, NBSP)
- Different normalization forms (NFC vs NFD)
- Improper DB or JSON handling
- QR payload encoding mismatches

💉 Payments + QR + logs = **zero tolerance**.

---

### Global Hard Rule

> All text that enters the system MUST be normalized to UTF-8 + NFC exactly once.

Never multiple times. Never at random places.

---

### Backend (Node.js) – Primary Defense Line

**Encoding Rule:**
- Entire backend must assume **UTF-8**
- JSON only
- No binary text fields

Node.js is UTF-8 safe **by default**, but normalization is **NOT automatic**.

**Mandatory Text Normalization Utility:**

Create ONE utility and use it **everywhere text enters**.

`core/utils/textNormalizer.js`

```javascript
/**
 * Normalizes user-provided text to prevent Unicode issues.
 * - Converts to string
 * - Normalizes to NFC
 * - Trims
 * - Removes invisible chars
 */
function normalizeText(input) {
  if (!input) return '';
  
  return String(input)
    .normalize('NFC')
    .replace(/[\u200B-\u200D\uFEFF]/g, '') // zero-width chars
    .trim();
}

module.exports = { normalizeText };
```

**Where to Apply (Mandatory):**

Normalize **only at entry points:**
- Merchant onboarding (business name, address)
- User profile (name)
- Admin edits
- Phone-number billing (if enabled)
- QR payload generation

❌ Do NOT normalize repeatedly downstream

---

### Database (MongoDB) – Safe by Default

MongoDB stores UTF-8 natively ✔️

But **comparison & indexing** can fail if normalization differs.

**Rules:**
- Store **only normalized strings**
- Never store raw input
- Never compare un-normalized strings

---

### Flutter (Dart) – Second Defense Line

Dart strings are UTF-16 internally – mostly safe – but input can still contain junk.

`core/utils/text_normalizer.dart`

```dart
String normalizeText(String? input) {
  if (input == null) return '';
  return input
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
      .trim();
}
```

**Where to use (ONLY):**
- TextField submission
- Form save / submit
- Not on every keystroke

---

### QR Code – Most Critical Unicode Risk

**Absolute Rule for QR Payloads:**

> QR payload must be ASCII-only or Base64-encoded JSON

Never raw Unicode text inside QR.

**Correct QR Payload Strategy:**

Instead of:
```
merchant_name|₹540|6%
```

Use:
```json
{
  "bill_id": "br_123456",
  "merchant_id": "m_101",
  "exp": 1700000000
}
```

Then:
- JSON stringify
- Base64 encode
- Put into QR

This avoids:
❌ Emoji crash
❌ Encoding mismatch
❌ Scanner bugs

---

### Payment Gateway (Razorpay) – Strict Limits

Razorpay expects:
- UTF-8
- No emojis in key fields

**DO NOT SEND Unicode Here:**
- order.notes
- receipt
- merchant labels

Sanitize these fields:
```javascript
receipt: `order_${orderId}` // ASCII only
```

---

### Phone Numbers – Never String-Mangle

**Rule:**
- Always store phone numbers in **E.164 format**
- Digits + "+" only

**Validation:**
```
+91XXXXXXXXXX
```

Never allow:
- Spaces
- Unicode digits
- Hyphens

This prevents:
- OTP failures
- Duplicate accounts
- Index mismatches

---

### Logging – Silent Unicode Killer

Logs can break terminals, parsers, CI tools.

**Logging Rule:**
- Log IDs, not raw text
- Never log merchant names or addresses
- No emojis in logs

Example:
```javascript
logger.info(`Order created: ${orderId}`);
```

Not:
```javascript
logger.info(`Order created for Café ☕️`);
```

---

### API Contracts – Never Rely on Client Strings

**Golden Rule:**

> Server never trusts client text.

Client sends text → server normalizes → server stores.

Client must:
- Display server-returned text
- Never assume local formatting is final

---

### Test Cases (Do This Once)

Before launch, test with:
- Accented characters (é, ñ)
- Hindi / regional languages
- Emoji pasted into name field
- Copy-paste from WhatsApp
- Mixed scripts

Expected:
- Emojis removed (or rejected)
- Names stored clean
- No crashes
- No mismatches

---

### Final Unicode Mental Model

> Normalize once.
> Store normalized only.
> Transmit IDs, not text.
> QR = ASCII only.
> Emojis never touch money.

Follow this and you will **never debug Unicode issues at 2 AM**.

---

## 7.2 GST Verification (Mandatory)

### Core Rule (Locked)

> Every merchant MUST have a valid GSTIN to operate on the platform.
> 
> No GST → No transactions → No QR → No payments.

This is now a **hard gate**, not a trust signal.

---

### Where M4 Sits in Flow

```
Partner Onboarding
 → Business Details (M1)
 → Commercial Setup (M2)
 → Settlement Setup (M3)
 → GST Verification (M4)  ← BLOCKING STEP
 → Partner Dashboard
```

A merchant **cannot enter dashboard** unless M4 is completed and verified.

---

### GST Verification States (Strict)

| Status | Meaning | Allowed |
|--------|---------|---------|
| `NOT_SUBMITTED` | GST not provided | ❌ Blocked |
| `SUBMITTED` | GST submitted | ❌ Blocked |
| `VERIFIED` | GST verified | ✅ Full access |
| `REJECTED` | Invalid / mismatch | ❌ Blocked |

➡ Only `VERIFIED` merchants can:
- Generate QR
- Receive payments
- Appear to users

---

### Database Fields (Final)

`merchant.gst` (MongoDB)

```javascript
gst: {
  gstin: String, // REQUIRED, uppercase, normalized
  legal_name: String, // REQUIRED
  trade_name: String, // Optional
  state_code: String, // Derived from GSTIN
  verification_status: "NOT_SUBMITTED" | "SUBMITTED" | "VERIFIED" | "REJECTED",
  verification_method: "GST_API" | "ADMIN_REVIEW",
  submitted_at: Date,
  verified_at: Date,
  verified_by: ObjectId // admin account_id
}
```

---

### Merchant Input Fields (M4 Screen)

**Mandatory Fields (Cannot Skip):**

| Field | Required | Rules |
|-------|----------|-------|
| GSTIN | ✅ Yes | 15 chars, uppercase |
| Legal Business Name | ✅ Yes | Must match GST |
| Upload GST Certificate | ✅ Yes | PDF / JPG / PNG |
| Consent Checkbox | ✅ Yes | Legal confirmation |

**UX Copy (Important):**
> "GST verification is mandatory to accept payments on the platform."

No soft language. No skip button.

---

### Validation Rules (Backend – Strict)

**GSTIN Validation:**
- Length = 15
- Uppercase only
- Alphanumeric
- Valid state code
- Valid PAN pattern

If validation fails:
```
verification_status = REJECTED
```

---

### Verification Methods (Implementation)

**✅ METHOD 1 – GST API (AUTO-VERIFY, PREFERRED)**

If GST API is available:
```
Merchant submits GSTIN
→ Fetch GST data
→ Match legal_name + state
→ Auto-mark VERIFIED
```

Mismatch → `REJECTED`

**✅ METHOD 2 – ADMIN REVIEW (FALLBACK)**

```
Merchant submits GST + document
→ Status = SUBMITTED
→ Appears in Admin Queue
→ Admin verifies manually
→ VERIFIED / REJECTED
```

---

### Admin Flow (M4)

**Admin Verification Queue**

Admin sees:
- Business Name
- GSTIN
- Legal Name
- Uploaded Certificate
- State
- Submission Date

Admin actions:
- ✅ Verify
- ❌ Reject (mandatory reason)
- 🔄 Re-request details

All actions logged.

---

### Hard Block Rules (Critical)

If `verification_status != VERIFIED`:

- ❌ Generate QR → blocked
- ❌ Receive payments → blocked
- ❌ Appear in user app → hidden
- ❌ Settlement → disabled

Merchant sees:
> "Complete GST verification to start accepting payments."

---

### User-Side Display (Required)

- All listed merchants are **GST Verified**
- Show "GST Verified" badge
- **Never show GSTIN**

This increases user trust.

---

### Security & Compliance

- GSTIN stored encrypted at rest (optional but recommended)
- GST documents private to admin
- No GST data sent to payment gateway
- No GST data exposed in APIs to users

---

### Unicode & Data Safety (GST-Specific)

- Normalize GSTIN:
  - Uppercase
  - Strip spaces
  - ASCII only
- Reject any Unicode character
- Validate before DB save

---

### What is NOT Allowed Anymore

- ❌ Admin listing merchants without GST
- ❌ Skipping M4
- ❌ Temporary approval
- ❌ Payments during pending verification

This keeps you **fully compliant**.

---

### Final M4 Mental Model (Updated)

> GST is a compliance gate.
> 
> **Verification is mandatory.**
> 
> **No GST = No money movement.**
> 
> **Admin validates authenticity.**

---

### Implications (Good News)

With mandatory GST:
- Easier regulatory conversations
- Cleaner merchant base
- Higher user trust
- Fewer fraud cases
- Easier scaling later (invoices, B2B)

---

# DOCUMENT END

**Version:** 1.0  
**Last Updated:** December 2024  
**Status:** Final Specification
