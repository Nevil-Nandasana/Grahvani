/// Sade Sati Saturn Transit Screen — 7.5-Year Saturn Transit Dashboard & Remedies
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';

class SadeSatiScreen extends ConsumerStatefulWidget {
  const SadeSatiScreen({super.key, required this.profileId});
  final String profileId;

  @override
  ConsumerState<SadeSatiScreen> createState() => _SadeSatiScreenState();
}

class _SadeSatiScreenState extends ConsumerState<SadeSatiScreen> {
  bool _isLoading = true;
  bool _isPdfLoading = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchSadeSatiData();
  }

  Future<void> _fetchSadeSatiData() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/api/v1/transits/sade-sati/${widget.profileId}');
      if (response.statusCode == 200) {
        final body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
        setState(() {
          _data = (body['data'] ?? body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load Sade Sati details (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (_data == null) return;

    setState(() => _isPdfLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/transits/sade-sati/export-pdf',
        data: {
          'profile_id': widget.profileId,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sade Sati Analysis',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Saturn 7.5 Year Transit Cycle',
                style: TextStyle(color: Color(0xFF6B6B99), fontSize: 11)),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6EFA)))
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data ?? {};
    final bool isActive = d['is_active'] as bool? ?? false;
    final String phase = d['phase'] as String? ?? 'none';
    final String phaseName = d['phase_name'] as String? ?? 'No Active Sade Sati';
    final String moonSign = d['moon_sign'] as String? ?? 'Unknown';
    final String saturnSign = d['saturn_sign'] as String? ?? 'Unknown';
    final String description = d['description'] as String? ?? '';
    final List<dynamic> remedies = d['remedies'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saturn Status Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF3A1C71), const Color(0xFFD76D77)]
                    : [const Color(0xFF16163A), const Color(0xFF252554)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🪐', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'SADE SATI ACTIVE' : 'NO SADE SATI',
                            style: TextStyle(
                              color: isActive ? const Color(0xFFFFD700) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phaseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignInfo('Your Moon Sign', moonSign, Icons.brightness_3),
                    _buildSignInfo('Saturn Transit', saturnSign, Icons.public),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3-Phase Status Stepper
          const Text(
            'Sade Sati Phase Breakdown',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPhaseStepper(phase),
          const SizedBox(height: 20),

          // Description Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16163A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A5A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF7C6EFA), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.4, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Remedies Section
          const Text(
            'Recommended Vedic Remedies',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...remedies.map((remedy) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12122C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22224C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF5B4FDB), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          remedy.toString(),
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSignInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, color: const Color(0xFF9B93CC), size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseStepper(String activePhase) {
    final phases = [
      {'code': 'first_phase', 'title': 'Phase 1', 'subtitle': '12th from Moon'},
      {'code': 'second_phase', 'title': 'Phase 2 (Peak)', 'subtitle': 'Over Moon Sign'},
      {'code': 'third_phase', 'title': 'Phase 3', 'subtitle': '2nd from Moon'},
    ];

    return Row(
      children: phases.map((p) {
        final isCurrent = p['code'] == activePhase;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF5B4FDB) : const Color(0xFF16163A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? const Color(0xFF7C6EFA) : const Color(0xFF2A2A5A),
              ),
            ),
            child: Column(
              children: [
                Text(
                  p['title']!,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white60,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  p['subtitle']!,
                  style: TextStyle(
                    color: isCurrent ? Colors.white70 : Colors.white38,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
