# Auth Feature Context

## Purpose
Handles user authentication, OTP verification, and role management.

## Responsibilities
- Login with email + phone + OTP
- OTP sending and verification
- Session management (JWT tokens)
- Role selection for first-time users
- Demo mode for testing (OTP: 123456)

## Does NOT Handle
- User profile editing (handled in user feature)
- Partner onboarding (handled in partner feature)
- Admin actions

## Key Files
- `models/account.dart` - Account data model
- `auth_service.dart` - API calls for authentication
- `login_page.dart` - Login UI with email/phone/OTP
- `role_selection_page.dart` - First-time role selection

## Key APIs Used
- POST /auth/login
- POST /auth/send-otp
- GET /auth/me

## Demo Mode
For testing without backend:
- Use any email and phone number
- OTP: 123456
- Creates demo account with USER role

## Flow
```
App Launch
  → Check token
    → Valid: Go to home based on role
    → Invalid: Show login
      → Enter email + phone
      → Send OTP
      → Enter OTP
      → Verify & Login
        → First time: Role selection
        → Returning: Go to home
```
