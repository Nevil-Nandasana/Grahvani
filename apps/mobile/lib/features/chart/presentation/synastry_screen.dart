/// Synastry Dual-Chart Overlay Screen
/// Side-by-side North Indian charts for two profiles with planet-to-planet
/// aspect lines drawn between them, plus an aspects summary table.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile/domain/profile_model.dart';
import '../../profile/domain/profile_provider.dart';
import '../domain/chart_model.dart';
import '../domain/chart_provider.dart';
import 'chart_screen.dart';

// ─── Aspect Model ─────────────────────────────────────────────────────────────

class SynastryAspect {
  const SynastryAspect({
    required this.planet1,
    required this.planet2,
    required this.type,
    required this.orb,
    required this.isHarmonious,
  });
  final String planet1; // from person 1
  final String planet2; // from person 2
  final String type;    // Trine, Sextile, Square, Opposition, Conjunction
  final double orb;
  final bool isHarmonious;

  String get symbol {
    switch (type) {
      case 'Trine': return '△';
      case 'Sextile': return '⚹';
      case 'Square': return '□';
      case 'Opposition': return '☍';
      case 'Conjunction': return '☌';
      default: return '?';
    }
  }

  Color get color {
    switch (type) {
      case 'Trine': return const Color(0xFF64FF8A);
      case 'Sextile': return const Color(0xFF7C6EFA);
      case 'Square': return const Color(0xFFFF6B6B);
      case 'Opposition': return const Color(0xFFFF9B4F);
      case 'Conjunction': return const Color(0xFFFFD700);
      default: return Colors.white38;
    }
  }
}

// ─── Aspect Calculator ────────────────────────────────────────────────────────

List<SynastryAspect> computeSynastryAspects(
    BirthChartFacts chart1, BirthChartFacts chart2) {
  const aspectAngles = {
    'Conjunction': 0.0,
    'Sextile': 60.0,
    'Square': 90.0,
    'Trine': 120.0,
    'Opposition': 180.0,
  };
  const orbs = {
    'Conjunction': 8.0,
    'Sextile': 5.0,
    'Square': 7.0,
    'Trine': 7.0,
    'Opposition': 8.0,
  };
  const harmoniousTypes = {'Trine', 'Sextile', 'Conjunction'};

  final aspects = <SynastryAspect>[];

  for (final p1 in chart1.planets) {
    for (final p2 in chart2.planets) {
      double diff = (p2.longitude - p1.longitude).abs() % 360;
      if (diff > 180) diff = 360 - diff;

      for (final entry in aspectAngles.entries) {
        final orb = orbs[entry.key]!;
        final actualOrb = (diff - entry.value).abs();
        if (actualOrb <= orb) {
          aspects.add(SynastryAspect(
            planet1: p1.name,
            planet2: p2.name,
            type: entry.key,
            orb: actualOrb,
            isHarmonious: harmoniousTypes.contains(entry.key),
          ));
          break; // one aspect per pair
        }
      }
    }
  }

  aspects.sort((a, b) => a.orb.compareTo(b.orb));
  return aspects;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SynastryScreen extends ConsumerStatefulWidget {
  const SynastryScreen({super.key});

  @override
  ConsumerState<SynastryScreen> createState() => _SynastryScreenState();
}

class _SynastryScreenState extends ConsumerState<SynastryScreen>
    with SingleTickerProviderStateMixin {
  BirthProfile? _profile1;
  BirthProfile? _profile2;
  late TabController _tabs;
  bool _isPdfLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_profile1 == null || _profile2 == null) return;

    setState(() => _isPdfLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/charts/synastry/export-pdf',
        data: {
          'profile1_id': _profile1!.id,
          'profile2_id': _profile2!.id,
        },
      );
      final pdfUrl = response.data?['pdf_url'] as String? ?? response.data?['url'] as String?;
      if (pdfUrl != null) {
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF export is a Premium feature.'),
              backgroundColor: Color(0xFF3B2FBE),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: ${e.toString().replaceAll('ApiException', '').trim()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Synastry',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          _isPdfLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFFFD700)),
                  tooltip: 'Export PDF',
                  onPressed: (_profile1 != null && _profile2 != null) ? () => _exportPdf(context) : null,
                ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF5B4FDB),
          labelColor: const Color(0xFF7C6EFA),
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Charts'), Tab(text: 'Aspects')],
        ),
      ),
      body: profilesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C6EFA))),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.white54)),
        ),
        data: (profiles) => Column(
          children: [
            // Profile picker row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SynastryProfilePicker(
                      label: 'Person 1',
                      color: const Color(0xFF7C6EFA),
                      selected: _profile1,
                      profiles:
                          profiles.where((p) => p != _profile2).toList(),
                      onChanged: (p) => setState(() => _profile1 = p),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('↔️', style: TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: _SynastryProfilePicker(
                      label: 'Person 2',
                      color: const Color(0xFF64FF8A),
                      selected: _profile2,
                      profiles:
                          profiles.where((p) => p != _profile1).toList(),
                      onChanged: (p) => setState(() => _profile2 = p),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: (_profile1 == null || _profile2 == null)
                  ? _SelectPrompt()
                  : _SynastryBody(
                      profile1: _profile1!,
                      profile2: _profile2!,
                      tabController: _tabs,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SynastryBody extends ConsumerWidget {
  const _SynastryBody({
    required this.profile1,
    required this.profile2,
    required this.tabController,
  });
  final BirthProfile profile1;
  final BirthProfile profile2;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chart1Async = ref.watch(chartNotifierProvider(profile1.id));
    final chart2Async = ref.watch(chartNotifierProvider(profile2.id));

    // Wait for both charts
    if (chart1Async.isLoading || chart2Async.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7C6EFA)),
            SizedBox(height: 12),
            Text('Loading charts…',
                style: TextStyle(color: Color(0xFF9B93CC))),
          ],
        ),
      );
    }

    final chart1 = chart1Async.valueOrNull;
    final chart2 = chart2Async.valueOrNull;

    if (chart1 == null || chart2 == null) {
      return const Center(
        child: Text('Could not load one or both charts.',
            style: TextStyle(color: Colors.white54)),
      );
    }

    final aspects = computeSynastryAspects(chart1, chart2);

    return TabBarView(
      controller: tabController,
      children: [
        // Chart overlay tab
        _ChartsTab(
          chart1: chart1,
          chart2: chart2,
          profile1Name: profile1.name,
          profile2Name: profile2.name,
          aspects: aspects,
        ),
        // Aspects table tab
        _AspectsTab(aspects: aspects),
      ],
    );
  }
}

