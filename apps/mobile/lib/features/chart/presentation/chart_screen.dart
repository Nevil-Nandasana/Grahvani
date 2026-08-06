/// Chart Screen — North Indian diamond chart, dasha timeline, house bottom sheet
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/chart_model.dart';
import '../domain/chart_provider.dart';

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key, required this.chartId});
  final String chartId; // actually profileId used to trigger/load chart

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(chartNotifierProvider(widget.chartId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Birth Chart',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.public, color: Color(0xFFFFD700)),
            tooltip: 'Sade Sati Tracker',
            onPressed: () => context.push('/home/sade-sati/${widget.chartId}'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF7C6EFA)),
            tooltip: 'Ask AI',
            onPressed: chartAsync.valueOrNull != null
                ? () => context.push('/home/chat/new?chartId=${widget.chartId}')
                : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5B4FDB),
          labelColor: const Color(0xFF7C6EFA),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Dashas'),
          ],
        ),
      ),
      body: chartAsync.when(
        loading: () => const _LoadingChart(),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (chart) {
          if (chart == null) return const _ErrorView(error: 'Chart not found.');
          return TabBarView(
            controller: _tabController,
            children: [
              _ChartTab(chart: chart),
              _DashaTab(chart: chart),
            ],
          );
        },
      ),
    );
  }
}

// ─── Chart Tab ─────────────────────────────────────────────────────────────

class _ChartTab extends StatefulWidget {
  const _ChartTab({required this.chart});
  final BirthChartFacts chart;

  @override
  State<_ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<_ChartTab> {
  String _selectedDivision = 'D1';

  static const _divisions = [
    {'code': 'D1', 'label': 'D1 Rasi'},
    {'code': 'D9', 'label': 'D9 Navamsha'},
    {'code': 'D10', 'label': 'D10 Dasamsa'},
    {'code': 'D12', 'label': 'D12 Dwadasamsa'},
    {'code': 'D60', 'label': 'D60 Shashtiamsa'},
  ];

  @override
  Widget build(BuildContext context) {
    final ascSign = widget.chart.ascendantSignForDivision(_selectedDivision);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ayanamsa & Divisional Lagna badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF5B4FDB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5B4FDB).withOpacity(0.4)),
            ),
            child: Text(
              '${widget.chart.ayanamsa.toUpperCase()} AYANAMSA  •  $_selectedDivision LAGNA: $ascSign',
              style: const TextStyle(color: Color(0xFF9B93CC), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          // Divisional Chart Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _divisions.map((div) {
                final isSelected = div['code'] == _selectedDivision;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      div['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white60,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF5B4FDB),
                    backgroundColor: const Color(0xFF16163A),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDivision = div['code']!);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // North Indian Diamond Chart
          NorthIndianChart(chart: widget.chart, division: _selectedDivision),
          const SizedBox(height: 20),
          // Planet placement table
          _PlanetTable(planets: widget.chart.planets),
        ],
      ),
    );
  }
}

// ─── North Indian CustomPainter Chart ──────────────────────────────────────

class NorthIndianChart extends StatelessWidget {
  const NorthIndianChart({
    super.key,
    required this.chart,
    this.division = 'D1',
  });
  final BirthChartFacts chart;
  final String division;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return GestureDetector(
            onTapDown: (details) =>
                _handleTap(context, details.localPosition, size, chart),
            child: CustomPaint(
              size: Size(size, size),
              painter: _NorthIndianChartPainter(chart: chart, division: division),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    Offset tapPos,
    double size,
    BirthChartFacts chart,
  ) {
    // Determine which house was tapped using zone detection
    final house = _NorthIndianChartPainter.houseAtPosition(tapPos, size);
    if (house == null) return;

    final planetsInHouse = chart.planetsInDivisionalHouse(house, division);
    final cusp = chart.houseCusps[house - 1];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HouseDetailsSheet(
        houseNumber: house,
        cusp: cusp,
        planets: planetsInHouse,
      ),
    );
  }
}

class _NorthIndianChartPainter extends CustomPainter {
  const _NorthIndianChartPainter({required this.chart, this.division = 'D1'});
  final BirthChartFacts chart;
  final String division;

