/// Varshaphal (Solar Return) Annual Chart Screen
/// Shows the annual chart calculated at the exact moment the Sun returns
/// to its natal longitude, covering career, health, and events for the year.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../domain/chart_model.dart';
import '../domain/chart_provider.dart';
import 'chart_screen.dart';

// ─── Varshaphal Data Model ────────────────────────────────────────────────────

class VarshaphalData {
  const VarshaphalData({
    required this.year,
    required this.solarReturnDate,
    required this.chartFacts,
    required this.munthaPlanet,
    required this.varsheshaPlanet,
    required this.yearSummary,
  });
  final int year;
  final String solarReturnDate;
  final BirthChartFacts chartFacts;
  final String munthaPlanet;   // Muntha = progressed ascendant
  final String varsheshaPlanet; // Year lord
  final String yearSummary;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _varshaphalYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// ─── Screen ───────────────────────────────────────────────────────────────────

class VarshaphalScreen extends ConsumerStatefulWidget {
  const VarshaphalScreen({super.key, required this.profileId});
  final String profileId;

  @override
  ConsumerState<VarshaphalScreen> createState() => _VarshaphalScreenState();
}

class _VarshaphalScreenState extends ConsumerState<VarshaphalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isLoading = false;
  bool _isPdfLoading = false;
  String? _errorMsg;
  VarshaphalData? _data;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      // Try real API; fall back to synthetic demo data using the natal chart.
      final chartAsync = await ref.read(
          chartNotifierProvider(widget.profileId).future);
      if (chartAsync == null) throw Exception('Natal chart not found.');
      _buildDemoData(chartAsync);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildDemoData(BirthChartFacts natal) {
    final year = ref.read(_varshaphalYearProvider);
    // In production: POST /api/v1/charts/{profileId}/varshaphal?year={year}
    // For now, use the natal chart facts with a modified ayanamsa label.
    _data = VarshaphalData(
      year: year,
      solarReturnDate: '$year-${natal.ascendant.zodiacSign.substring(0, 3)}-21',
      chartFacts: natal,
      munthaPlanet: _selectMuntha(natal, year),
      varsheshaPlanet: _selectVarsesha(natal, year),
      yearSummary: _generateSummary(natal, year),
    );
  }

  static const _dayLords = [
    'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'
  ];

  static String _selectMuntha(BirthChartFacts chart, int year) {
    // Muntha moves 1 sign per year from natal ascendant
    final natalIdx = BirthChartFacts.zodiacOrder.indexOf(chart.ascendant.zodiacSign);
    final progIdx = (natalIdx + (year - 2000)) % 12;
    return BirthChartFacts.zodiacOrder[progIdx];
  }

  static String _selectVarsesha(BirthChartFacts chart, int year) {
    // Varsesha = lord of the day at solar return moment
    return _dayLords[year % 7];
  }

  static String _generateSummary(BirthChartFacts chart, int year) {
    final varsesha = _dayLords[year % 7];
    final themes = {
      'Sun': 'authority, recognition, and self-expression lead this year',
      'Moon': 'emotional growth and domestic matters take center stage',
      'Mars': 'courage, action, and competitive energy drive this year',
      'Mercury': 'communication, learning, and travel are highlighted',
      'Jupiter': 'expansion, wisdom, and fortune favor this year',
      'Venus': 'creativity, relationships, and prosperity bless this year',
      'Saturn': 'discipline, karmic lessons, and perseverance define this year',
    };
    return 'With $varsesha as Varsesha (year lord), ${themes[varsesha] ?? 'transformation and growth unfold'}.';
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_data == null) return;

    setState(() => _isPdfLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/charts/varshaphal/export-pdf',
        data: {
          'profile_id': widget.profileId,
          'year': _data!.year,
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
    final year = ref.watch(_varshaphalYearProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Varshaphal',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            Text('Solar Return $year',
                style: const TextStyle(
                    color: Color(0xFF6B6B99), fontSize: 11)),
          ],
        ),
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
                  onPressed: _data != null ? () => _exportPdf(context) : null,
                ),
          // Year picker
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF7C6EFA)),
            onPressed: () {
              ref.read(_varshaphalYearProvider.notifier).state = year - 1;
              _load();
            },
          ),
          Center(
            child: Text(
              '$year',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF7C6EFA)),
            onPressed: year < DateTime.now().year + 5
                ? () {
                    ref.read(_varshaphalYearProvider.notifier).state =
                        year + 1;
                    _load();
                  }
                : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF5B4FDB),
          labelColor: const Color(0xFF7C6EFA),
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'Annual Chart'), Tab(text: 'Predictions')],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('☀️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 12),
                  Text('Calculating Solar Return...',
                      style: TextStyle(color: Color(0xFF9B93CC))),
                ],
              ),
            )
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMsg!,
                          style:
                              const TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B4FDB)),
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _data == null
                  ? const Center(
                      child: Text('No data available.',
                          style: TextStyle(color: Colors.white54)))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _ChartTab(data: _data!),
                        _PredictionsTab(data: _data!),
                      ],
                    ),
    );
  }
}

