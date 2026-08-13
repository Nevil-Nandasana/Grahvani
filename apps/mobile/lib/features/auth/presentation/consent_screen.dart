import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grahvani/router/app_router.dart';
import 'package:grahvani/features/auth/data/auth_repository.dart';
import 'package:grahvani/features/auth/domain/auth_state.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isConsentGiven = false;
  bool _isSubmitting = false;

  Future<void> _handleAccept() async {
    if (!_isConsentGiven) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // We read the repository provider directly to call grantConsent
      await ref.read(authRepositoryProvider).grantConsent();
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record consent: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A4A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF7C6EFA),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Data Privacy & Consent',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To provide accurate Vedic astrology interpretations, we need to collect and process specific personal data in accordance with the Digital Personal Data Protection (DPDP) Act, 2023.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9B93CC),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Data Collection Details
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12122A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A4A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataPoint(
                          icon: Icons.calendar_month,
                          title: 'Birth Details',
                          description: 'Date and exact time of birth.',
                        ),
                        const SizedBox(height: 16),
                        _buildDataPoint(
                          icon: Icons.location_on_outlined,
                          title: 'Birth Location',
                          description: 'City, state, and geographic coordinates.',
                        ),
                        const SizedBox(height: 16),
                        _buildDataPoint(
                          icon: Icons.person_outline,
                          title: 'Identity Data',
                          description: 'Name and contact information.',
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFF2A2A4A)),
                        const SizedBox(height: 20),
                        Text(
                          'Why we need this:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This data is strictly necessary to calculate planetary positions and generate your personalized astrological chart. We do not sell your personal data.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9B93CC),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Consent Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isConsentGiven 
                      ? const Color(0xFF3B2FBE).withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isConsentGiven 
                        ? const Color(0xFF7C6EFA)
                        : const Color(0xFF2A2A4A),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'I have read and agree to the ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: Color(0xFF7C6EFA),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://grahvani.com/terms'),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xFF7C6EFA),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://grahvani.com/privacy'),
                            ),
                            const TextSpan(
                              text: '. I explicitly consent to the processing of my personal data as described.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      key: const Key('consent_switch'),
                      value: _isConsentGiven,
                      onChanged: (value) {
                        setState(() {
                          _isConsentGiven = value;
                        });
                      },
                      activeColor: const Color(0xFF7C6EFA),
                      activeTrackColor: const Color(0xFF3B2FBE),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isConsentGiven && !_isSubmitting ? _handleAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6EFA),
                    disabledBackgroundColor: const Color(0xFF2A2A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'I Agree & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isConsentGiven ? Colors.white : Colors.white54,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    // Allows withdrawal before consent
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                  child: const Text(
                    'Cancel & Delete Account',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7C6EFA), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF9B93CC),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
