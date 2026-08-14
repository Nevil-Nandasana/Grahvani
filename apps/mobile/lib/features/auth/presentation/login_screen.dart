/// Login Screen — Google Sign-In + Phone OTP authentication UI
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Phone OTP state
  bool _showOtpFlow = false;
  bool _otpSent = false;
  PhoneAuthSession? _phoneAuthSession;
  String _selectedCountryCode = '+91';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  static const _countryOptions = [
    (flag: '🇮🇳', name: 'India', code: '+91', length: 10),
    (flag: '🇺🇸', name: 'USA', code: '+1', length: 10),
    (flag: '🇬🇧', name: 'UK', code: '+44', length: 10),
    (flag: '🇦🇪', name: 'UAE', code: '+971', length: 9),
    (flag: '🇦🇺', name: 'Australia', code: '+61', length: 9),
    (flag: '🇨🇦', name: 'Canada', code: '+1', length: 10),
    (flag: '🇸🇬', name: 'Singapore', code: '+65', length: 8),
    (flag: '🇩🇪', name: 'Germany', code: '+49', length: 10),
    (flag: '🌐', name: 'Other', code: '+', length: 10),
  ];

  String get _cleanPhoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  int get _expectedLength {
    final country = _countryOptions.firstWhere(
      (c) => c.code == _selectedCountryCode,
      orElse: () => (flag: '🌐', name: 'Other', code: _selectedCountryCode, length: 10),
    );
    return country.length;
  }

  bool get _isPhoneValid {
    final digits = _cleanPhoneDigits;
    if (_selectedCountryCode == '+91') {
      return digits.length == 10;
    }
    return digits.length >= 7 && digits.length <= 15;
  }

  String get _fullPhoneNumber => '$_selectedCountryCode$_cleanPhoneDigits';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _onPhoneChanged() {
    var text = _phoneController.text;
    // Auto-strip leading +91 or + when pasted
    if (text.startsWith('+91')) {
      text = text.substring(3).trim();
      _phoneController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }
    // Auto-strip leading 0
    if (text.startsWith('0') && text.length > 1) {
      text = text.substring(1);
      _phoneController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Navigate home on successful auth
    ref.listen(authStateStreamProvider, (_, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          context.go('/home');
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildBrandHeader(context),
                const Spacer(flex: 2),
                if (!_showOtpFlow) ...[
                  _buildGoogleSignInButton(context, isLoading),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildPhoneButton(context),
                ] else if (!_otpSent) ...[
                  _buildPhoneInput(context, isLoading),
                ] else ...[
                  _buildOtpInput(context, isLoading),
                ],
                const SizedBox(height: 24),
                if (authState.hasError)
                  _buildErrorBanner(authState.error.toString()),
                const Spacer(flex: 1),
                _buildFooterText(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Column(
      children: [
        // Celestial glyph
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.primaryBurgundy, AppColors.primaryBurgundyDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBurgundy.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('🪐', style: TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Grahvani',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vedic Astrology, Precisely.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryDark,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkBgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBgStrong),
          ),
          child: const Text(
            'Sign In / Create Account',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, bool isLoading) {
    return _AuthButton(
      label: 'Continue with Google',
      icon: _GoogleIcon(),
      isLoading: isLoading,
      onPressed: () async {
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      },
    );
  }

  Widget _buildPhoneButton(BuildContext context) {
    return _AuthButton(
      label: 'Continue with Phone',
      icon: const Icon(Icons.phone_android, color: Colors.white, size: 20),
      isLoading: false,
      onPressed: () => setState(() => _showOtpFlow = true),
    );
  }

  Widget _buildPhoneInput(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Text(
          'Enter your mobile number',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'We will send an OTP to verify your account',
          style: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code Selector
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.darkBgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBgStrong),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: AppColors.darkBgElevated,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                  items: _countryOptions.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.code,
                      child: Text(
                        '${c.flag} ${c.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCountryCode = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mobile Number Input (10 digits)
            Expanded(
              child: _StyledTextField(
                controller: _phoneController,
                hintText: _selectedCountryCode == '+91' ? '98765 43210' : 'Mobile number',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_expectedLength > 0 ? _expectedLength : 15),
                ],
              ),
            ),
          ],
        ),
        // Dynamic Mobile Number Validator Banner
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _cleanPhoneDigits.isEmpty
                        ? Icons.info_outline
                        : _isPhoneValid
                            ? Icons.check_circle
                            : Icons.error_outline,
                    size: 14,
                    color: _cleanPhoneDigits.isEmpty
                        ? AppColors.textSecondaryDark
                        : _isPhoneValid
                            ? Colors.greenAccent
                            : Colors.amberAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _cleanPhoneDigits.isEmpty
                        ? 'Enter $_expectedLength-digit number'
                        : _cleanPhoneDigits.length < _expectedLength
                            ? 'Number too short (${_cleanPhoneDigits.length}/$_expectedLength digits)'
                            : _isPhoneValid
                                ? 'Valid mobile number'
                                : 'Invalid length',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _isPhoneValid ? FontWeight.w600 : FontWeight.normal,
                      color: _cleanPhoneDigits.isEmpty
                          ? AppColors.textSecondaryDark
                          : _isPhoneValid
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              Text(
                '${_cleanPhoneDigits.length}/$_expectedLength',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isPhoneValid ? Colors.greenAccent : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _AuthButton(
          label: 'Send OTP',
          icon: const Icon(Icons.send, color: Colors.white, size: 18),
          isLoading: isLoading,
          onPressed: !_isPhoneValid
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid $_expectedLength-digit mobile number'),
                      backgroundColor: Colors.amber[900],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : () async {
                  final fullNumber = _fullPhoneNumber;
                  final result = await ref
                      .read(authNotifierProvider.notifier)
                      .sendPhoneOtp(fullNumber);
                  if (result != null && mounted) {
                    setState(() {
                      _phoneAuthSession = result;
                      _otpSent = true;
                    });
                  }
                },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _showOtpFlow = false),
          child: const Text('← Back', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Text(
          'Enter the OTP sent to\n$_selectedCountryCode $_cleanPhoneDigits',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        _StyledTextField(
          controller: _otpController,
          hintText: '6-digit OTP',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        const SizedBox(height: 16),
        _AuthButton(
          label: 'Verify OTP',
          icon: const Icon(Icons.verified_user, color: Colors.white, size: 18),
          isLoading: isLoading,
          onPressed: () async {
            if (_phoneAuthSession == null) return;
            await ref
                .read(authNotifierProvider.notifier)
                .verifyOtp(_phoneAuthSession!, _otpController.text.trim());
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _otpSent = false;
            _otpController.clear();
          }),
          child: const Text('Change Number', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
      ],
    );
  }

  Widget _buildErrorBanner(String rawMessage) {
    var message = rawMessage.replaceAll('Exception: ', '');
    if (message.contains('operation-not-allowed')) {
      message = 'SMS is not allowed for this phone number/region. Enable Phone Auth in Firebase Console or use test number (+91 9999999999).';
    } else if (message.contains('billing-not-enabled')) {
      message = 'Real SMS requires Firebase Blaze billing. Use a Test Phone Number (+91 9999999999 with code 123456) or Google Sign-In for free testing!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooterText() {
    return Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy (DPDP Act 2023 compliant)',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 11,
        height: 1.5,
      ),
    );
  }
}

// ─── Reusable Auth Button ──────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.darkBgStrong, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: AppColors.darkBgElevated,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBurgundy,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Styled Text Field ─────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
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

// ─── Google Icon SVG ──────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Simplified Google 'G' icon using colored arcs
    final Paint red = Paint()..color = const Color(0xFFEA4335);
    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);

    final rect = Rect.fromCircle(center: c, radius: r);
    final sweepAngle = 1.5707963;

    canvas.drawArc(rect, -1.5707963, sweepAngle, false, red..strokeWidth = 3 ..style = PaintingStyle.stroke);
    canvas.drawArc(rect, 0, sweepAngle, false, blue..strokeWidth = 3 ..style = PaintingStyle.stroke);
    canvas.drawArc(rect, sweepAngle, sweepAngle, false, green..strokeWidth = 3 ..style = PaintingStyle.stroke);
    canvas.drawArc(rect, sweepAngle * 2, sweepAngle, false, yellow..strokeWidth = 3 ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