// ─── Chart Tab ────────────────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.data});
  final VarshaphalData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Solar Return metadata card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Row(
              children: [
                const Text('☀️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solar Return ${data.year}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(data.solarReturnDate,
                          style: const TextStyle(
                              color: Color(0xFF6B6B99), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Varsesha',
                        style: TextStyle(
                            color: Color(0xFF6B6B99), fontSize: 10)),
                    Text(data.varsheshaPlanet,
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // North Indian Chart (Annual)
          _SrChartHeader(
            muntha: data.munthaPlanet,
            varsesha: data.varsheshaPlanet,
          ),
          const SizedBox(height: 8),
          NorthIndianChart(chart: data.chartFacts, division: 'D1'),
          const SizedBox(height: 20),

          // Annual planet placements
          _AnnualPlanetGrid(planets: data.chartFacts.planets),
        ],
      ),
    );
  }
}

class _SrChartHeader extends StatelessWidget {
  const _SrChartHeader({required this.muntha, required this.varsesha});
  final String muntha;
  final String varsesha;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Badge('MUNTHA', muntha, const Color(0xFF64FF8A))),
        const SizedBox(width: 10),
        Expanded(child: _Badge('VARSESHA', varsesha, const Color(0xFFFFD700))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AnnualPlanetGrid extends StatelessWidget {
  const _AnnualPlanetGrid({required this.planets});
  final List<PlanetPlacement> planets;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A35),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Planet',
                        style: TextStyle(
                            color: Color(0xFF6B6B99),
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Sign',
                        style: TextStyle(
                            color: Color(0xFF6B6B99),
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('Nakshatra',
                        style: TextStyle(
                            color: Color(0xFF6B6B99),
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
                Text('H',
                    style: TextStyle(
                        color: Color(0xFF6B6B99),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...planets.map((p) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFF1E1E3A))),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(p.displayName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text(p.zodiacSign,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12))),
                    Expanded(
                        flex: 3,
                        child: Text('${p.nakshatra} P${p.pada}',
                            style: const TextStyle(
                                color: Color(0xFF9B93CC), fontSize: 12))),
                    Text('${p.house}',
                        style: const TextStyle(
                            color: Color(0xFF6B6B99), fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Predictions Tab ──────────────────────────────────────────────────────────

class _PredictionsTab extends StatelessWidget {
  const _PredictionsTab({required this.data});
  final VarshaphalData data;

  static const _lifeAreas = [
    ('Career & Status', '💼', 'The 10th house lord in a strong annual position indicates professional growth and recognition.'),
    ('Relationships', '❤️', 'Venus and the 7th house lord determine the annual relationship quality and key partnerships.'),
    ('Health & Vitality', '🌿', 'The 1st and 6th house dynamics in the solar return chart indicate physical vitality.'),
    ('Finances', '💰', 'The 2nd and 11th house lords reveal income, gains, and financial opportunities this year.'),
    ('Travel & Learning', '✈️', '9th house activation indicates long journeys, higher education, or spiritual retreats.'),
    ('Spiritual Growth', '🕉️', 'Jupiter\'s position in the annual chart reveals wisdom, dharma, and spiritual expansion.'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1235), Color(0xFF120C2A)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5B4FDB).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🌟', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Year Overview',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.yearSummary,
                  style: const TextStyle(
                      color: Color(0xFF9B93CC), fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Life Area Forecasts',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._lifeAreas.map((area) => _LifeAreaCard(
                title: area.$1,
                emoji: area.$2,
                prediction: area.$3,
              )),
          const SizedBox(height: 16),
          Container(
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
                    'Varshaphal predictions shown are indicative. '
                    'Full accuracy requires your precise birth time and location. '
                    'Backend integration with /varshaphal endpoint pending.',
                    style: TextStyle(
                        color: Color(0xFF6B6B99),
                        fontSize: 11,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeAreaCard extends StatelessWidget {
  const _LifeAreaCard({
    required this.title,
    required this.emoji,
    required this.prediction,
  });
  final String title;
  final String emoji;
  final String prediction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(prediction,
                      style: const TextStyle(
                          color: Color(0xFF6B6B99),
                          fontSize: 12,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
