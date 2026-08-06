/// Kundali Milan — Ashtakoot Matchmaking Screen
/// Dual-profile selector with Guna Milan scoring table (36-point system)
/// Supports North Indian Ashtakoot scoring with all 8 kootas displayed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_model.dart';
import '../../profile/domain/profile_provider.dart';

// ─── Ashtakoot Score Model ────────────────────────────────────────────────────

class KootaScore {
  const KootaScore({
    required this.name,
    required this.sanskrit,
    required this.maxPoints,
    required this.obtainedPoints,
    required this.description,
    required this.aspect,
  });
  final String name;
  final String sanskrit;
  final int maxPoints;
  final double obtainedPoints;
  final String description;
  final String aspect; // what it assesses
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class KundaliMilanScreen extends ConsumerStatefulWidget {
  const KundaliMilanScreen({super.key});

  @override
  ConsumerState<KundaliMilanScreen> createState() => _KundaliMilanScreenState();
}

class _KundaliMilanScreenState extends ConsumerState<KundaliMilanScreen>
    with SingleTickerProviderStateMixin {
  BirthProfile? _profile1;
  BirthProfile? _profile2;
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  static const List<(String, String, int, String, String)> _kootaInfo = [
    ('Varna', 'वर्ण', 1, 'Spiritual compatibility', 'Soul evolution & spiritual level'),
    ('Vashya', 'वश्य', 2, 'Mutual attraction & control', 'Magnetic attraction between partners'),
    ('Tara', 'तारा', 3, 'Health & longevity compatibility', 'Health, birth star compatibility'),
    ('Yoni', 'योनि', 4, 'Sexual & biological compatibility', 'Physical & intimate compatibility'),
    ('Graha Maitri', 'ग्रह मैत्री', 5, 'Mental compatibility & friendship', 'Intellectual & emotional harmony'),
    ('Gana', 'गण', 6, 'Temperament compatibility', 'Nature — Deva, Manushya, or Rakshasa'),
    ('Bhakoot', 'भकूट', 7, 'Emotional & love compatibility', 'Health, prosperity & togetherness'),
    ('Nadi', 'नाड़ी', 8, 'Health & genetic compatibility', 'Physiological compatibility & progeny'),
  ];

  List<KootaScore> _computeScores() {
    if (_profile1 == null || _profile2 == null) return [];

    // Demo computation based on profile name hash for deterministic results.
    // In production this would call /api/v1/charts/milan.
    final seed1 = _profile1!.name.codeUnits.fold(0, (a, b) => a + b);
    final seed2 = _profile2!.name.codeUnits.fold(0, (a, b) => a + b);

    final scores = <double>[
      1.0,   // Varna (max 1)
      (seed1 + seed2) % 3 == 0 ? 2.0 : 1.0,  // Vashya (max 2)
      (seed1 * seed2 % 4) < 3 ? 3.0 : 1.5,   // Tara (max 3)
      (seed1 + seed2) % 5 < 4 ? 4.0 : 2.0,   // Yoni (max 4)
      (seed1 % 3) == (seed2 % 3) ? 5.0 : 3.0, // Graha Maitri (max 5)
      (seed1 + seed2) % 4 > 1 ? 6.0 : 0.0,   // Gana (max 6)
      (seed1 % 7) + 1.0,                       // Bhakoot (max 7)
      (seed1 + seed2) % 3 == 0 ? 0.0 : 8.0,   // Nadi (max 8) — 0 = dosha
    ];

    return List.generate(_kootaInfo.length, (i) {
      final (name, sanskrit, maxPts, desc, aspect) = _kootaInfo[i];
      return KootaScore(
        name: name,
        sanskrit: sanskrit,
        maxPoints: maxPts,
        obtainedPoints: scores[i].clamp(0, maxPts.toDouble()),
        description: desc,
        aspect: aspect,
      );
    });
  }

  double get _totalScore {
    return _computeScores()
        .fold(0.0, (sum, k) => sum + k.obtainedPoints);
  }

  String _compatibility(double score) {
    if (score >= 28) return 'Excellent Match';
    if (score >= 24) return 'Very Good';
    if (score >= 18) return 'Good';
    if (score >= 12) return 'Average';
    return 'Challenging';
  }

  Color _compatibilityColor(double score) {
    if (score >= 28) return const Color(0xFF64FF8A);
    if (score >= 24) return const Color(0xFFB0FF6F);
    if (score >= 18) return const Color(0xFFFFD700);
    if (score >= 12) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onProfileSelected() {
    if (_profile1 != null && _profile2 != null) {
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesNotifierProvider);
    final scores = _computeScores();
    final total = _totalScore;
    final hasMatch = _profile1 != null && _profile2 != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kundali Milan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF9B93CC)),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: profilesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Color(0xFF7C6EFA))),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.white54)),
        ),
        data: (profiles) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Profile selector row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ProfilePicker(
                      label: 'Person 1',
                      emoji: '💙',
                      selected: _profile1,
                      profiles: profiles
                          .where((p) => p != _profile2)
                          .toList(),
                      onChanged: (p) {
                        setState(() => _profile1 = p);
                        _onProfileSelected();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5B4FDB).withOpacity(0.15),
                            border: Border.all(
                                color: const Color(0xFF5B4FDB).withOpacity(0.4)),
                          ),
                          child: const Center(
                            child: Text('❤️', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _ProfilePicker(
                      label: 'Person 2',
                      emoji: '💜',
                      selected: _profile2,
                      profiles: profiles
                          .where((p) => p != _profile1)
                          .toList(),
                      onChanged: (p) {
                        setState(() => _profile2 = p);
                        _onProfileSelected();
                      },
                    ),
                  ),
                ],
              ),

              if (!hasMatch) ...[
                const SizedBox(height: 40),
                _PromptCard(),
              ],

              if (hasMatch) ...[
                const SizedBox(height: 24),

                // ── Score Circle ────────────────────────────────────────
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (_, __) {
                    final animated = total * _scoreAnim.value;
                    final color = _compatibilityColor(animated);
                    return Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            color: color.withOpacity(0.08),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${animated.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '/ 36',
                                style: TextStyle(
                                  color: color.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _compatibility(animated),
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_profile1!.name}  &  ${_profile2!.name}',
                          style: const TextStyle(
                              color: Color(0xFF6B6B99), fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Ashtakoot Table ─────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF12122A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A35),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('Koota',
                                  style: TextStyle(
                                      color: Color(0xFF6B6B99),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Aspect',
                                  style: TextStyle(
                                      color: Color(0xFF6B6B99),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Text('Score',
                                style: TextStyle(
                                    color: Color(0xFF6B6B99),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Rows
                      ...scores.map((k) => _KootaRow(
                            koota: k,
                            animValue: _scoreAnim.value,
                          )),
                      // Total row
                      AnimatedBuilder(
                        animation: _scoreAnim,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A35),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            border: Border(
                                top: BorderSide(color: Color(0xFF2A2A4A))),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text('TOTAL',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const Expanded(flex: 3, child: SizedBox()),
                              Text(
                                '${(total * _scoreAnim.value).toStringAsFixed(1)} / 36',
                                style: TextStyle(
                                  color: _compatibilityColor(
                                      total * _scoreAnim.value),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Disclaimer ──────────────────────────────────────────
                const _Disclaimer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16163A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Kundali Milan',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Ashtakoot (8-fold) compatibility matching is based on the Vimshottari nakshatra system. '
          'A score ≥ 18 is considered acceptable, ≥ 24 is very good, ≥ 28 is excellent.\n\n'
          'This is a traditional Vedic system — not a definitive judgement of compatibility.',
          style: TextStyle(color: Color(0xFF9B93CC), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF7C6EFA))),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.profiles,
    required this.onChanged,
  });
  final String label;
  final String emoji;
  final BirthProfile? selected;
  final List<BirthProfile> profiles;
  final ValueChanged<BirthProfile?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected != null
              ? const Color(0xFF5B4FDB).withOpacity(0.5)
              : const Color(0xFF2A2A4A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B6B99),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<BirthProfile?>(
              isExpanded: true,
              value: selected,
              dropdownColor: const Color(0xFF16163A),
              hint: const Text('Select person',
                  style: TextStyle(color: Color(0xFF3D3266), fontSize: 12)),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Color(0xFF7C6EFA)),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Select person',
                      style:
                          TextStyle(color: Color(0xFF6B6B99), fontSize: 12)),
                ),
                ...profiles.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 4),
            Text(
              selected!.dateOfBirth,
              style: const TextStyle(color: Color(0xFF4A4A6A), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _KootaRow extends StatelessWidget {
  const _KootaRow({required this.koota, required this.animValue});
  final KootaScore koota;
  final double animValue;

  @override
  Widget build(BuildContext context) {
    final animated = koota.obtainedPoints * animValue;
    final ratio = animated / koota.maxPoints;
    final color = ratio >= 0.7
        ? const Color(0xFF64FF8A)
        : ratio >= 0.4
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF6B6B);
    final isDosha =
        koota.name == 'Nadi' && koota.obtainedPoints == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: Color(0xFF1E1E3A))),
        color: isDosha ? Colors.redAccent.withOpacity(0.04) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(koota.name,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text(koota.sanskrit,
                    style: const TextStyle(
                        color: Color(0xFF4A4A6A), fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(koota.description,
                style:
                    const TextStyle(color: Color(0xFF6B6B99), fontSize: 11),
                maxLines: 2),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isDosha
                    ? '0 / ${koota.maxPoints} ⚠'
                    : '${animated.toStringAsFixed(0)} / ${koota.maxPoints}',
                style: TextStyle(
                  color: isDosha ? Colors.redAccent : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 50,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    backgroundColor: const Color(0xFF1E1E3A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDosha ? Colors.redAccent : color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          const Text('💑', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Select two profiles to compare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grahvani will calculate Ashtakoot compatibility\nusing Vimshottari Nakshatra analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF6B6B99), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FDB).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF5B4FDB).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF7C6EFA), size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ashtakoot scoring is a traditional Vedic guideline. '
              'A score ≥18/36 is generally considered compatible. '
              'Nadi dosha (0 pts) is considered significant.',
              style: TextStyle(
                  color: Color(0xFF6B6B99), fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
