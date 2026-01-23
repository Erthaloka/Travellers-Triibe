import 'package:flutter/material.dart';
import 'package:travellers_triibe/routes/app_router.dart';

import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

// Color constants from your palette image

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'How to use Travellers Triibe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // This is the clean way to go back to the previous screen (Profile)
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.userProfile);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Welcome to the Triibe"),
            const SizedBox(height: 10),
            const Text(
              "Travellers Triibe is a single app designed for Users, Partners, and Admins. Your role determines what you see.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Divider(height: 40, color: AppColors.textSecondary),

            _buildRoleSection(
              title: "For Users (Travellers)",
              color: AppColors.textHint,
              icon: Icons.person,
              steps: [
                "Tap 'Scan & Pay' on your Home screen to start a payment.",
                "Review your payment details on the 'Payment Preview' screen[cite: 69].",
                "Complete the payment using Razorpay[cite: 76].",
                "View your transaction history in the 'Orders' section[cite: 85].",
              ],
            ),

            _buildRoleSection(
              title: "For Partners (Merchants)",
              color: AppColors.primary,
              icon: Icons.storefront,
              steps: [
                "Use your Dashboard to 'Generate Bill'[cite: 112].",
                "Enter the amount to create a unique QR code for customers[cite: 118, 119].",
                "Wait for the 'Payment Success' screen to appear automatically[cite: 121].",
                "Track your business growth in the 'Analytics' tab[cite: 131].",
              ],
            ),

            _buildRoleSection(
              title: "Switching Roles",
              color: AppColors.warning,
              icon: Icons.swap_horiz,
              steps: [
                "Go to your 'Profile'[cite: 181].",
                "Tap 'Switch Role' to move between User and Partner modes[cite: 182].",
                "Your navigation stack will reset to keep things simple[cite: 188].",
              ],
            ),

            const SizedBox(height: 30),
            const Center(
              child: Text(
                "Version 1.0.0 • Offline mode supported [cite: 220]",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRoleSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> steps,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(step, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
