import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/supabase_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, otp, newPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorText = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  void _setError(String msg) {
    if (mounted) setState(() { _errorText = msg; _isLoading = false; });
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) { _setError('Enter a valid email'); return; }
    setState(() { _isLoading = true; _errorText = ''; });
    try {
      final exists = await SupabaseService.emailExists(email);
      if (!exists) { _setError('No account found with this email.'); return; }
      await SupabaseService.resetPassword(email);
      if (mounted) setState(() { _step = _Step.otp; _isLoading = false; });
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      try {
        await SupabaseService.resetPassword(email);
        if (mounted) setState(() { _step = _Step.otp; _isLoading = false; });
      } catch (e) {
        _setError('Failed to send reset email. Please try again.');
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) { _setError('Enter the 6-digit code'); return; }
    setState(() { _isLoading = true; _errorText = ''; });
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailCtrl.text.trim().toLowerCase(),
        token: _otpValue,
        type: OtpType.recovery,
      );
      if (mounted) setState(() { _step = _Step.newPassword; _isLoading = false; });
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Invalid or expired code. Try again.');
    }
  }

  Future<void> _updatePassword() async {
    final password = _passwordCtrl.text;
    if (password.length < 6) { _setError('Password must be at least 6 characters'); return; }
    if (password != _confirmCtrl.text) { _setError('Passwords do not match'); return; }
    setState(() { _isLoading = true; _errorText = ''; });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to update password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left panel
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _step == _Step.email ? Icons.lock_reset_rounded
                          : _step == _Step.otp ? Icons.pin_outlined
                          : Icons.lock_outline_rounded,
                        size: 44, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _step == _Step.email ? 'Reset Password'
                        : _step == _Step.otp ? 'Check your email'
                        : 'New Password',
                      style: GoogleFonts.manrope(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == _Step.email ? "We'll send you a reset code"
                        : _step == _Step.otp ? 'Enter the 6-digit code'
                        : 'Almost there!',
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right panel
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: switch (_step) {
                    _Step.email      => _buildEmailStep(),
                    _Step.otp        => _buildOtpStep(),
                    _Step.newPassword => _buildNewPasswordStep(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Email ──
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forgot password?',
            style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text("Enter your email and we'll send you a reset code.",
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w300)),
        const SizedBox(height: 36),
        Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
          decoration: _inputDecoration('you@example.com', Icons.email_outlined),
        ),
        if (_errorText.isNotEmpty) _errorWidget(),
        const SizedBox(height: 28),
        _primaryButton('Send Reset Code', _isLoading ? null : _sendOtp),
        const SizedBox(height: 20),
        _backToLogin(),
      ],
    );
  }

  // ── Step 2: OTP ──
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter reset code',
            style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('We sent a 6-digit code to\n${_emailCtrl.text}',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15, height: 1.6)),
        const SizedBox(height: 36),
        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        if (_errorText.isNotEmpty) _errorWidget(),
        const SizedBox(height: 28),
        _primaryButton('Verify Code', _isLoading ? null : _verifyOtp),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _isLoading ? null : _sendOtp,
            child: Text("Didn't receive it? Resend",
                style: GoogleFonts.inter(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 12),
        _backToLogin(),
      ],
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 52, height: 60,
      child: TextFormField(
        controller: _otpCtrls[index],
        focusNode: _otpFocuses[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocuses[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocuses[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty) {
            // Auto-submit when last digit entered
            _verifyOtp();
          }
        },
      ),
    );
  }

  // ── Step 3: New Password ──
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set new password',
            style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('Choose a strong password for your account.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w300)),
        const SizedBox(height: 36),
        Text('New Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
          decoration: _inputDecoration('Min. 6 characters', Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Confirm Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
          decoration: _inputDecoration('Re-enter password', Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        if (_errorText.isNotEmpty) _errorWidget(),
        const SizedBox(height: 28),
        _primaryButton('Update Password', _isLoading ? null : _updatePassword),
      ],
    );
  }

  // ── Helpers ──

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _primaryButton(String label, VoidCallback? onPressed) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
    ),
  );

  Widget _errorWidget() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(_errorText,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
      ]),
    ),
  );

  Widget _backToLogin() => Center(
    child: GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Text('← Back to Sign In',
          style: GoogleFonts.inter(color: AppColors.accentBlue, fontSize: 14, fontWeight: FontWeight.w500)),
    ),
  );
}