  // North Indian house layout — house number → center offset fractions (dx, dy)
  // Grid is divided into 12 triangular zones on a 3x3 diamond grid.
  static const _houseCenters = {
    1:  Offset(0.50, 0.17), // Top center
    2:  Offset(0.75, 0.25), // Top right
    3:  Offset(0.83, 0.50), // Right center
    4:  Offset(0.75, 0.75), // Bottom right
    5:  Offset(0.50, 0.83), // Bottom center
    6:  Offset(0.25, 0.75), // Bottom left
    7:  Offset(0.17, 0.50), // Left center
    8:  Offset(0.25, 0.25), // Top left
    9:  Offset(0.38, 0.38), // Inner top-left
    10: Offset(0.50, 0.50), // Center
    11: Offset(0.62, 0.38), // Inner top-right
    12: Offset(0.62, 0.62), // Inner bottom-right (note: varies per tradition)
  };

  // Simplified house tap regions as center points with detection radius
  static int? houseAtPosition(Offset tap, double size) {
    for (final entry in _houseCenters.entries) {
      final center = Offset(
        entry.value.dx * size,
        entry.value.dy * size,
      );
      if ((tap - center).distance < size * 0.12) return entry.key;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = const Color(0xFF10102A)
      ..style = PaintingStyle.fill;

    // Outer square
    final outerRect = Rect.fromLTWH(0, 0, s, s);
    canvas.drawRect(outerRect, bgPaint);
    canvas.drawRect(outerRect, paint);

    // Diagonal lines (corners)
    canvas.drawLine(Offset(0, 0), Offset(s / 3, s / 3), paint);
    canvas.drawLine(Offset(s, 0), Offset(s * 2 / 3, s / 3), paint);
    canvas.drawLine(Offset(0, s), Offset(s / 3, s * 2 / 3), paint);
    canvas.drawLine(Offset(s, s), Offset(s * 2 / 3, s * 2 / 3), paint);

    // Inner diamond (the central 4-triangle zone)
    final diamondPath = Path()
      ..moveTo(s / 2, s / 3)
      ..lineTo(s * 2 / 3, s / 2)
      ..lineTo(s / 2, s * 2 / 3)
      ..lineTo(s / 3, s / 2)
      ..close();
    canvas.drawPath(diamondPath, paint);

    // Cross lines
    canvas.drawLine(Offset(s / 3, s / 3), Offset(s * 2 / 3, s / 3), paint);
    canvas.drawLine(Offset(s * 2 / 3, s / 3), Offset(s * 2 / 3, s * 2 / 3), paint);
    canvas.drawLine(Offset(s * 2 / 3, s * 2 / 3), Offset(s / 3, s * 2 / 3), paint);
    canvas.drawLine(Offset(s / 3, s * 2 / 3), Offset(s / 3, s / 3), paint);

    // House numbers and planets
    for (final entry in _houseCenters.entries) {
      final houseNum = entry.key;
      final center = Offset(entry.value.dx * s, entry.value.dy * s);
      final planetsHere = chart.planetsInDivisionalHouse(houseNum, division);

      // House number
      _drawText(
        canvas,
        '$houseNum',
        center.translate(0, -10),
        const TextStyle(
          color: Color(0xFF4A4A7A),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );

      // Planet abbreviations
      if (planetsHere.isNotEmpty) {
        final labels = planetsHere.map((p) {
          final abbr = _planetAbbr(p.name);
          return p.isRetrograde ? '$abbr(R)' : abbr;
        }).toList();

        for (int i = 0; i < labels.length; i++) {
          _drawText(
            canvas,
            labels[i],
            center.translate(0, 4 + i * 12.0),
            TextStyle(
              color: _planetColor(planetsHere[i].name),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          );
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  static String _planetAbbr(String name) {
    return const {
      'Sun': 'Su', 'Moon': 'Mo', 'Mars': 'Ma', 'Mercury': 'Me',
      'Jupiter': 'Ju', 'Venus': 'Ve', 'Saturn': 'Sa', 'Rahu': 'Ra', 'Ketu': 'Ke',
    }[name] ?? name.substring(0, 2);
  }

  static Color _planetColor(String name) {
    return const {
      'Sun':     Color(0xFFFFB347),
      'Moon':    Color(0xFFE0E0FF),
      'Mars':    Color(0xFFFF6B6B),
      'Mercury': Color(0xFF64FF8A),
      'Jupiter': Color(0xFFFFD700),
      'Venus':   Color(0xFFFF9ECD),
      'Saturn':  Color(0xFF87CEEB),
      'Rahu':    Color(0xFFB0B0B0),
      'Ketu':    Color(0xFFD2A679),
    }[name] ?? Colors.white;
  }

  @override
  bool shouldRepaint(covariant _NorthIndianChartPainter oldDelegate) => false;
}

// ─── House Details Bottom Sheet ─────────────────────────────────────────────

class _HouseDetailsSheet extends StatelessWidget {
  const _HouseDetailsSheet({
    required this.houseNumber,
    required this.cusp,
    required this.planets,
  });

  final int houseNumber;
  final double cusp;
  final List<PlanetPlacement> planets;

  static const _houseNames = [
    'Lagna (Self)', 'Dhana (Wealth)', 'Sahaja (Siblings)', 'Sukha (Home)',
    'Putra (Children)', 'Ari (Enemies)', 'Yuvati (Partnership)', 'Mrityu (Transformation)',
    'Dharma (Fortune)', 'Karma (Career)', 'Labha (Gains)', 'Vyaya (Losses)',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12122A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
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
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4FDB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF5B4FDB).withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            '$houseNumber',
                            style: const TextStyle(
                              color: Color(0xFF7C6EFA),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'House $houseNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _houseNames[houseNumber - 1],
                            style: const TextStyle(
                                color: Color(0xFF9B93CC), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cusp: ${cusp.toStringAsFixed(2)}°',
                    style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
                  ),
                  const Divider(color: Color(0xFF2A2A4A), height: 24),
                  if (planets.isEmpty)
                    const Text('No planets in this house.',
                        style: TextStyle(color: Color(0xFF6B6B99), fontSize: 14))
                  else
                    ...planets.map((p) => _PlanetDetailRow(planet: p)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanetDetailRow extends StatelessWidget {
  const _PlanetDetailRow({required this.planet});
  final PlanetPlacement planet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _NorthIndianChartPainter._planetColor(planet.name)
                  .withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                _NorthIndianChartPainter._planetAbbr(planet.name),
                style: TextStyle(
                  color: _NorthIndianChartPainter._planetColor(planet.name),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(planet.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (planet.isRetrograde) ...[
                      const SizedBox(width: 6),
                      const Text('ℛ',
                          style:
                              TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${planet.zodiacSign} • ${planet.degreeInSign.toStringAsFixed(2)}° • ${planet.nakshatra} Pada ${planet.pada}',
                  style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Planet Table ──────────────────────────────────────────────────────────

class _PlanetTable extends StatelessWidget {
  const _PlanetTable({required this.planets});
  final List<PlanetPlacement> planets;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          _tableHeader(),
          ...planets.map((p) => _tableRow(p)),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: _HeaderCell('Planet')),
          Expanded(flex: 2, child: _HeaderCell('Sign')),
          Expanded(flex: 3, child: _HeaderCell('Nakshatra')),
          Expanded(flex: 1, child: _HeaderCell('H')),
        ],
      ),
    );
  }

  Widget _tableRow(PlanetPlacement p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1E3A))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  _NorthIndianChartPainter._planetAbbr(p.name),
                  style: TextStyle(
                    color: _NorthIndianChartPainter._planetColor(p.name),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (p.isRetrograde)
                  const Text(' ℛ',
                      style:
                          TextStyle(color: Color(0xFFFF6B6B), fontSize: 10)),
              ],
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(p.zodiacSign,
                  style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text('${p.nakshatra} P${p.pada}',
                  style: const TextStyle(
                      color: Color(0xFF9B93CC), fontSize: 12))),
          Expanded(
              flex: 1,
              child: Text('${p.house}',
                  style: const TextStyle(
                      color: Color(0xFF6B6B99), fontSize: 12))),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFF6B6B99),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5));
  }
}

// ─── Dasha Tab ─────────────────────────────────────────────────────────────

class _DashaTab extends StatefulWidget {
  const _DashaTab({required this.chart});
  final BirthChartFacts chart;

  @override
  State<_DashaTab> createState() => _DashaTabState();
}

class _DashaTabState extends State<_DashaTab> {
  final _scrollController = ScrollController();
  int? _expandedIndex;
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final dashas = widget.chart.vimshottariDasha.mahaDashas;
    for (int i = 0; i < dashas.length; i++) {
      final end = DateTime.tryParse(dashas[i].endDate);
      if (end != null && end.isAfter(_today)) {
        // Auto-expand current dasha
        setState(() => _expandedIndex = i);
        // Scroll to it
        final itemHeight = 72.0;
        _scrollController.animateTo(
          i * itemHeight,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        break;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isCurrentDasha(MahaDasha d) {
    final start = DateTime.tryParse(d.startDate);
    final end = DateTime.tryParse(d.endDate);
    if (start == null || end == null) return false;
    return _today.isAfter(start) && _today.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final dashas = widget.chart.vimshottariDasha.mahaDashas;
    final dasha = widget.chart.vimshottariDasha;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Birth nakshatra info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A4A)),
          ),
          child: Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Birth Nakshatra',
                      style: TextStyle(color: Color(0xFF6B6B99), fontSize: 11)),
                  Text(
                    '${dasha.birthNakshatra}  •  Lord: ${dasha.birthNakshatraLord}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(dashas.length, (i) {
          final d = dashas[i];
          final isCurrent = _isCurrentDasha(d);
          final isExpanded = _expandedIndex == i;
          return _MahaDashaCard(
            dasha: d,
            isCurrent: isCurrent,
            isExpanded: isExpanded,
            onTap: () => setState(
              () => _expandedIndex = isExpanded ? null : i,
            ),
            today: _today,
          );
        }),
      ],
    );
  }
}

class _MahaDashaCard extends StatelessWidget {
  const _MahaDashaCard({
    required this.dasha,
    required this.isCurrent,
    required this.isExpanded,
    required this.onTap,
    required this.today,
  });

