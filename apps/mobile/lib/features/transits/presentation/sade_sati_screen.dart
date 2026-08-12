/// Sade Sati Screen — Displays the user's current 7.5-year Saturn transit status
/// Shows phase timeline, remedies, and transit details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/transit_repository.dart';

class SadeSatiScreen extends ConsumerWidget {
  const SadeSatiScreen({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(sadeSatiStatusProvider(profileId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Sade Sati Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7C6EFA)),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(sadeSatiStatusProvider(profileId)),
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(
          error: e.toString(),
          onRetry: () => ref.refresh(sadeSatiStatusProvider(profileId)),
        ),
        data: (status) => _SadeSatiContent(status: status),
      ),
    );
  }
}

class _SadeSatiContent extends StatelessWidget {
  const _SadeSatiContent({required this.status});
  final SadeSatiStatus status;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phase indicator
          _buildPhaseIndicator(context),
          const SizedBox(height: 24),
          
          // Timeline
          _buildTimeline(context),
          const SizedBox(height: 24),
          
          // Current status
          _buildCurrentStatus(context),
          const SizedBox(height: 24),
          
          // Remedies
          _buildRemedies(context),
          const SizedBox(height: 24),
          
          // Transit details
          _buildTransitDetails(context),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(BuildContext context) {
    final phase = status.phase ?? 'none';
    final isActive = status.isSadeSati;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _getPhaseColor(phase).withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isActive ? _getPhaseColor(phase) : Colors.greenAccent,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isActive ? 'Sade Sati Active' : 'No Sade Sati',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Text(
              _getPhaseTitle(phase),
              style: TextStyle(
                color: _getPhaseColor(phase),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (status.daysRemaining != null && isActive)
            LinearProgressIndicator(
              value: 1 - (status.daysRemaining! / 913),
              backgroundColor: Colors.white10,
              color: _getPhaseColor(phase),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          if (status.daysRemaining != null && isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${status.daysRemaining} days remaining in this phase',
                style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sade Sati Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelinePhase('First Phase', '12th from Moon', 'first_phase'),
          const SizedBox(height: 8),
          _buildTimelinePhase('Second Phase', 'Moon Sign', 'second_phase'),
          const SizedBox(height: 8),
          _buildTimelinePhase('Third Phase', '2nd from Moon', 'third_phase'),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(String title, String subtitle, String phaseKey) {
    final isCurrent = status.phase == phaseKey;
    final isActive = status.isSadeSati;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrent && isActive
            ? _getPhaseColor(phaseKey).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent && isActive
              ? _getPhaseColor(phaseKey).withOpacity(0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent && isActive
                  ? _getPhaseColor(phaseKey)
                  : Colors.white10,
            ),
            child: Center(
              child: Icon(
                isCurrent && isActive ? Icons.circle : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCurrent && isActive ? Colors.white : Colors.white70,
                    fontWeight: isCurrent && isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isCurrent && isActive ? _getPhaseColor(phaseKey) : const Color(0xFF6B6B99),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent && isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPhaseColor(phaseKey).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CURRENT',
                style: TextStyle(
                  color: _getPhaseColor(phaseKey),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (status.isSadeSati && status.description != null)
            Text(
              status.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            )
          else
            const Text(
              'You are not currently in Sade Sati. Saturn is not transiting the 12th, 1st, or 2nd house from your Moon sign.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 16),
          _buildStatusRow('Moon Sign', status.moonSign),
          const SizedBox(height: 8),
          _buildStatusRow('Saturn Sign', status.saturnSign),
          if (status.startDate != null && status.endDate != null) ...[
            const SizedBox(height: 8),
            _buildStatusRow('Phase Dates', '${status.startDate} to ${status.endDate}'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRemedies(BuildContext context) {
    final remedies = _getRemediesForPhase(status.phase);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Remedies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (remedies.isEmpty)
            const Text(
              'No specific remedies for this phase.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            )
          else
            ...remedies.map((remedy) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remedy,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTransitDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is Sade Sati?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sade Sati is a 7.5-year period when Saturn transits through the 12th, 1st, and 2nd houses from your Moon sign. This transit is believed to bring challenges, karmic lessons, and opportunities for spiritual growth in Vedic astrology.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Each phase lasts approximately 2.5 years:',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('First Phase', 'Saturn in 12th from Moon', 'Preparation, introspection, financial challenges'),
          _buildDetailRow('Second Phase', 'Saturn in Moon sign', 'Peak challenges, health, career, relationships'),
          _buildDetailRow('Third Phase', 'Saturn in 2nd from Moon', 'Integration, results, financial stability'),
          const SizedBox(height: 16),
          const Text(
            'Note: The effects of Sade Sati vary based on your Moon sign, Saturn placement, and overall chart.',
            style: TextStyle(color: Color(0xFF6B6B99), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String phase, String position, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPhaseColor(phase.toLowerCase().replaceAll(' ', '_')),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  position,
                  style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'first_phase':
        return const Color(0xFF87CEEB); // Light blue
      case 'second_phase':
        return const Color(0xFFFF6B6B); // Red
      case 'third_phase':
        return const Color(0xFF64FF8A); // Green
      default:
        return const Color(0xFF7C6EFA); // Purple
    }
  }

  static String _getPhaseTitle(String phase) {
    switch (phase) {
      case 'first_phase':
        return 'First Phase (Rising)'; 
      case 'second_phase':
        return 'Second Phase (Peak)';
      case 'third_phase':
        return 'Third Phase (Setting)';
      default:
        return 'No Active Phase';
    }
  }

  static List<String> _getRemediesForPhase(String? phase) {
    if (phase == null) return [];
    
    switch (phase) {
      case 'first_phase':
        return [
          'Wear blue sapphire (Neelam) after consulting an astrologer.',
          'Chant Shani Mantra (Om Sham Shanicharaya Namah) daily.',
          'Donate black sesame seeds, iron, or black clothes on Saturdays.',
          'Perform Shani Puja or visit a Saturn temple.',
          'Practice meditation and mindfulness to navigate emotional challenges.',
        ];
      case 'second_phase':
        return [
          'Wear a Jyotish-quality blue sapphire (Neelam) ring on the middle finger.',
          'Chant the Mahamrityunjaya Mantra for health and protection.',
          'Donate mustard oil, black lentils, or shoes to the needy on Saturdays.',
          'Avoid starting new ventures or making major life decisions without careful consideration.',
          'Practice patience, discipline, and humility in all aspects of life.',
          'Perform Rudrabhishek or Shiva Puja for spiritual strength.',
        ];
      case 'third_phase':
        return [
          'Continue wearing blue sapphire if it suits your chart.',
          'Chant the Hanuman Chalisa for protection and strength.',
          'Donate food, especially sweets, to children or the elderly.',
          'Focus on financial planning and long-term security.',
          'Express gratitude and share your blessings with others.',
          'Prepare for the end of the Sade Sati period and new beginnings.',
        ];
      default:
        return [];
    }
  }
}

// ─── Loading & Error States ─────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF7C6EFA)),
          SizedBox(height: 16),
          Text(
            'Calculating your Sade Sati status...',
            style: TextStyle(color: Color(0xFF9B93CC)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, this.onRetry});
  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error loading Sade Sati status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6EFA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRetry ?? () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Riverpod Provider ─────────────────────────────────────────────────────

final sadeSatiStatusProvider = FutureProvider.autoDispose.family<SadeSatiStatus, String>((ref, profileId) async {
  final repository = ref.watch(transitRepositoryProvider);
  return repository.getSadeSatiStatus(profileId);
});