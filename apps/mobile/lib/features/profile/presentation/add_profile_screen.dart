/// Add Profile Screen — 4-step multi-step form for birth profile creation
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api_client.dart';
import '../domain/profile_provider.dart';

class AddProfileScreen extends ConsumerStatefulWidget {
  const AddProfileScreen({super.key});

  @override
  ConsumerState<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends ConsumerState<AddProfileScreen> {
  int _step = 0;

  // Form data
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _placeName = '';
  String _stateName = '';
  String _countryName = '';
  String _pincode = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _timezone = 'Asia/Kolkata';

  final _steps = ['Name', 'Date of Birth', 'Time of Birth', 'Birthplace'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedDate != null;
      case 2:
        return _selectedTime != null;
      case 3:
        return _placeName.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    if (!_isStepValid()) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

    try {
      await ref.read(profilesNotifierProvider.notifier).createProfile(
            name: _nameController.text.trim(),
            dateOfBirth: dateStr,
            timeOfBirth: timeStr,
            placeName: _placeName,
            latitude: _latitude,
            longitude: _longitude,
            timezone: _timezone,
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Birth Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isDone = index < _step;
          final isCurrent = index == _step;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone || isCurrent
                        ? const Color(0xFF7C6EFA)
                        : const Color(0xFF26264A),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF7C6EFA)
                        : isCurrent
                            ? const Color(0xFF7C6EFA).withOpacity(0.2)
                            : const Color(0xFF161630),
                    border: Border.all(
                      color: isDone || isCurrent
                          ? const Color(0xFF7C6EFA)
                          : const Color(0xFF3D3266),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? const Color(0xFF7C6EFA) : const Color(0xFF6B6B99),
                            ),
                          ),
                  ),
                ),
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? const Color(0xFF7C6EFA)
                          : const Color(0xFF26264A),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildDateStep();
      case 2:
        return _buildTimeStep();
      case 3:
        return _buildPlaceStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Full Name'),
        const SizedBox(height: 8),
        _stepSubtitle('Enter the person\'s full legal or preferred name.'),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'e.g. Rahul Sharma',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF12122A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D3266)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D3266)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C6EFA), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDateStep() {
    final dateDisplay = _selectedDate != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
        : 'Select Date of Birth';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Date of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle('Accurate date is critical for planetary position math.'),
        const SizedBox(height: 24),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime(1995, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF7C6EFA),
                      surface: Color(0xFF1A1A32),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDate != null
                    ? const Color(0xFF7C6EFA)
                    : const Color(0xFF3D3266),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDate != null
                      ? const Color(0xFF7C6EFA)
                      : const Color(0xFF6B6B99),
                ),
                const SizedBox(width: 16),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.white : Colors.white.withOpacity(0.3),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStep() {
    final timeDisplay = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Select Time of Birth';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Time of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle(
            'Exact birth time determines the Ascendant (Lagna) and House boundaries.'),
        const SizedBox(height: 24),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF7C6EFA),
                      surface: Color(0xFF1A1A32),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedTime = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedTime != null
                    ? const Color(0xFF7C6EFA)
                    : const Color(0xFF3D3266),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _selectedTime != null
                      ? const Color(0xFF7C6EFA)
                      : const Color(0xFF6B6B99),
                ),
                const SizedBox(width: 16),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    color: _selectedTime != null ? Colors.white : Colors.white.withOpacity(0.3),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceStep() {
    final locationDetails = [
      if (_stateName.isNotEmpty) _stateName,
      if (_countryName.isNotEmpty) _countryName,
    ].join(', ');
    final pincodeText = _pincode.isNotEmpty ? ' - $_pincode' : '';
    final locationSubtitle = locationDetails.isNotEmpty
        ? '$locationDetails$pincodeText'
        : (_pincode.isNotEmpty ? 'Pincode: $_pincode' : 'Selected Birth Location');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Place of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle('Enter the city or place of birth for geocoding.'),
        const SizedBox(height: 24),
        _CitySearchField(
          onPlaceSelected: (name, state, country, postcode, lat, lng, tz) {
            setState(() {
              _placeName = name;
              _stateName = state;
              _countryName = country;
              _pincode = postcode;
              _latitude = lat;
              _longitude = lng;
              _timezone = tz;
            });
          },
        ),
        if (_placeName.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3D3266)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF7C6EFA), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_placeName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        locationSubtitle,
                        style: const TextStyle(
                            color: Color(0xFF8E8EA8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _stepSubtitle(String text) {
    return Text(text,
        style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 14));
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF3D3266)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
          ),
        if (_step > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isStepValid()
                ? () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      _submit();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF7C6EFA),
              disabledBackgroundColor: const Color(0xFF26264A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _step < _steps.length - 1 ? 'Next' : 'Create Profile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CitySearchField extends StatefulWidget {
  const _CitySearchField({required this.onPlaceSelected});

  final void Function(
    String name,
    String state,
    String country,
    String postcode,
    double lat,
    double lng,
    String tz,
  ) onPlaceSelected;

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    // Default place selection so form step is valid even before selecting a dropdown item
    widget.onPlaceSelected(
      trimmed,
      '',
      '',
      '',
      22.4707,
      70.0577,
      'Asia/Kolkata',
    );

    setState(() => _isLoading = true);

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await _fetchPlacesFromApi(trimmed);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPlacesFromApi(String query) async {
    final dio = Dio();
    final baseUrl = defaultApiBaseUrl;

    try {
      final res = await dio.get('$baseUrl/api/v1/places/search', queryParameters: {'q': query});
      if (res.statusCode == 200) {
        final rawData = res.data;
        final List list = (rawData is Map && rawData.containsKey('data'))
            ? rawData['data']
            : (rawData is List ? rawData : []);

        if (list.isNotEmpty) {
          return list.map<Map<String, dynamic>>((item) => {
                'name': (item['name'] as String? ?? '').trim(),
                'state': (item['state'] as String? ?? '').trim(),
                'country': (item['country'] as String? ?? '').trim(),
                'postcode': (item['postcode'] as String? ?? '').trim(),
                'lat': (item['latitude'] as num? ?? 22.4707).toDouble(),
                'lng': (item['longitude'] as num? ?? 70.0577).toDouble(),
                'tz': item['timezone'] as String? ?? 'Asia/Kolkata',
              }).toList();
        }
      }
    } catch (_) {}

    try {
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': query, 'format': 'json', 'addressdetails': 1, 'limit': 5},
      );
      if (res.statusCode == 200 && res.data is List) {
        final List items = res.data;
        if (items.isNotEmpty) {
          return items.map<Map<String, dynamic>>((item) {
            final addr = item['address'] ?? {};
            final countryCode = (addr['country_code'] ?? '').toString().toLowerCase();
            final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? item['display_name'].toString().split(',')[0]).toString().trim();
            final state = (addr['state'] ?? '').toString().trim();
            final country = (addr['country'] ?? '').toString().trim();
            final postcode = (addr['postcode'] ?? addr['postal_code'] ?? '').toString().trim();

            final tz = (countryCode == 'in' || countryCode == 'np' || countryCode == 'lk' || countryCode == 'bd')
                ? 'Asia/Kolkata'
                : 'UTC';
            return {
              'name': city.isNotEmpty ? city : query,
              'state': state,
              'country': country,
              'postcode': postcode,
              'lat': double.tryParse(item['lat'].toString()) ?? 22.4707,
              'lng': double.tryParse(item['lon'].toString()) ?? 70.0577,
              'tz': tz,
            };
          }).toList();
        }
      }
    } catch (_) {}

    return [
      {
        'name': query.trim(),
        'state': '',
        'country': '',
        'postcode': '',
        'lat': 22.4707,
        'lng': 70.0577,
        'tz': 'Asia/Kolkata',
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search city or place...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6EFA), size: 20),
            filled: true,
            fillColor: const Color(0xFF12122A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D3266)),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C6EFA).withOpacity(0.5)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFF26264A),
              ),
              itemBuilder: (context, index) {
                final p = _suggestions[index];
                final stateStr = p['state'] as String? ?? '';
                final countryStr = p['country'] as String? ?? '';
                final pinStr = p['postcode'] as String? ?? '';

                final locationParts = [
                  if (stateStr.isNotEmpty) stateStr,
                  if (countryStr.isNotEmpty) countryStr,
                ].join(', ');

                final subtitleText = locationParts.isNotEmpty
                    ? (pinStr.isNotEmpty ? '$locationParts - $pinStr' : locationParts)
                    : (pinStr.isNotEmpty ? 'Pincode: $pinStr' : 'Location Details');

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, color: Color(0xFF7C6EFA), size: 18),
                  title: Text(
                    p['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: const TextStyle(color: Color(0xFF8E8EA8), fontSize: 11),
                  ),
                  onTap: () {
                    final placeName = p['name'] as String;
                    _controller.text = placeName;
                    setState(() => _suggestions = []);
                    widget.onPlaceSelected(
                      placeName,
                      stateStr,
                      countryStr,
                      pinStr,
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble(),
                      p['tz'] as String,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