// ─── Charts Tab ───────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({
    required this.chart1,
    required this.chart2,
    required this.profile1Name,
    required this.profile2Name,
    required this.aspects,
  });
  final BirthChartFacts chart1;
  final BirthChartFacts chart2;
  final String profile1Name;
  final String profile2Name;
  final List<SynastryAspect> aspects;

  @override
  Widget build(BuildContext context) {
    final harmCount = aspects.where((a) => a.isHarmonious).length;
    final tensCount = aspects.where((a) => !a.isHarmonious).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Aspect summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AspectStat('Total', '${aspects.length}', Colors.white70),
                _AspectStat(
                    'Harmonious', '$harmCount', const Color(0xFF64FF8A)),
                _AspectStat(
                    'Tense', '$tensCount', const Color(0xFFFF6B6B)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Side-by-side charts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _ChartLabel(name: profile1Name, color: const Color(0xFF7C6EFA)),
                    const SizedBox(height: 6),
                    NorthIndianChart(chart: chart1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _ChartLabel(name: profile2Name, color: const Color(0xFF64FF8A)),
                    const SizedBox(height: 6),
                    NorthIndianChart(chart: chart2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key aspects list (top 5)
          if (aspects.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Aspects',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            ...aspects.take(5).map((a) => _AspectTile(aspect: a)),
          ],
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class _AspectStat extends StatelessWidget {
  const _AspectStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 10)),
      ],
    );
  }
}

class _AspectTile extends StatelessWidget {
  const _AspectTile({required this.aspect});
  final SynastryAspect aspect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: aspect.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(aspect.symbol,
                style: TextStyle(
                    color: aspect.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${aspect.planet1} ${aspect.type} ${aspect.planet2}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  Text(
                    'Orb: ${aspect.orb.toStringAsFixed(1)}°  •  ${aspect.isHarmonious ? "Harmonious" : "Tense"}',
                    style: const TextStyle(
                        color: Color(0xFF6B6B99), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              aspect.isHarmonious ? Icons.check_circle : Icons.warning,
              color: aspect.color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Aspects Tab ──────────────────────────────────────────────────────────────

class _AspectsTab extends StatelessWidget {
  const _AspectsTab({required this.aspects});
  final List<SynastryAspect> aspects;

  @override
  Widget build(BuildContext context) {
    if (aspects.isEmpty) {
      return const Center(
        child: Text('No major aspects found.',
            style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: aspects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _AspectTile(aspect: aspects[i]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SynastryProfilePicker extends StatelessWidget {
  const _SynastryProfilePicker({
    required this.label,
    required this.color,
    required this.selected,
    required this.profiles,
    required this.onChanged,
  });
  final String label;
  final Color color;
  final BirthProfile? selected;
  final List<BirthProfile> profiles;
  final ValueChanged<BirthProfile?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected != null ? color.withOpacity(0.5) : const Color(0xFF2A2A4A),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BirthProfile?>(
          isExpanded: true,
          value: selected,
          dropdownColor: const Color(0xFF16163A),
          hint: Text(label,
              style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: Icon(Icons.arrow_drop_down, color: color, size: 20),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B6B99), fontSize: 12)),
            ),
            ...profiles.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SelectPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5B4FDB).withOpacity(0.1),
            ),
            child: const Center(
              child: Text('🔭', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select two profiles',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Grahvani will calculate cross-chart\nplanetary aspects between both horoscopes.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF6B6B99), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
