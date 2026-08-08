/// Login Screen — Google Sign-In + Phone OTP authentication UI
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_state.dart';

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
  ConfirmationResult? _confirmationResult;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _fadeController.dispose();
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
      backgroundColor: const Color(0xFF0A0A1A),
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
                  const SizedBox(height: 16),
                  _buildDemoBypassButton(context),
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
              colors: [Color(0xFF7C6EFA), Color(0xFF3B2FBE)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4FDB).withOpacity(0.6),
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
                color: const Color(0xFF9B93CC),
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3730A3)),
          ),
          child: const Text(
            'Sign In / Create Account',
            style: TextStyle(
              color: Color(0xFFA5B4FC),
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
          'Enter your phone number',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 16),
        _StyledTextField(
          controller: _phoneController,
          hintText: '+91 9876543210',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
        ),
        const SizedBox(height: 16),
        _AuthButton(
          label: 'Send OTP',
          icon: const Icon(Icons.send, color: Colors.white, size: 18),
          isLoading: isLoading,
          onPressed: () async {
            final result = await ref
                .read(authNotifierProvider.notifier)
                .sendPhoneOtp(_phoneController.text.trim());
            if (result != null && mounted) {
              setState(() {
                _confirmationResult = result;
                _otpSent = true;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _showOtpFlow = false),
          child: const Text('← Back', style: TextStyle(color: Color(0xFF9B93CC))),
        ),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Text(
          'Enter the OTP sent to\n${_phoneController.text}',
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
            if (_confirmationResult == null) return;
            await ref
                .read(authNotifierProvider.notifier)
                .verifyOtp(_confirmationResult!, _otpController.text.trim());
          },
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

  Widget _buildDemoBypassButton(BuildContext context) {
    return _AuthButton(
      label: 'Demo / Guest Access (Local Testing)',
      icon: const Icon(Icons.flash_on, color: Color(0xFFFBBF24), size: 20),
      isLoading: false,
      onPressed: () {
        ref.read(authRepositoryProvider).consentStateNotifier.value = true;
        context.go('/home');
      },
    );
  }

  Widget _buildErrorBanner(String rawMessage) {
    final isApiKeyError = rawMessage.contains('api-key-not-valid');
    final message = isApiKeyError
        ? 'Firebase API key is not configured in firebase_options.dart yet. Tap "Demo / Guest Access" above to test all features locally.'
        : rawMessage.replaceAll('Exception: ', '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApiKeyError
            ? Colors.amber.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApiKeyError
              ? Colors.amber.withOpacity(0.4)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isApiKeyError ? const Color(0xFFFBBF24) : Colors.redAccent,
          fontSize: 13,
        ),
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
          side: const BorderSide(color: Color(0xFF3D3266), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: const Color(0xFF12122A),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7C6EFA),
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
