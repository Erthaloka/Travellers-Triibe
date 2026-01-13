# TRAVELLERS TRIIBE - TECHNICAL ARCHITECTURE, DATABASE & APIs

**Offline Discount Payments Platform - Complete Technical Specification**

---

# TABLE OF CONTENTS

1. [Technology Stack & Infrastructure](#1-technology-stack--infrastructure)
2. [Overall Architecture & OOP Principles](#2-overall-architecture--oop-principles)
3. [Database Schema & Design](#3-database-schema--design)
4. [API Specification](#4-api-specification)
5. [Database Caching Strategy](#5-database-caching-strategy)
6. [Lightweight App Strategy](#6-lightweight-app-strategy)

---

# 1. TECHNOLOGY STACK & INFRASTRUCTURE

## 1.1 Overall Architecture (Hybrid Model)

```
Mobile App (Flutter)
 ├─ Local Cache (SQLite)
 ├─ API Client (HTTPS)
 └─ Payment SDK

Backend (Node.js / Express)
 ├─ Auth & Roles
 ├─ Payment Engine
 ├─ Discount Logic
 ├─ Settlement Engine
 └─ Admin APIs

Database
 ├─ MongoDB Atlas (Cloud – Source of Truth)
 └─ SQLite (Device – UX Cache)

Payments
 └─ Razorpay (Orders, Webhooks, Settlements)
```

---

## 1.2 Frontend (Mobile Application)

### Framework & Language

- **Flutter**
- Language: **Dart**

**Why Flutter:**
- Single codebase (Android / iOS)
- Fast iteration
- Strong QR & payment SDK support
- Excellent state management ecosystem

---

### State Management

- **provider** (MVP-friendly, stable)
- Optional later: Riverpod / Bloc (not Day-1)

---

### Navigation

- `go_router` or `Navigator 2.0`
- Role-based routing (User / Partner / Admin)

---

### Local Storage (Hybrid Cache)

- **SQLite** (critical UX cache)
- Packages:
  - `sqflite`
  - `path_provider`

**Used ONLY for:**
- Recently ordered / stayed merchants
- Home screen recall UX

**❌ Never used for:**
- Payments
- Discounts
- Balances
- Settlements

---

### Networking

- `http` or `dio`
- JSON APIs over HTTPS
- Interceptors for auth tokens

---

### QR & Device Access

- QR Scanner: `mobile_scanner`
- Camera permissions handled natively
- Torch support

---

### Authentication

- Email + Phone OTP
- Backend-driven auth (JWT)
- Secure token storage:
  - `flutter_secure_storage`

---

### Payments (Client Side)

- **Razorpay Flutter SDK**
  - `razorpay_flutter`

**Frontend responsibilities:**
- Open Razorpay checkout
- Handle success/failure callback
- Never calculate discounts

---

### UI Utilities

- `intl` (date & currency formatting)
- `cached_network_image`
- `shimmer` (loading states)

---

## 1.3 Backend (Application Server)

### Runtime & Framework

- **Node.js**
- **Express.js**

**Why Node + Express:**
- Fast development
- Excellent payment gateway support
- Webhook-friendly
- Low infra overhead

---

### API Protocol

- REST (JSON over HTTPS)
- Versioned APIs:
```
/api/v1/...
```

---

### Authentication & Security

- JWT (`jsonwebtoken`)
- Role-based middleware
- OTP verification service
- Password hashing (if used): `bcrypt`

---

### Core Backend Libraries

- `mongoose` – MongoDB ODM
- `dotenv` – Environment variables
- `cors`
- `helmet` – HTTP headers security
- `express-rate-limit`
- `uuid`

---

### Payment Integration

- **Razorpay Node SDK**
  - Order creation
  - Payment verification
  - Webhook handling
  - Optional split settlements

**Backend responsibilities:**
- Create Razorpay orders
- Verify signatures
- Lock order records
- Trigger settlements

---

### Webhooks

- Razorpay webhooks over HTTPS
- Signature verification mandatory
- Idempotent processing

---

## 1.4 Database Stack

### Primary Database (Source of Truth)

- **MongoDB Atlas**
- Free Tier (M0) initially

**Used for:**
- Accounts
- Users
- Merchants
- Orders
- Payments
- Settlements
- Admin logs

**Indexes carefully designed for:**
- user_id
- merchant_id
- created_at
- payment.status

---

### Local Database (Device Cache)

- SQLite (via `sqflite`)
- Stores **derived, non-financial data only**

**Acts as:**
- UX cache
- Offline support
- Performance boost

---

## 1.5 Payment & Settlements

### Payment Gateway

- **Razorpay**

**Capabilities used:**
- Orders API
- Checkout
- Webhooks
- Optional Route (split payouts)

---

### Settlement Modes

1. **Platform-managed settlement**
   - Merchant has no Razorpay account
   - Admin pays merchant weekly / periodic
2. **Direct settlement**
   - Merchant completes Razorpay KYC
   - Auto split settlement

Fallback is automatic.

---

## 1.6 Admin & Operations

### Admin Access

- Same backend APIs
- Role = ADMIN
- Web admin panel OR admin mode in app

---

### Admin Capabilities

- Merchant approval (with / without GST)
- Override settlement mode
- Manual payouts
- Audit logs
- Global order visibility

---

## 1.7 Deployment & Infrastructure

### Backend Hosting

- **Railway**
  OR
- **Render**

**Why:**
- Simple CI/CD
- HTTPS by default
- Webhook-friendly
- Easy env management

---

### Database Hosting

- MongoDB Atlas (Cloud)

---

### Mobile App Distribution

- **Android:**
  - Internal APK (initial)
  - Google Play Store (later)
- **iOS:**
  - TestFlight (later)

---

## 1.8 Version Control & CI/CD

### Source Control

- **Git**
- **GitHub**

---

### Branching Strategy

```
main       → production
develop    → active development
feature/*  → features
hotfix/*   → urgent fixes
```

---

### CI/CD (Optional Early)

- GitHub Actions
- Automated:
  - Backend deploy
  - Tests
  - Build checks

---

## 1.9 Environment Setup

### Environments

- `development`
- `production`

**Each with:**
- Separate DB
- Separate Razorpay keys
- Separate secrets

---

## 1.10 Security & Compliance

### Security Measures

- HTTPS everywhere
- Razorpay signature verification
- Server-side discount calc
- Role-based API guards
- Admin audit logs
- Rate limiting

---

### Privacy

- QR-based default (no phone exchange)
- Phone billing optional & controlled
- Minimal PII storage
- Consent-based flows

---

## 1.11 Observability & Logging

### Logging

- `winston` or `pino`
- Structured logs

### Error Tracking (Optional)

- Sentry (later)

---

## 1.12 What is Intentionally NOT Used (MVP)

❌ Kubernetes  
❌ Microservices  
❌ GraphQL  
❌ Redis  
❌ Kafka  
❌ Custom payment gateway

**This avoids:**
- Overengineering
- Cost spikes
- Operational complexity

---

## 1.13 Final Tech Stack Mental Model

> Flutter for speed
> 
> **SQLite for UX**
> 
> **MongoDB for truth**
> 
> **Node for control**
> 
> **Razorpay for money**
> 
> **GitHub for discipline**
> 
> **Admin for safety**

---

## 1.14 MongoDB Connection

**Connection String:**
```
mongodb+srv://dhyanbhandari200_db_user:Dhyan3016#@tt.bf1lxrd.mongodb.net/?appName=TT
```

**Installation:**
```bash
npm install mongodb
```

---

# 2. OVERALL ARCHITECTURE & OOP PRINCIPLES

## 2.1 Architecture Principles (Lock First)

1. **Feature-first, not layer-first**
2. **One responsibility per file**
3. **No god files**
4. **No premature abstractions**
5. **Context files explain the feature**
6. **Comments explain "WHY", not "WHAT"**
7. **Readable > clever**

---

## 2.2 Flutter App – Modular Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/                     # App-wide shared logic
│   ├── config/
│   │   ├── env.dart
│   │   └── constants.dart
│   │
│   ├── network/
│   │   ├── api_client.dart
│   │   └── api_endpoints.dart
│   │
│   ├── auth/
│   │   ├── auth_provider.dart
│   │   └── auth_guard.dart
│   │
│   ├── storage/
│   │   ├── secure_storage.dart
│   │   └── local_cache.dart
│   │
│   ├── widgets/
│   │   ├── loading_overlay.dart
│   │   ├── error_view.dart
│   │   └── role_switcher.dart
│   │
│   └── utils/
│       ├── formatters.dart
│       └── validators.dart
│
├── features/
│   ├── user/
│   │   ├── user_context.md
│   │   ├── user_home_page.dart
│   │   ├── scan_page.dart
│   │   ├── payment_preview_page.dart
│   │   ├── payment_success_page.dart
│   │   ├── orders_page.dart
│   │   ├── order_detail_page.dart
│   │   └── user_provider.dart
│   │
│   ├── partner/
│   │   ├── partner_context.md
│   │   ├── onboarding/
│   │   │   ├── onboarding_page.dart
│   │   │   └── onboarding_provider.dart
│   │   ├── partner_dashboard_page.dart
│   │   ├── generate_qr_page.dart
│   │   ├── partner_orders_page.dart
│   │   ├── partner_order_detail_page.dart
│   │   ├── analytics_page.dart
│   │   └── partner_provider.dart
│   │
│   ├── admin/
│   │   ├── admin_context.md
│   │   ├── admin_dashboard_page.dart
│   │   ├── merchants_page.dart
│   │   ├── orders_page.dart
│   │   ├── settlements_page.dart
│   │   └── admin_provider.dart
│   │
│   └── auth/
│       ├── login_page.dart
│       └── role_selection_page.dart
│
└── routes/
    ├── app_router.dart
    └── route_guards.dart
```

---

## 2.3 Why This Flutter Structure Works

- **Features are isolated**
- Developers open `/features/user/` and instantly understand scope
- Providers are small and feature-specific
- No cross-feature imports
- Easy lazy loading later
- SQLite + API logic lives in `core/`

---

## 2.4 Required Document Files

Every feature folder has:
```
*_context.md
```

**Example: `features/user/user_context.md`**

```markdown
# User Feature Context

Purpose:
This module contains all screens and logic related to end users
(customer role).

Responsibilities:
- Scan QR and pay
- View discounts and savings
- View order history

Does NOT handle:
- Merchant flows
- Admin actions
- Payment calculations (server-side only)

Key APIs Used:
- GET /user/home/recents
- POST /payment/prepare
- GET /user/orders
```

This **prevents confusion forever**.

---

## 2.5 Backend – Node + Express (Modular & Readable)

```
src/
├── server.js
├── app.js
│
├── config/
│   ├── env.js
│   ├── db.js
│   └── razorpay.js
│
├── core/
│   ├── auth/
│   │   ├── jwt.js
│   │   ├── auth_middleware.js
│   │   └── role_guard.js
│   │
│   ├── errors/
│   │   ├── error_handler.js
│   │   └── api_error.js
│   │
│   ├── utils/
│   │   ├── logger.js
│   │   └── response.js
│
├── modules/
│   ├── auth/
│   │   ├── auth.routes.js
│   │   ├── auth.controller.js
│   │   └── auth.service.js
│   │
│   ├── users/
│   │   ├── users.context.md
│   │   ├── users.routes.js
│   │   ├── users.controller.js
│   │   └── users.service.js
│   │
│   ├── partners/
│   │   ├── partners.context.md
│   │   ├── partners.routes.js
│   │   ├── partners.controller.js
│   │   └── partners.service.js
│   │
│   ├── payments/
│   │   ├── payments.context.md
│   │   ├── payments.routes.js
│   │   ├── payments.controller.js
│   │   ├── payments.service.js
│   │   └── razorpay.webhook.js
│   │
│   ├── orders/
│   │   ├── orders.context.md
│   │   ├── orders.routes.js
│   │   ├── orders.controller.js
│   │   └── orders.service.js
│   │
│   └── admin/
│       ├── admin.context.md
│       ├── admin.routes.js
│       ├── admin.controller.js
│       └── admin.service.js
│
├── models/
│   ├── account.model.js
│   ├── user.model.js
│   ├── merchant.model.js
│   ├── order.model.js
│   ├── settlement.model.js
│   └── admin_log.model.js
│
└── routes/
    └── index.js
```

---

## 2.6 Backend Context File Example

**`modules/payments/payments.context.md`**

```markdown
# Payments Module

Purpose:
Handles order preparation, Razorpay integration,
payment confirmation, and settlement routing.

Responsibilities:
- Calculate discounts (server-side)
- Create Razorpay orders
- Verify webhooks
- Lock orders as PAID
- Decide settlement mode

Never Handles:
- UI decisions
- Merchant onboarding
- Manual settlements (handled by admin module)
```

---

## 2.7 File Size & Responsibility Rules

### Controller
- Only request/response handling
- No business logic
- ≤ 150 lines

### Service
- Business rules
- Discount logic
- DB access
- ≤ 300 lines

### Model
- Schema only
- No logic

### Routes
- Just endpoints
- No inline logic

**If a file grows:** 👉 split it

---

## 2.8 Documentation Standards (Mandatory)

Every file must include a header:

```javascript
/**
 * File: payments.service.js
 * Purpose: Handles payment preparation and discount logic
 * Context: Used by Payment Preview flow before gateway call
 * Author: Platform Backend Team
 */
```

This makes **AI + humans** understand instantly.

---

## 2.9 OOP Design Principles (Mandatory Rules)

These rules apply **everywhere** (frontend + backend):

### Core Rules

1. **Single Responsibility (SRP)** – one class = one job
2. **Dependency Injection over static calls**
3. **No business logic in UI or controllers**
4. **Services never talk to UI**
5. **Models never contain logic**
6. **Reuse via base classes, not copy-paste**
7. **Composition > inheritance (except for base classes)**

---

## 2.10 Flutter – OOP Structure

### Domain-First Thinking

Think in **entities**, not screens:
```
User
Merchant
Order
Payment
Settlement
```

Each entity has:
- Model (data)
- Service (logic)
- Provider (state)

---

### Base API Service

```dart
/// Base class for all API services
/// Handles HTTP, headers, auth & error mapping
abstract class BaseApiService {
  final ApiClient _client;

  BaseApiService(this._client);

  Future<dynamic> get(String path);
  Future<dynamic> post(String path, Map<String, dynamic> body);
}
```

➡ Every feature service **extends this**  
➡ No duplicate networking code anywhere

---

### ApiClient (Single Networking Brain)

```dart
class ApiClient {
  final HttpClient _http;
  final TokenProvider _tokenProvider;

  ApiClient(this._http, this._tokenProvider);

  Future<Response> request(...) async {
    // attach JWT
    // handle timeouts
    // parse JSON
  }
}
```

📌 **Only one file knows how HTTP works**

---

### Feature Services (Business Logic Lives Here)

**Example: PaymentService**

```dart
class PaymentService extends BaseApiService {
  PaymentService(ApiClient client) : super(client);

  Future<PaymentPreview> preparePayment({
    required String merchantId,
    required double billAmount,
  }) async {
    final res = await post('/payment/prepare', {
      'merchant_id': merchantId,
      'bill_amount': billAmount,
    });

    return PaymentPreview.fromJson(res);
  }
}
```

✔ No UI  
✔ No state  
✔ Pure logic + API

---

### Providers = State Only (Not Logic)

```dart
class PaymentProvider extends ChangeNotifier {
  final PaymentService _service;

  PaymentPreview? preview;
  bool loading = false;

  PaymentProvider(this._service);

  Future<void> loadPreview(...) async {
    loading = true;
    notifyListeners();

    preview = await _service.preparePayment(...);

    loading = false;
    notifyListeners();
  }
}
```

📌 Providers:
- call services
- store state
- notify UI

They **do NOT:**
❌ validate business rules  
❌ calculate discounts  
❌ format amounts

---

### UI Layers (Dumb by Design)

```dart
class PaymentPreviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return provider.loading
        ? LoadingView()
        : PaymentView(preview: provider.preview!);
  }
}
```

UI:
- reads state
- shows widgets
- triggers provider methods

That's it.

---

### Flutter OOP Summary

| Layer | Responsibility |
|-------|---------------|
| Model | Data only |
| Service | Business logic |
| Provider | State |
| UI | Rendering |

➡ **Zero duplication**  
➡ **Easy testing**  
➡ **Easy refactoring**

---

## 2.11 Node/Express – OOP Structure

### Layer Responsibilities

```
Route → Controller → Service → Repository → Model
```

❌ No jumping layers  
❌ No logic in controllers

---

### Base Controller (Avoid Duplication)

```javascript
/**
 * BaseController
 * Handles success & error responses
 */
class BaseController {
  success(res, data) {
    return res.json({ success: true, data });
  }

  error(res, err) {
    return res.status(err.status || 500).json({
      error: err.message
    });
  }
}
```

Every controller extends this.

---

### Payment Service (Pure Business Logic)

```javascript
/**
 * PaymentService
 * Handles discount & order logic
 */
class PaymentService {
  constructor(orderRepo, merchantRepo) {
    this.orderRepo = orderRepo;
    this.merchantRepo = merchantRepo;
  }

  async preparePayment({ merchantId, billAmount, userId }) {
    const merchant = await this.merchantRepo.findById(merchantId);

    const discount = this.calculateDiscount(
      billAmount,
      merchant.discount_percent
    );

    return {
      gross: billAmount,
      discount,
      net: billAmount - discount
    };
  }

  calculateDiscount(bill, percent) {
    return +(bill * percent / 100).toFixed(2);
  }
}
```

✔ No Express  
✔ No req/res  
✔ Testable  
✔ Reusable

---

### Controllers – Translators Only

```javascript
class PaymentController extends BaseController {
  constructor(paymentService) {
    super();
    this.paymentService = paymentService;
  }

  async prepare(req, res) {
    try {
      const data = await this.paymentService.preparePayment({
        merchantId: req.body.merchant_id,
        billAmount: req.body.bill_amount,
        userId: req.user.id
      });
      this.success(res, data);
    } catch (err) {
      this.error(res, err);
    }
  }
}
```

📌 Controllers:
- map HTTP → service calls
- return responses
- no logic

---

### Repository Pattern (Optional but Clean)

```javascript
class OrderRepository {
  async create(data) {
    return OrderModel.create(data);
  }

  async findByUser(userId) {
    return OrderModel.find({ user_id: userId });
  }
}
```

This avoids:
❌ mongoose calls spread everywhere

---

### Webhooks – Separate Class

```javascript
class RazorpayWebhookHandler {
  verifySignature(payload, signature) {}

  async handlePaymentCaptured(event) {}
}
```

Never mix webhook logic with REST APIs.

---

## 2.12 Duplication Elimination Checklist

| Problem | OOP Solution |
|---------|-------------|
| Repeating API calls | BaseApiService |
| Repeating HTTP logic | ApiClient |
| Repeating responses | BaseController |
| Business rule duplication | Services |
| DB clutter | Repository |
| UI clutter | Dumb widgets |

---

## 2.13 Final Golden Rule

> If the same logic is written twice,
> the design is wrong.

OOP exists **to make duplication impossible**, not just "clean code".

---

## 2.14 Final Mental Model

> Folders represent features
> Files represent responsibilities
> Context files explain intent
> No file knows too much

---

# 3. DATABASE SCHEMA & DESIGN

## 3.1 Database Name

```
travellers_triibe
```

---

## 3.2 Accounts Collection (Auth Identity)

> Single identity for User / Partner / Admin

### `accounts`

```javascript
{
  _id: ObjectId,

  email: String, // unique, indexed
  phone: String, // unique, indexed
  phone_verified: Boolean,
  email_verified: Boolean,

  roles: ["USER", "PARTNER", "ADMIN"], // multi-role support

  status: "ACTIVE" | "BLOCKED",

  created_at: Date,
  last_login_at: Date
}
```

### Indexes

```javascript
email (unique)
phone (unique)
roles
```

---

## 3.3 Merchants Collection (Business Entity)

> Created only when user becomes PARTNER

### `merchants`

```javascript
{
  _id: ObjectId, // merchant_id
  account_id: ObjectId, // ref → accounts._id

  business_name: String,
  category: "FOOD" | "STAY" | "SERVICE" | "RETAIL",

  address: {
    line1: String,
    city: String,
    state: String,
    pincode: String
  },

  gst: {
    gstin: String,
    verified: Boolean,
    legal_name: String
  },

  discount_percent: 3 | 6 | 9,
  platform_fee_percent: Number, // read-only for merchant

  settlement: {
    mode: "PLATFORM" | "DIRECT",
    razorpay_account_id: String, // null if PLATFORM
    kyc_status: "NOT_STARTED" | "PENDING" | "VERIFIED"
  },

  payout_cycle: "WEEKLY" | "BIWEEKLY",

  stats: {
    total_orders: Number,
    total_discount_given: Number,
    total_net_earned: Number
  },

  status: "ACTIVE" | "SUSPENDED",

  created_at: Date
}
```

### Indexes

```javascript
account_id
category
settlement.mode
status
```

---

## 3.4 Users Collection (Optional Profile Data)

> Only stores non-auth user data

### `users`

```javascript
{
  _id: ObjectId,
  account_id: ObjectId, // ref → accounts

  name: String,
  gender: String,
  dob: Date,

  savings: {
    today: Number,
    month: Number,
    lifetime: Number
  },

  created_at: Date
}
```

---

## 3.5 Orders Collection (Core Business Object)

> This is the MOST IMPORTANT collection

### `orders`

```javascript
{
  _id: ObjectId, // order_id

  user_id: ObjectId, // ref → users
  account_id: ObjectId, // direct ref → accounts
  merchant_id: ObjectId, // ref → merchants

  order_type: "FOOD" | "STAY" | "SERVICE" | "RETAIL",

  amounts: {
    gross_bill: Number,
    discount_amount: Number,
    platform_fee: Number,
    net_paid: Number,
    merchant_receivable: Number
  },

  discount_percent: Number,

  payment: {
    razorpay_order_id: String,
    razorpay_payment_id: String,
    method: "UPI" | "CARD" | "WALLET",
    status: "CREATED" | "PAID" | "FAILED"
  },

  settlement: {
    mode_used: "PLATFORM" | "DIRECT",
    settled: Boolean,
    settlement_id: ObjectId // ref → settlements
  },

  created_at: Date,
  paid_at: Date
}
```

### Indexes

```javascript
merchant_id
account_id
user_id
created_at
payment.status
```

---

## 3.6 Payments Collection (Gateway Events)

> For webhook traceability & audits

### `payments`

```javascript
{
  _id: ObjectId,

  order_id: ObjectId, // ref → orders
  razorpay_order_id: String,
  razorpay_payment_id: String,

  event: "payment.created" | "payment.captured" | "payment.failed",
  payload: Object,

  verified: Boolean,

  created_at: Date
}
```

---

## 3.7 Settlements Collection (Admin Payouts)

> Used only for PLATFORM mode

### `settlements`

```javascript
{
  _id: ObjectId,

  merchant_id: ObjectId,
  period_start: Date,
  period_end: Date,

  total_orders: Number,
  total_amount: Number,

  payout: {
    amount: Number,
    method: "BANK" | "UPI",
    reference_id: String,
    paid_at: Date
  },

  status: "PENDING" | "PAID",

  admin_id: ObjectId, // ref → accounts (admin)

  created_at: Date
}
```

### Indexes

```javascript
merchant_id
status
period_start
```

---

## 3.8 Admin Action Logs (Audit Trail)

> Mandatory for control & compliance

### `admin_logs`

```javascript
{
  _id: ObjectId,

  admin_id: ObjectId,

  action: String, // e.g. "SETTLEMENT_PAID"
  target_type: "MERCHANT" | "ORDER" | "USER",
  target_id: ObjectId,

  metadata: Object,

  created_at: Date
}
```

---

## 3.9 QR / Bill Requests (Temporary)

> Short-lived documents

### `bill_requests`

```javascript
{
  _id: ObjectId,

  merchant_id: ObjectId,
  order_id: ObjectId,

  expires_at: Date,
  status: "ACTIVE" | "EXPIRED" | "USED",

  created_at: Date
}
```

### TTL Index

```javascript
expires_at (TTL)
```

---

## 3.10 Relationship Summary

```
Account
 ├── User (optional)
 ├── Merchant (optional)
 └── Admin (role)

Merchant
 ├── Orders
 └── Settlements

Order
 ├── Payment
 └── Settlement (optional)
```

---

## 3.11 Why This Schema Works

### ✅ MongoDB-friendly
- Read-optimized
- Minimal joins
- Indexed properly

### ✅ Payments-safe
- Immutable orders
- Separate payment events
- Clear settlement tracking

### ✅ Admin-operable
- Full control
- Manual settlement support
- Auditability

### ✅ Free-tier friendly
- Limited collections
- Controlled document growth
- TTL cleanup

---

## 3.12 Intentional Non-Designs

- ❌ No wallet balance mutation per txn
- ❌ No item-level order storage
- ❌ No embedded settlements inside orders
- ❌ No mixed auth + profile data

---

## 3.13 Final DB Mental Model

> Accounts identify people
> 
> **Merchants represent businesses**
> 
> **Orders represent reality**
> 
> **Payments prove money moved**
> 
> **Settlements close the loop**
> 
> **Admin logs ensure trust**

---

# 4. API SPECIFICATION

## 4.1 Global API Rules

### Base URL

```
/api/v1
```

### Auth

- JWT-based auth
- Token issued after login
- Token contains:

```json
{
  "account_id": "ObjectId",
  "roles": ["USER", "PARTNER", "ADMIN"]
}
```

### Headers (All Protected APIs)

```
Authorization: Bearer <JWT>
Content-Type: application/json
```

### Role Enforcement

- USER → user routes
- PARTNER → partner routes
- ADMIN → admin routes
- One account can have multiple roles

---

## 4.2 Auth & Account

### 1️⃣ Login

**`POST /auth/login`**

**Input**

```json
{
  "email": "user@mail.com",
  "phone": "+919876543210",
  "otp": "123456"
}
```

**Output**

```json
{
  "token": "JWT_TOKEN",
  "account": {
    "account_id": "acc_123",
    "roles": ["USER"]
  }
}
```

---

### 2️⃣ Get My Account

**`GET /auth/me`**

**Output**

```json
{
  "account_id": "acc_123",
  "email": "user@mail.com",
  "phone": "+919876543210",
  "roles": ["USER", "PARTNER"]
}
```

---

## 4.3 User APIs

### 3️⃣ User Home – Recents

**`GET /user/home/recents`**

**Logic:**
- Derived from `orders`
- Group by merchant
- Sorted by last order

**Output**

```json
{
  "recents": [
    {
      "merchant_id": "m_101",
      "merchant_name": "Cafe Aroma",
      "category": "FOOD",
      "last_order_at": "2025-01-12T10:22:00Z"
    }
  ]
}
```

---

### 4️⃣ User Savings Summary

**`GET /user/savings/summary`**

**Output**

```json
{
  "today": 32.4,
  "month": 486.0,
  "lifetime": 3240.5
}
```

---

### 5️⃣ User Orders (History)

**`GET /user/orders`**

**Query Params**

```
?type=FOOD|STAY|SERVICE|RETAIL
&page=1&limit=20
```

**Output**

```json
{
  "orders": [
    {
      "order_id": "ord_001",
      "merchant_name": "Cafe Aroma",
      "category": "FOOD",
      "net_paid": 508,
      "discount": 32.4,
      "status": "PAID",
      "created_at": "2025-01-12T10:22:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "has_more": false
  }
}
```

---

### 6️⃣ User Order Detail

**`GET /orders/{order_id}`**

**Output**

```json
{
  "order_id": "ord_001",
  "merchant": {
    "name": "Cafe Aroma",
    "category": "FOOD",
    "gst_verified": true
  },
  "amounts": {
    "gross": 540,
    "discount": 32.4,
    "paid": 508
  },
  "payment": {
    "method": "UPI",
    "status": "PAID"
  },
  "created_at": "2025-01-12T10:22:00Z"
}
```

---

### 7️⃣ User Profile

**`GET /user/profile`**

```json
{
  "name": "Surya",
  "email": "user@mail.com",
  "phone": "+919876543210",
  "gender": null,
  "dob": null
}
```

**`PUT /user/profile`**

```json
{
  "name": "Surya",
  "gender": "MALE",
  "dob": "1998-06-01"
}
```

---

## 4.4 Payment APIs (Core)

### 8️⃣ Validate QR

**`POST /qr/validate`**

**Input**

```json
{
  "qr_token": "QR_ENCODED_STRING"
}
```

**Output**

```json
{
  "merchant_id": "m_101",
  "bill_amount": 540,
  "expires_at": "2025-01-12T10:25:00Z"
}
```

---

### 9️⃣ Prepare Payment (CRITICAL)

**`POST /payment/prepare`**

**Input**

```json
{
  "merchant_id": "m_101",
  "bill_amount": 540
}
```

**Output**

```json
{
  "order_id": "ord_001",
  "merchant": {
    "name": "Cafe Aroma",
    "category": "FOOD"
  },
  "amounts": {
    "gross": 540,
    "discount_percent": 6,
    "discount": 32.4,
    "net_payable": 508
  },
  "razorpay": {
    "order_id": "rzp_order_123",
    "amount": 50800,
    "currency": "INR"
  }
}
```

---

### 🔒 Razorpay Webhook (Backend only)

**`POST /webhooks/razorpay`**

- Verifies signature
- Updates payment status
- Locks order

No client response.

---

## 4.5 Partner (Merchant) APIs

### 🔟 Partner Onboarding – Business

**`POST /partner/onboarding/business`**

```json
{
  "business_name": "Cafe Aroma",
  "category": "FOOD",
  "address": {
    "city": "Bangalore",
    "state": "KA",
    "pincode": "560001"
  }
}
```

---

### 1️⃣1️⃣ Partner Onboarding – GST

**`POST /partner/onboarding/gst`**

```json
{
  "gstin": "29ABCDE1234F1Z5"
}
```

---

### 1️⃣2️⃣ Partner Onboarding – Commercials

**`POST /partner/onboarding/commercials`**

```json
{
  "discount_percent": 6,
  "settlement_mode": "PLATFORM"
}
```

---

### 1️⃣3️⃣ Partner Dashboard

**`GET /partner/dashboard`**

```json
{
  "today_orders": 12,
  "today_revenue": 6200,
  "discount_given": 420,
  "pending_settlement": 15800
}
```

---

### 1️⃣4️⃣ Create Bill / QR

**`POST /partner/bill/create`**

```json
{
  "bill_amount": 540
}
```

**Output**

```json
{
  "qr_token": "QR_ENCODED_STRING",
  "expires_at": "2025-01-12T10:25:00Z"
}
```

---

### 1️⃣5️⃣ Partner Orders

**`GET /partner/orders`**

```json
{
  "orders": [
    {
      "order_id": "ord_001",
      "user": "U****210",
      "bill": 540,
      "discount": 32.4,
      "net_receivable": 507,
      "status": "PAID"
    }
  ]
}
```

---

### 1️⃣6️⃣ Partner Analytics

**`GET /partner/analytics`**

```json
{
  "total_orders": 120,
  "discount_invested": 4200,
  "net_earned": 62400,
  "repeat_users": 36
}
```

---

## 4.6 Admin APIs

### 1️⃣7️⃣ Admin Dashboard

**`GET /admin/dashboard`**

```json
{
  "gmv": 1240000,
  "total_orders": 8420,
  "active_merchants": 210,
  "pending_settlements": 42
}
```

---

### 1️⃣8️⃣ Admin Merchants

**`GET /admin/merchants`**

```json
{
  "merchants": [
    {
      "merchant_id": "m_101",
      "name": "Cafe Aroma",
      "category": "FOOD",
      "gst_verified": true,
      "settlement_mode": "PLATFORM",
      "status": "ACTIVE"
    }
  ]
}
```

---

### 1️⃣9️⃣ Admin Update Merchant

**`PUT /admin/merchants/{merchant_id}`**

```json
{
  "status": "ACTIVE",
  "force_settlement_mode": "PLATFORM"
}
```

---

### 2️⃣0️⃣ Admin Orders (Global Ledger)

**`GET /admin/orders`**

**Filters:**

```
?merchant_id=&user_id=&type=&date_from=&date_to=
```

---

### 2️⃣1️⃣ Admin Settlements

**Create Settlement**

`POST /admin/settlements/create`

```json
{
  "merchant_id": "m_101",
  "period_start": "2025-01-01",
  "period_end": "2025-01-07"
}
```

**List Settlements**

`GET /admin/settlements`

---

### 2️⃣2️⃣ Admin Users

**`GET /admin/users`**

```json
{
  "users": [
    {
      "user_id": "u_001",
      "phone": "+91****3210",
      "orders": 12,
      "savings": 486
    }
  ]
}
```

---

## 4.7 Error Format (Global)

```json
{
  "error": {
    "code": "INVALID_QR",
    "message": "QR code has expired"
  }
}
```

---

## 4.8 Final API Mental Model

- **Auth identifies people**
- **Roles gate access**
- **Orders are immutable**
- **Payments are event-driven**
- **Admin controls settlements**
- **Discount logic is server-only**

---

# 5. DATABASE CACHING STRATEGY

## 5.1 What We Are Optimizing

We are **NOT** optimizing:
- Payments
- Settlements
- Balances
- Discounts

We are optimizing only:
- **Home page recall UX**
- "Previously ordered / stayed"
- Faster app open

This is **non-critical UX data**, not financial data.

---

## 5.2 Three Layers of Data

You must mentally separate data into **3 layers**:

```
Layer 1: Database (Truth)
Layer 2: API Response (Derived)
Layer 3: Device Cache (UX Speed)
```

Only **Layer 1** is authoritative.

---

## 5.3 What Should Be Stored Where

### ✅ DATABASE (MongoDB)

**Store only events:**
- Orders
- Payments
- Merchants

**❌ Never store:**
- "Recent merchants"
- "Previously ordered list"

---

### ✅ BACKEND (API – Derived)

Backend **derives:**

```
Recent merchants
Grouped by order_type
Sorted by last_order_at
Limited to N
```

This is computed **from orders**.

---

### ✅ FRONTEND (LOCAL CACHE – SQLite)

**YES – use SQLite**, but with strict rules.

SQLite stores:
- Last fetched **recent list**
- Merchant summary info only

Example table:

```sql
recent_merchants (
  merchant_id TEXT PRIMARY KEY,
  merchant_name TEXT,
  category TEXT,
  last_order_at INTEGER,
  last_synced_at INTEGER
)
```

---

## 5.4 When to Use Cache vs API

### 🟢 USE CACHE WHEN:
- App opens
- User lands on Home
- Network is slow
- App restarted

### 🔄 REFRESH FROM API WHEN:
- App comes to foreground
- New order completed
- Cache is older than X minutes
- User pulls to refresh

---

## 5.5 Cache Invalidation Rules (Critical)

> Caching is easy. Invalidation is the hard part.

### Rule 1 – TTL (Time To Live)

```
Cache expires after 15–30 minutes
```

Never keep it indefinitely.

---

### Rule 2 – Post-Payment Invalidation

After **successful payment:**

```
→ Invalidate recent cache
→ Refresh from server
→ Update SQLite
```

This guarantees correctness.

---

### Rule 3 – Logout / Account Switch

On logout:

```
Clear SQLite cache
```

No exceptions.

---

## 5.6 Why SQLite (Not SharedPreferences)

| Option | Why / Why Not |
|--------|---------------|
| SharedPreferences | ❌ Too weak, no queries |
| In-memory | ❌ Lost on restart |
| SQLite | ✅ Structured, fast, persistent |
| Realm / Isar | ⚠️ Overkill for MVP |

SQLite is **perfect** here.

---

## 5.7 What Must Never Be Cached Locally

❌ Do NOT store:
- Wallet balances
- Payment status
- Settlement amounts
- Discounts
- Razorpay IDs

Those **must always come from backend**.

---

## 5.8 Offline Mode UX (Bonus Benefit)

With SQLite cache:
- Home page still looks alive offline
- User sees familiar merchants
- Clear "Offline" indicator shown

Once network returns:
- Silent refresh
- Cache updated

This gives **premium UX** without risk.

---

## 5.9 Final Flow (End-to-End)

### App Launch

```
1. Load recent merchants from SQLite
2. Render UI instantly
3. Call /user/home/recents API
4. If data differs → update SQLite & UI
```

### After Payment

```
1. Payment success
2. Invalidate SQLite cache
3. Fetch fresh data
4. Update SQLite
```

---

## 5.10 Why This Is the Correct Decision

This approach gives:
- ⚡ Fast UI
- 🧠 Correct data
- 🔒 No financial risk
- 📱 Offline support
- 🚀 Scales cleanly

This is exactly how Paytm, PhonePe, Uber, Zomato handle "recent" UX data.

---

## 5.11 Final Mental Model

> Events live on the server.
> Interpretations are derived.
> UI shortcuts are cached.
> Money is never cached.

If you remember only this, you won't make mistakes later.

---

# 6. LIGHTWEIGHT APP STRATEGY

## 6.1 What "Lightweight" Means

Lightweight ≠ fewer features

Lightweight = **low friction at every layer**

### Targets (Realistic & Achievable)

- 📦 **APK size**: ≤ 25–30 MB (Android)
- 🚀 **Cold start time**: < 2 sec on low-end devices
- 🧠 **Memory usage**: Minimal background footprint
- 📡 **Network usage**: Only essential calls
- 🔋 **Battery impact**: Low (no polling, no background jobs)

---

## 6.2 Frontend (Flutter) – Keep It Lean

### Use Flutter Wisely (NOT blindly)

**What to DO:**
- Use **Material widgets only**
- Prefer **StatelessWidget** wherever possible
- Lazy-load screens (no eager initialization)
- Use simple layouts (Column / Row / ListView)

**What to AVOID:**
❌ Heavy animations  
❌ Large icon packs  
❌ Custom fonts beyond logo  
❌ Over-nesting widgets

> Payments apps should feel instant, not fancy.

---

## 6.3 Dependency Hygiene (Critical)

### ✅ ONLY include essential packages

**KEEP:**
- `provider`
- `http` or `dio`
- `mobile_scanner`
- `razorpay_flutter`
- `sqflite`
- `flutter_secure_storage`

**AVOID:**
- All-in-one UI kits
- State managers you don't need
- Analytics SDKs on Day-1
- Background job libraries

📌 **Rule:**
> If a package saves <50 lines of code but adds MBs → don't use it.

---

## 6.4 SQLite – Store Little, Query Fast

### What SQLite is used for
- Recent merchants only
- Small tables
- Indexed by primary keys

### What SQLite is NOT used for
❌ Orders  
❌ Payments  
❌ Settlements

This keeps:
- DB size tiny
- I/O fast
- No schema migration pain

---

## 6.5 API Strategy – Fewer Calls, Smart Calls

### Principles
- No polling
- No background refresh loops
- Fetch data **on demand**

### Smart API patterns
- Combine related data into one response
- Use pagination
- Cache recents locally
- Invalidate cache only on payment success

> One successful payment = one cache refresh.

---

## 6.6 Images & Assets – Extreme Discipline

### Rules
- Logo: SVG or single PNG
- Icons: Material icons only
- No hero images
- No large illustrations
- No Lottie files (yet)

> Payments don't need decoration — clarity beats beauty.

---

## 6.7 Build Optimizations (Android)

### Must-do release flags

```bash
flutter build apk --release --split-per-abi
```

### Result
- Smaller APK per device
- Faster installs
- Less RAM usage

Also:
- Enable tree-shaking for icons
- Remove debug logs in release

---

## 6.8 Backend – Keep Responses Small

### Response hygiene
- No unused fields
- No nested junk objects
- No verbose metadata

**Example:**

```json
{
  "merchant": {"id": "x", "name": "Cafe Aroma"},
  "amounts": {"payable": 508}
}
```

**Not:**

```json
{
  "merchant": {"id": "x", "name": "...", "created_at": "...", ...},
  "metadata": { ...}
}
```

Smaller payload = faster app.

---

## 6.9 Razorpay – Use Only Required Features

### Use
- Orders API
- Checkout
- Webhooks

### Do NOT use
❌ Subscriptions  
❌ Auto-debits  
❌ Heavy analytics

The gateway is **a tool**, not a platform inside your app.

---

## 6.10 Background Processes – None by Default

### Avoid
- Background services
- Periodic syncs
- Push notification listeners (Day-1)

### Allow later
- Payment notifications only
- Opt-in merchant alerts

This protects:
- Battery
- OS restrictions
- App reputation

---

## 6.11 Admin Features – Separate Mentally

Admin-heavy screens:
- Load only when role = ADMIN
- Not bundled into user initial route
- Lazy-load admin modules

This keeps **user app fast**.

---

## 6.12 Error & Edge Handling

- Short error messages
- No modal explosions
- No retry storms

**Example:**
> "QR expired. Ask merchant to regenerate."

Simple. Honest. Fast.

---

## 6.13 Monitor App Size Continuously

### Practices
- Check APK size every release
- Track dependency growth
- Avoid "quick fixes" that add SDKs

📌 **Once bloat enters, it never leaves easily.**

---

## 6.14 Final Lightweight Mental Model

> Only load what the user needs,
> only when the user needs it,
> and never twice.

If a feature:
- doesn't speed payment
- doesn't increase trust

→ it doesn't belong in MVP.

---

## 6.15 Execution Checklist

- [ ] Minimal dependencies
- [ ] SQLite only for UX cache
- [ ] No background jobs
- [ ] Small API payloads
- [ ] Lazy-loaded screens
- [ ] Split APK builds
- [ ] No analytics SDK Day-1

---

# DOCUMENT END

**Version:** 1.0  
**Last Updated:** December 2024  
**Status:** Final Technical Specification
