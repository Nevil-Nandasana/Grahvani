/// Paywall Sheet — Premium upgrade bottom sheet
/// Integrates with in_app_purchase for Google Play / App Store purchases.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/subscription_repository.dart';
import '../domain/subscription_provider.dart';
import 'trial_banner.dart';

// ─── IAP Product IDs ──────────────────────────────────────────────────────────
const _kMonthlyId = 'grahvani_premium_monthly';
const _kYearlyId  = 'grahvani_premium_yearly';

// ─── IAP Products Provider ────────────────────────────────────────────────────
final _iapProductsProvider =
    FutureProvider<List<ProductDetails>>((ref) async {
  if (kIsWeb) return [];
  final iap = InAppPurchase.instance;
  final bool available = await iap.isAvailable();
  if (!available) return [];

  final response = await iap.queryProductDetails(
      {_kMonthlyId, _kYearlyId});
  return response.productDetails;
});

class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallSheet(),
    );
  }

  /// Initiates an in-app purchase for the given product ID.
  /// Falls back to a SnackBar if the store is unavailable (e.g. emulator).
  Future<void> _purchase(
      BuildContext context, WidgetRef ref, String productId) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web subscriptions use Razorpay checkout.'),
            backgroundColor: Color(0xFF3B2FBE),
          ),
        );
      }
      return;
    }
    final iap = InAppPurchase.instance;
    final bool available = await iap.isAvailable();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store not available. Check your connection.'),
            backgroundColor: Color(0xFF3B2FBE),
          ),
        );
      }
      return;
    }

    final productsAsync = ref.read(_iapProductsProvider);
    final products = productsAsync.valueOrNull ?? [];
    final product = products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      // Product not found in store catalogue — log and show message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product $productId not found. '
                'Ensure it is configured in the developer console.'),
            backgroundColor: const Color(0xFF3B2FBE),
          ),
        );
      }
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      await iap.buyNonConsumable(purchaseParam: purchaseParam);
      // Purchase result arrives via _purchaseProvider stream (listen in main.dart or here).
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementsAsync = ref.watch(entitlementsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16103A), Color(0xFF0A0A1A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3266),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            const Center(
              child: Text('✨', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Unlock Grahvani Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Full access to Vedic AI interpretation\ngrounded in classical Shastra texts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9B93CC), fontSize: 13, height: 1.5),
              ),
            ),

            const SizedBox(height: 28),

            // Comparison table
            _ComparisonTable(),

            const SizedBox(height: 28),

            // Trial Banner
            const TrialBanner(),

            const SizedBox(height: 16),

            // Price cards
            _PriceCard(
              label: 'Monthly',
              price: '₹299',
              period: '/month',
              isPopular: false,
              onTap: () => _purchase(context, ref, _kMonthlyId),
            ),
            const SizedBox(height: 12),
            _PriceCard(
              label: 'Yearly',
              price: '₹1,999',
              period: '/year',
              savings: 'Save ₹1,589',
              isPopular: true,
              onTap: () => _purchase(context, ref, _kYearlyId),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Cancel anytime. No hidden fees.\nAutomatic renewal. DPDP Act 2023 compliant.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4A4A6A), fontSize: 11, height: 1.5),
              ),
            ),

            // Current entitlement status
            const SizedBox(height: 20),
            entitlementsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (e) => _QuotaStatus(entitlements: e),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Daily AI interpretations', '3', '100'),
      ('North Indian Chart', '✓', '✓'),
      ('Vimshottari Dasha timeline', '✓', '✓'),
      ('Classical text citations', '✓', '✓'),
      ('Multiple birth profiles', '✗', 'Up to 10'),
      ('Priority AI responses', '✗', '✓'),
      ('Export chart as PDF', '✗', '✓'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A35),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Feature',
                      style: TextStyle(color: Color(0xFF6B6B99), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Center(
                    child: Text('Free',
                        style: TextStyle(color: Color(0xFF6B6B99), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('Premium',
                        style: TextStyle(color: Color(0xFF7C6EFA), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          ...rows.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E1E3A))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(row.$1,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$2,
                          style: TextStyle(
                            color: row.$2 == '✗'
                                ? const Color(0xFF4A4A6A)
                                : const Color(0xFF6B6B99),
                            fontSize: 13,
                          )),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(row.$3,
                          style: const TextStyle(
                            color: Color(0xFF7C6EFA),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
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
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.label,
    required this.price,
    required this.period,
    required this.isPopular,
    required this.onTap,
    this.savings,
  });

  final String label;
  final String price;
  final String period;
  final bool isPopular;
  final VoidCallback onTap;
  final String? savings;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(
                  colors: [Color(0xFF3B2FBE), Color(0xFF5B4FDB)],
                )
              : null,
          color: isPopular ? null : const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? const Color(0xFF7C6EFA)
                : const Color(0xFF2A2A4A),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: const Color(0xFF5B4FDB).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BEST VALUE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(savings!,
                          style: const TextStyle(
                              color: Color(0xFF64FF8A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(period,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaStatus extends StatelessWidget {
  const _QuotaStatus({required this.entitlements});
  final Entitlements entitlements;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF7C6EFA), size: 18),
          const SizedBox(width: 10),
          Text(
            'Today: ${entitlements.queriesRemaining}/${entitlements.dailyQueriesLimit} queries remaining  •  ${entitlements.tier.toUpperCase()}',
            style: const TextStyle(color: Color(0xFF9B93CC), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
