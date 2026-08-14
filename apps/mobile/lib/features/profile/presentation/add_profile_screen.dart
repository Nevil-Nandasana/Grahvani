/// Add Profile Screen — 4-step multi-step form for birth profile creation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api_client.dart';
import '../domain/profile_provider.dart';
import '../../theme/app_colors.dart';

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
  double _latitude = 0;
  double _longitude = 0;
  String _timezone = 'Asia/Kolkata';
  bool _isSubmitting = false;
  String? _errorMessage;

  final _steps = ['Name', 'Date of Birth', 'Time of Birth', 'Birthplace'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    return switch (_step) {
      0 => _nameController.text.trim().length >= 2,
      1 => _selectedDate != null,
      2 => _selectedTime != null,
      3 => _placeName.isNotEmpty,
      _ => false,
    };
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dob = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final tob =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      await ref.read(profilesNotifierProvider.notifier).createProfile(
            name: _nameController.text.trim(),
            dateOfBirth: dob,
            timeOfBirth: tob,
            placeName: _placeName,
            latitude: _latitude,
            longitude: _longitude,
            timezone: _timezone,
          );

      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Birth Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildStepContent(),
                  const Spacer(),
                  if (_errorMessage != null)
                    _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.primaryBurgundy
                        : isActive
                            ? Colors.transparent
                            : Colors.transparent,
                    border: Border.all(
                      color: isDone || isActive
                          ? AppColors.primaryBurgundy
                          : AppColors.darkBgStrong,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primaryBurgundy
                                  : AppColors.darkBgStrong,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppColors.primaryBurgundy
                          : AppColors.darkBgSecondary,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildNameStep(),
      1 => _buildDateStep(),
      2 => _buildTimeStep(),
      3 => _buildPlaceStep(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('What is the name?'),
        const SizedBox(height: 8),
        _stepSubtitle("Enter the full name for this birth chart."),
        const SizedBox(height: 24),
        _StyledField(
          controller: _nameController,
          hint: 'e.g. Aditya Sharma',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Date of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle('Select the birth date for accurate chart calculation.'),
        const SizedBox(height: 24),
        _DatePickerButton(
          selectedDate: _selectedDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryBurgundy,
                    onPrimary: Colors.white,
                    surface: AppColors.darkBgElevated,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Time of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle('Enter the birth time as accurately as possible.'),
        const SizedBox(height: 24),
        _TimePickerButton(
          selectedTime: _selectedTime,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 6, minute: 0),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryBurgundy,
                    onPrimary: Colors.white,
                    surface: AppColors.darkBgElevated,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedTime = picked);
          },
        ),
      ],
    );
  }

  Widget _buildPlaceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Place of Birth'),
        const SizedBox(height: 8),
        _stepSubtitle('Enter the city or place of birth for geocoding.'),
        const SizedBox(height: 24),
        // City search field — geocoding via backend Google Places integration
        _CitySearchField(
          onPlaceSelected: (name, lat, lng, tz) {
            setState(() {
              _placeName = name;
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
              color: AppColors.darkBgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBgStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryBurgundy, size: 20),
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
                        'Lat: ${_latitude.toStringAsFixed(4)}  Lng: ${_longitude.toStringAsFixed(4)}  TZ: $_timezone',
                        style: const TextStyle(
                            color: AppColors.textMutedDark, fontSize: 11),
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
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _stepSubtitle(String text) {
    return Text(text, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 14));
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkBgStrong),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => setState(() => _step--),
              child: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBurgundy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _canProceed
                ? (_step < _steps.length - 1
                    ? () => setState(() => _step++)
                    : _isSubmitting
                        ? null
                        : _submit)
                : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _step < _steps.length - 1 ? 'Next' : 'Create Profile',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(message,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: AppColors.darkBgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBgStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBgStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBurgundy, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.selectedDate, required this.onTap});
  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkBgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null
                ? AppColors.primaryBurgundy
                : AppColors.darkBgStrong,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primaryBurgundy, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate != null
                  ? DateFormat('dd MMMM yyyy').format(selectedDate!)
                  : 'Select date',
              style: TextStyle(
                color: selectedDate != null ? Colors.white : Colors.white38,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({required this.selectedTime, required this.onTap});
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkBgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedTime != null
                ? AppColors.primaryBurgundy
                : AppColors.darkBgStrong,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primaryBurgundy, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedTime != null
                  ? selectedTime!.format(context)
                  : 'Select time',
              style: TextStyle(
                color: selectedTime != null ? Colors.white : Colors.white38,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// City search field — in production wires to Google Places API via backend.
class _CitySearchField extends StatefulWidget {
  const _CitySearchField({required this.onPlaceSelected});
  final void Function(String name, double lat, double lng, String tz)
      onPlaceSelected;

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  final _controller = TextEditingController();

  // Hardcoded demo suggestions — production would call Google Places Autocomplete API
  static const List<Map<String, dynamic>> _demoPlaces = [
    {'name': 'New Delhi, India', 'lat': 28.6139, 'lng': 77.2090, 'tz': 'Asia/Kolkata'},
    {'name': 'Mumbai, India', 'lat': 19.0760, 'lng': 72.8777, 'tz': 'Asia/Kolkata'},
    {'name': 'Bangalore, India', 'lat': 12.9716, 'lng': 77.5946, 'tz': 'Asia/Kolkata'},
    {'name': 'Chennai, India', 'lat': 13.0827, 'lng': 80.2707, 'tz': 'Asia/Kolkata'},
    {'name': 'Kolkata, India', 'lat': 22.5726, 'lng': 88.3639, 'tz': 'Asia/Kolkata'},
    {'name': 'Hyderabad, India', 'lat': 17.3850, 'lng': 78.4867, 'tz': 'Asia/Kolkata'},
    {'name': 'Pune, India', 'lat': 18.5204, 'lng': 73.8567, 'tz': 'Asia/Kolkata'},
  ];

  List<Map<String, dynamic>> _suggestions = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final filtered = _demoPlaces
        .where((p) =>
            (p['name'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() => _suggestions = filtered);
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
            prefixIcon:
                const Icon(Icons.search, color: AppColors.primaryBurgundy, size: 20),
            filled: true,
            fillColor: AppColors.darkBgElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBgStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBgStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBurgundy, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.darkBgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBgStrong),
            ),
            child: Column(
              children: _suggestions
                  .map(
                    (p) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on,
                          color: AppColors.primaryBurgundy, size: 18),
                      title: Text(
                        p['name'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      onTap: () {
                        _controller.text = p['name'] as String;
                        setState(() => _suggestions = []);
                        widget.onPlaceSelected(
                          p['name'] as String,
                          (p['lat'] as num).toDouble(),
                          (p['lng'] as num).toDouble(),
                          p['tz'] as String,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
