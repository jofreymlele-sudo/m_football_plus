import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'admin_screen.dart';
import 'main.dart' show MColors, AppLanguage;

// ============================================================================
// UKURASA WA WASIFU NA MIPANGILIO (PROFILE & SETTINGS SCREEN)
// ============================================================================
// 1. Usalama Kamili: Kitufe cha Admin Panel kinaonekana TU kama
//    FirebaseAuth.instance.currentUser?.email == 'jofreymlele@gmail.com'.
// 2. Kama mtumiaji ni shabiki wa kawaida (mfano shabiki@gmail.com) au mgeni,
//    kitufe cha Admin Panel kimefichwa kabisa.
// 3. Hakuna fomu ya nenosiri wala PIN (Password-free Google Sign-In).
// 4. Mtumiaji wa kawaida anaona tu 'Badilisha Lugha' na 'Kuhusu App'.
// ============================================================================

class ProfileScreen extends StatefulWidget {
  final bool isSwahili;
  final ValueChanged<AppLanguage>? onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.isSwahili,
    this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _isSwahili;
  bool _isLoading = false;
  final AuthService _auth = AuthService();

  // Mfumo wa Nambari ya Siri (OTP State)
  bool _isOtpStep = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _emailErrorMessage;
  String? _otpErrorMessage;
  String? _sentEmailAddress;
  String? _latestSentOtp;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _isSwahili = widget.isSwahili;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _resendCountdown = 0;
          });
        }
      }
    });
  }

  /// Pata barua pepe ya mtumiaji aliyepo sasa kupitia FirebaseAuth au AuthService
  String? _getActiveUserEmail() {
    try {
      final fbEmail = FirebaseAuth.instance.currentUser?.email;
      if (fbEmail != null && fbEmail.isNotEmpty) {
        return fbEmail;
      }
    } catch (_) {}
    final current = _auth.currentUser.email;
    return current.isNotEmpty ? current : null;
  }

  /// Kagua kama mtumiaji aliyepo ni Mmiliki halisi (jofreymlele@gmail.com pekee)
  bool _isOwner() {
    final email = _getActiveUserEmail();
    return email != null && email.trim().toLowerCase() == AuthService.ownerEmail.toLowerCase();
  }

  /// Kagua kama mtumiaji hajaingia kwenye akaunti (Mgeni)
  bool _isGuest() {
    final email = _getActiveUserEmail();
    return email == null || email.isEmpty || _auth.currentUser.uid == 'guest_user';
  }

  /// Jina la kuonyesha la mtumiaji
  String _getDisplayName() {
    if (_isOwner()) return 'Jofrey Mlele';
    if (_auth.currentUser.displayName.isNotEmpty) {
      return _auth.currentUser.displayName;
    }
    final email = _getActiveUserEmail();
    if (email != null && email.isNotEmpty) {
      final namePart = email.split('@').first;
      return namePart.isNotEmpty
          ? namePart[0].toUpperCase() + (namePart.length > 1 ? namePart.substring(1) : '')
          : 'Shabiki';
    }
    return _isSwahili ? 'Mgeni (Guest)' : 'Guest Fan';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser>(
      valueListenable: _auth.currentUserNotifier,
      builder: (context, user, _) {
        final bool isOwner = _isOwner();
        final bool isGuest = _isGuest();
        final String? userEmail = _getActiveUserEmail();
        final String displayName = _getDisplayName();

        return Scaffold(
          backgroundColor: MColors.background,
          appBar: AppBar(
            backgroundColor: MColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MColors.textWhite, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _isSwahili ? 'Wasifu & Mipangilio' : 'Profile & Settings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite,
              ),
            ),
            centerTitle: true,
            actions: [
              // Kitufe cha Haraka cha Lugha
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _toggleLanguage,
                  icon: const Icon(Icons.translate_rounded, color: MColors.scoresCyan, size: 18),
                  label: Text(
                    _isSwahili ? 'SW' : 'EN',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MColors.highlightsGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Kadi ya Utambulisho wa Mtumiaji (User Profile Card)
                _buildUserProfileCard(
                  displayName: displayName,
                  userEmail: userEmail,
                  isOwner: isOwner,
                  isGuest: isGuest,
                ),

                const SizedBox(height: 24),

                // 2. ==========================================================
                // KITUFE CHA ADMIN PANEL: KINAONEKANA TU KWA jofreymlele@gmail.com!
                // KAMA MTUMIAJI NI SHABIKI AU MGENI, KINAFICHWA KABISA 100%!
                // ==========================================================
                if (isOwner) ...[
                  _buildAdminPanelCard(),
                  const SizedBox(height: 24),
                ],

                // 3. Sehemu ya Mipangilio na Chaguzi za Mtumiaji (Settings Group)
                _buildSettingsCard(isGuest: isGuest),

                const SizedBox(height: 32),

                // 4. Sehemu ya Toleo / Footer
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_soccer_rounded, color: MColors.scoresCyan, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'M FOOTBALL PLUS',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: MColors.textWhite.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSwahili
                            ? 'v2.0 Premium • Usimamizi Salama wa Soka'
                            : 'v2.0 Premium • Secure Football Management',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: MColors.textWhite.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 1. Kadi ya Wasifu wa Mtumiaji ---
  Widget _buildUserProfileCard({
    required String displayName,
    required String? userEmail,
    required bool isOwner,
    required bool isGuest,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwner
              ? MColors.scoresCyan.withValues(alpha: 0.5)
              : MColors.scoresCyan.withValues(alpha: 0.15),
          width: isOwner ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isOwner
                ? MColors.scoresCyan.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MColors.background,
                  border: Border.all(
                    color: isOwner
                        ? MColors.scoresCyan
                        : (isGuest ? Colors.white24 : MColors.highlightsGold),
                    width: 2.2,
                  ),
                ),
                child: Icon(
                  isOwner
                      ? Icons.admin_panel_settings_rounded
                      : (isGuest ? Icons.person_outline_rounded : Icons.person_rounded),
                  color: isOwner
                      ? MColors.scoresCyan
                      : (isGuest ? MColors.textWhite.withValues(alpha: 0.5) : MColors.highlightsGold),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Taarifa za Mtumiaji
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MColors.textWhite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 18, color: MColors.scoresCyan),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userEmail ?? (_isSwahili ? 'Hujaunganisha Google' : 'No Google Account'),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: isOwner ? MColors.highlightsGold : MColors.textWhite.withValues(alpha: 0.6),
                        fontWeight: isOwner ? FontWeight.w700 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? MColors.scoresCyan.withValues(alpha: 0.15)
                            : (isGuest
                                ? Colors.white.withValues(alpha: 0.08)
                                : MColors.highlightsGold.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOwner
                            ? (_isSwahili ? 'Mmiliki wa App (Administrator)' : 'App Owner & Administrator')
                            : (isGuest
                                ? (_isSwahili ? 'Mgeni (Hujaingia)' : 'Guest Fan')
                                : (_isSwahili ? 'Shabiki wa Soka (Fan Account)' : 'Football Fan Account')),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOwner
                              ? MColors.scoresCyan
                              : (isGuest ? MColors.textWhite.withValues(alpha: 0.6) : MColors.highlightsGold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 14),

          // Sehemu ya Kuingia kwa Barua Pepe (Mgeni) au Kitufe cha Sign Out
          if (isGuest)
            _buildEmailSignInSection()
          else
            _buildSignOutButton(),
        ],
      ),
    );
  }

  // --- Mfumo wa Kuingia kwa Barua Pepe na Namba ya Siri (OTP) ---
  Widget _buildEmailSignInSection() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: _isOtpStep ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: _buildEmailStep(),
      secondChild: _buildOtpStep(),
    );
  }

  // Hatua ya 1: Weka Barua Pepe
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_outline_rounded, size: 16, color: MColors.scoresCyan),
            const SizedBox(width: 8),
            Text(
              _isSwahili ? 'Ingia kwa Barua Pepe (Email)' : 'Sign In with Email',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emailErrorMessage != null
                  ? Colors.redAccent
                  : MColors.scoresCyan.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.manrope(color: MColors.textWhite, fontSize: 13.5),
            onSubmitted: (_) => _handleSendOtp(),
            decoration: InputDecoration(
              hintText: _isSwahili
                  ? 'Weka barua pepe yako (mfano: jina@gmail.com)'
                  : 'Enter your email (e.g. name@gmail.com)',
              hintStyle: GoogleFonts.manrope(color: Colors.white38, fontSize: 12.5),
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: MColors.scoresCyan, size: 18),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                      onPressed: () {
                        _emailController.clear();
                        setState(() {
                          _emailErrorMessage = null;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onChanged: (_) {
              if (_emailErrorMessage != null) {
                setState(() {
                  _emailErrorMessage = null;
                });
              } else {
                setState(() {});
              }
            },
          ),
        ),
        if (_emailErrorMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _emailErrorMessage!,
              style: GoogleFonts.manrope(
                color: Colors.redAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.scoresCyan,
              foregroundColor: MColors.background,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MColors.background),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isSwahili ? 'TUMA NAMBA YA SIRI (OTP)' : 'SEND VERIFICATION CODE (OTP)',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Hatua ya 2: Weka Nambari ya Siri (OTP Verification Step)
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kichwa chenye kitufe cha kurudi nyuma
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _isOtpStep = false;
                  _otpErrorMessage = null;
                  _otpController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MColors.scoresCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: MColors.scoresCyan, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isSwahili ? 'Thibitisha Namba ya Siri (OTP)' : 'Verify One-Time Code (OTP)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kisanduku cha Barua Pepe Iliyotumwa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: MColors.scoresCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSwahili ? 'Nambari imetumwa kwa:' : 'Code sent to:',
                      style: GoogleFonts.manrope(fontSize: 10.5, color: MColors.textWhite.withValues(alpha: 0.6)),
                    ),
                    Text(
                      _sentEmailAddress ?? '',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isOtpStep = false;
                    _otpErrorMessage = null;
                    _otpController.clear();
                  });
                },
                child: Text(
                  _isSwahili ? 'Badili' : 'Change',
                  style: GoogleFonts.manrope(color: MColors.scoresCyan, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Kidokezo cha Namba ya Siri (OTP Code Notification Card)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: MColors.scoresCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MColors.scoresCyan.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: MColors.highlightsGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.manrope(fontSize: 12, color: MColors.textWhite),
                    children: [
                      TextSpan(
                        text: _isSwahili ? 'Namba yako ya siri ni: ' : 'Your OTP code is: ',
                      ),
                      TextSpan(
                        text: _latestSentOtp ?? '',
                        style: GoogleFonts.outfit(
                          color: MColors.scoresCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Kisanduku cha Kuandika OTP (Tarakimu 6)
        Container(
          decoration: BoxDecoration(
            color: MColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _otpErrorMessage != null
                  ? Colors.redAccent
                  : MColors.scoresCyan.withValues(alpha: 0.4),
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: MColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            onSubmitted: (_) => _handleVerifyOtp(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white24,
                fontSize: 20,
                letterSpacing: 8,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) {
              if (_otpErrorMessage != null) {
                setState(() {
                  _otpErrorMessage = null;
                });
              } else {
                setState(() {});
              }
              // Ikishafika tarakimu 6, thibitisha moja kwa moja
              if (val.trim().length == 6) {
                _handleVerifyOtp();
              }
            },
          ),
        ),
        if (_otpErrorMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _otpErrorMessage!,
              style: GoogleFonts.manrope(
                color: Colors.redAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Kitufe cha Kuthibitisha na Kuingia
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.scoresCyan,
              foregroundColor: MColors.background,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MColors.background),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(Icons.verified_user_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isSwahili ? 'THIBITISHA NA UINGIE' : 'VERIFY & SIGN IN',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Countdown Timer & Kitufe cha Tuma Tena
        Center(
          child: _resendCountdown > 0
              ? Text(
                  _isSwahili
                      ? 'Tuma tena namba ya siri baada ya ${_resendCountdown}s'
                      : 'Resend code in ${_resendCountdown}s',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: MColors.textWhite.withValues(alpha: 0.5),
                  ),
                )
              : TextButton.icon(
                  onPressed: _handleSendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: MColors.scoresCyan),
                  label: Text(
                    _isSwahili ? 'Tuma Tena Namba ya Siri' : 'Resend Verification Code',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: MColors.scoresCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // --- Kitufe cha Kutoka Kwenye Akaunti ---
  Widget _buildSignOutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await _auth.signOut();
          _emailController.clear();
          _otpController.clear();
          _resendTimer?.cancel();
          if (mounted) {
            setState(() {
              _isOtpStep = false;
              _emailErrorMessage = null;
              _otpErrorMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: MColors.surface,
                content: Text(
                  _isSwahili ? 'Umetoka kwenye akaunti.' : 'Signed out successfully.',
                  style: GoogleFonts.manrope(color: MColors.textWhite),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                _isSwahili ? 'Toka kwenye Akaunti (Sign Out)' : 'Sign Out of Account',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. Kadi ya Paneli ya Msimamizi (Inaonekana TU kwa Mmiliki) ---
  Widget _buildAdminPanelCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MColors.surface,
            MColors.scoresCyan.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MColors.scoresCyan, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: MColors.scoresCyan.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminScreen(isSwahili: _isSwahili),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MColors.scoresCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: MColors.scoresCyan, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isSwahili ? 'Paneli ya Msimamizi' : 'Admin Panel',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: MColors.textWhite,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MColors.highlightsGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OWNER ONLY',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: MColors.highlightsGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isSwahili
                            ? 'Dhibiti Habari, Wachambuzi, na Kura za Mashabiki'
                            : 'Control News, Expert Analysis & Fan Polls',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          color: MColors.textWhite.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: MColors.scoresCyan, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Kadi ya Mipangilio (Inayoonekana kwa Kila Mtu) ---
  Widget _buildSettingsCard({required bool isGuest}) {
    return Material(
      color: MColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MColors.scoresCyan.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Badilisha Lugha
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MColors.scoresCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.translate_rounded, color: MColors.scoresCyan, size: 20),
            ),
            title: Text(
              _isSwahili ? 'Badilisha Lugha' : 'Switch Language',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite,
              ),
            ),
            subtitle: Text(
              _isSwahili ? 'Kiswahili 🇹🇿 / English 🇬🇧' : 'English 🇬🇧 / Swahili 🇹🇿',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: MColors.highlightsGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isSwahili ? 'Kiswahili 🇹🇿' : 'English 🇬🇧',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: MColors.highlightsGold,
                ),
              ),
            ),
            onTap: _toggleLanguage,
          ),

          const Divider(color: Color(0x1AFFFFFF), height: 1),

          // Kuhusu App (About App)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MColors.scoresCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: MColors.scoresCyan, size: 20),
            ),
            title: Text(
              _isSwahili ? 'Kuhusu App' : 'About App',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MColors.textWhite,
              ),
            ),
            subtitle: Text(
              'M Football Plus v2.0 Premium',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: MColors.textWhite.withValues(alpha: 0.5),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: MColors.textMuted, size: 14),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  // --- Kubadilisha Lugha ---
  void _toggleLanguage() {
    setState(() {
      _isSwahili = !_isSwahili;
    });
    final newLang = _isSwahili ? AppLanguage.swahili : AppLanguage.english;
    if (widget.onLanguageChanged != null) {
      widget.onLanguageChanged!(newLang);
    }
  }

  // --- Tuma Nambari ya Siri (Send OTP) ---
  void _handleSendOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _emailErrorMessage = _isSwahili
            ? 'Tafadhali weka barua pepe sahihi (mfano: mtumiaji@gmail.com)'
            : 'Please enter a valid email address (e.g. user@gmail.com)';
      });
      return;
    }

    final parts = email.split('@');
    if (parts.length != 2 || parts[1].trim().length < 4 || !parts[1].contains('.')) {
      setState(() {
        _emailErrorMessage = _isSwahili
            ? 'Muundo wa barua pepe siyo halisi. Tafadhali kagua tena.'
            : 'Invalid email domain format. Please check again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailErrorMessage = null;
      _otpErrorMessage = null;
    });

    final otp = _auth.sendOtp(email);
    _sentEmailAddress = email;
    _latestSentOtp = otp;
    _startResendTimer();

    setState(() {
      _isLoading = false;
      _isOtpStep = true;
    });

    _showSuccessSnackBar(
      _isSwahili
          ? 'Namba ya siri (OTP) imetumwa kwenda $email'
          : 'Verification code (OTP) sent to $email',
    );
  }

  // --- Thibitisha Nambari ya Siri (Verify OTP & Sign In) ---
  void _handleVerifyOtp() {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty || enteredOtp.length < 6) {
      setState(() {
        _otpErrorMessage = _isSwahili
            ? 'Tafadhali weka nambari kamili ya tarakimu 6'
            : 'Please enter the complete 6-digit verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _otpErrorMessage = null;
    });

    final bool isVerified = _auth.verifyOtp(enteredOtp);
    setState(() {
      _isLoading = false;
    });

    if (!isVerified) {
      setState(() {
        _otpErrorMessage = _isSwahili
            ? 'Nambari ya siri siyo sahihi! Tafadhali hakiki namba uliyopewa.'
            : 'Invalid verification code! Please check the code provided.';
      });
      return;
    }

    // Uthibitishaji umekubaliwa 100%!
    _emailController.clear();
    _otpController.clear();
    _resendTimer?.cancel();
    _isOtpStep = false;
    FocusScope.of(context).unfocus();

    final isOwner = _isOwner();
    setState(() {});
    _showSuccessSnackBar(
      isOwner
          ? (_isSwahili
              ? 'Karibu Mmiliki Jofrey Mlele! Paneli ya Msimamizi imefunguka.'
              : 'Welcome Owner Jofrey Mlele! Admin Panel unlocked.')
          : (_isSwahili
              ? 'Umeingia kikamilifu kwenye akaunti ya Shabiki!'
              : 'Signed in successfully as Football Fan!'),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: MColors.scoresCyan),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: MColors.scoresCyan, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: MColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: MColors.scoresCyan, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.sports_soccer_rounded, color: MColors.scoresCyan, size: 24),
              const SizedBox(width: 10),
              Text(
                'M Football Plus',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MColors.textWhite,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSwahili
                    ? 'M Football Plus ni jukwaa nambari moja la michezo nchini Tanzania na Duniani linalokuletea matokeo mubashara, msimamo wa ligi, uchambuzi wa kitaalam, na habari motomoto za soka.'
                    : 'M Football Plus is the premier football platform bringing you live scores, standings, expert analysis, and trending football news from Tanzania and worldwide.',
                style: GoogleFonts.manrope(fontSize: 12.5, color: MColors.textWhite.withValues(alpha: 0.8), height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSwahili ? 'Toleo la Mfumo:' : 'System Version:',
                      style: GoogleFonts.manrope(fontSize: 11, color: MColors.textWhite.withValues(alpha: 0.6)),
                    ),
                    Text(
                      'v2.0 Premium',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: MColors.highlightsGold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                _isSwahili ? 'Funga' : 'Close',
                style: GoogleFonts.outfit(color: MColors.scoresCyan, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