  final MahaDasha dasha;
  final bool isCurrent;
  final bool isExpanded;
  final VoidCallback onTap;
  final DateTime today;

  static const _planetColors = {
    'Sun':     Color(0xFFFFB347),
    'Moon':    Color(0xFFE0E0FF),
    'Mars':    Color(0xFFFF6B6B),
    'Mercury': Color(0xFF64FF8A),
    'Jupiter': Color(0xFFFFD700),
    'Venus':   Color(0xFFFF9ECD),
    'Saturn':  Color(0xFF87CEEB),
    'Rahu':    Color(0xFFB0B0B0),
    'Ketu':    Color(0xFFD2A679),
  };

  Color get _color =>
      _planetColors[dasha.planet] ?? const Color(0xFF7C6EFA);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? _color.withOpacity(0.6)
                : const Color(0xFF2A2A4A),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: _color.withOpacity(0.12),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            ListTile(
              onTap: onTap,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color.withOpacity(0.15),
                  border: Border.all(color: _color.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    dasha.planet.substring(0, 2),
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(dasha.planet,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('CURRENT',
                          style: TextStyle(
                              color: _color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${dasha.startDate} → ${dasha.endDate}  (${dasha.durationYears.toStringAsFixed(1)} yr)',
                style:
                    const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF3D3266),
              ),
            ),
            if (isExpanded) _buildAntarDashas(),
          ],
        ),
      ),
    );
  }

  Widget _buildAntarDashas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          const Divider(color: Color(0xFF2A2A4A)),
          ...dasha.antarDashas.map((a) {
            final isCurrentAntar = () {
              final s = DateTime.tryParse(a.startDate);
              final e = DateTime.tryParse(a.endDate);
              return s != null && e != null && today.isAfter(s) && today.isBefore(e);
            }();
            final ac = _planetColors[a.planet] ?? const Color(0xFF9B93CC);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ac.withOpacity(0.12),
                    ),
                    child: Center(
                      child: Text(
                        a.planet.substring(0, 2),
                        style: TextStyle(
                            color: ac, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(a.planet,
                                style: TextStyle(
                                    color: isCurrentAntar
                                        ? ac
                                        : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isCurrentAntar
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            if (isCurrentAntar) ...[
                              const SizedBox(width: 4),
                              const Text('●',
                                  style: TextStyle(
                                      color: Color(0xFF64FF8A), fontSize: 8)),
                            ],
                          ],
                        ),
                        Text(
                          '${a.startDate} → ${a.endDate}',
                          style: const TextStyle(
                              color: Color(0xFF6B6B99), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Loading & Error States ─────────────────────────────────────────────────

class _LoadingChart extends StatelessWidget {
  const _LoadingChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪐', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: Color(0xFF7C6EFA)),
          const SizedBox(height: 16),
          Text(
            'Calculating your birth chart\nusing Swiss Ephemeris...',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF9B93CC), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

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
            Text(error,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
