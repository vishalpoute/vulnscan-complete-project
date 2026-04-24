import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vulnscan/config/theme/colors.dart';

/// Animated cyber-themed splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _ringController;

  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Subtle grid background
            CustomPaint(
              painter: _GridPainter(),
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing rings + shield
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated rings
                        AnimatedBuilder(
                          animation: _ringAnim,
                          builder: (context, child) => CustomPaint(
                            painter: _RingPainter(_ringAnim.value),
                            size: const Size(160, 160),
                          ),
                        ),
                        // Shield icon
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgPrimary,
                              border: Border.all(
                                color: AppColors.accentGreen,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGreen.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.accentGreen,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App name
                  Text(
                    'VulnScan',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'AI-Powered Vulnerability Scanner',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Progress
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.bgSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing secure environment...',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle dot-grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault.withOpacity(0.3)
      ..strokeWidth = 1;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

/// Animated expanding rings painter
class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final p = ((progress + i * 0.33) % 1.0);
      final radius = maxR * p;
      final opacity = (1 - p) * 0.5;
      final paint = Paint()
        ..color = AppColors.accentGreen.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

