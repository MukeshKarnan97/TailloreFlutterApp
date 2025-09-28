import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

/// AnimatedSplashScreen - Beautiful animated splash screen for Tailor App
/// 
/// Features:
/// - Fade-in logo animation
/// - Shimmer loading effect
/// - Brand colors and gradients
/// - Smooth transitions
/// - Loading progress indicator
/// - Configuration-based app name
/// - Responsive design
/// - Performance optimized animations
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final Duration splashDuration;
  
  const AnimatedSplashScreen({
    Key? key,
    this.onAnimationComplete,
    this.splashDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  static const String _className = 'AnimatedSplashScreen';
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _progressController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _progressAnimation;
  
  Timer? _splashTimer;
  
  @override
  void initState() {
    super.initState();
    Logger.startTrace(_className, 'initState');
    
    _initializeAnimations();
    _startSplashSequence();
    
    Logger.endTrace(_className, 'initState');
  }

  /// Initialize all animation controllers and animations
  void _initializeAnimations() {
    Logger.debug(_className, 'Initializing splash screen animations');
    
    // Fade animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Shimmer animation for loading effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Progress animation
    _progressController = AnimationController(
      duration: widget.splashDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  /// Start the splash screen animation sequence
  void _startSplashSequence() {
    Logger.info(_className, 'Starting splash screen sequence');
    
    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        Logger.debug(_className, 'Started fade animation');
      }
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
        Logger.debug(_className, 'Started scale animation');
      }
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _shimmerController.repeat();
        _progressController.forward();
        Logger.debug(_className, 'Started shimmer and progress animations');
      }
    });

    // Complete splash after duration
    _splashTimer = Timer(widget.splashDuration, () {
      if (mounted) {
        _completeSplash();
      }
    });
  }

  /// Complete splash screen and trigger callback
  void _completeSplash() {
    Logger.info(_className, 'Splash screen animation completed');
    
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    Logger.startTrace(_className, 'dispose');
    
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    _splashTimer?.cancel();
    
    Logger.endTrace(_className, 'dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFF6B73FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            _buildBackgroundPattern(),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  _buildAnimatedLogo(screenSize),
                  
                  const SizedBox(height: 40),
                  
                  // App name with shimmer effect
                  _buildAnimatedAppName(),
                  
                  const SizedBox(height: 20),
                  
                  // Tagline
                  _buildTagline(),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),
            
            // Progress bar at bottom
            _buildProgressBar(),
            
            // Version info
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  /// Build background pattern overlay
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: BackgroundPatternPainter(
              animation: _shimmerAnimation.value,
            ),
          );
        },
      ),
    );
  }

  /// Build animated logo
  Widget _buildAnimatedLogo(Size screenSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: screenSize.width * 0.3,
              height: screenSize.width * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/splash_logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    Logger.warning(_className, 'Logo image failed to load: $error');
                    return _buildFallbackLogo();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build fallback logo if image fails to load
  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade300,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          Icons.content_cut,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build animated app name with shimmer effect
  Widget _buildAnimatedAppName() {
    return FadeInUp(
      delay: const Duration(milliseconds: 1000),
      duration: const Duration(milliseconds: 800),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.white70,
                  Colors.white,
                  Colors.white70,
                ],
                stops: [
                  0.0,
                  _shimmerAnimation.value.clamp(0.0, 1.0),
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: Text(
              AppConfig.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  /// Build tagline
  Widget _buildTagline() {
    return FadeInUp(
      delay: const Duration(milliseconds: 1300),
      duration: const Duration(milliseconds: 600),
      child: Text(
        'Crafting Perfect Fits',
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.8),
          letterSpacing: 1.0,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return FadeInUp(
      delay: const Duration(milliseconds: 1600),
      duration: const Duration(milliseconds: 400),
      child: Column(
        children: [
          // Animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  final delay = index * 0.3;
                  final animValue = (_shimmerController.value + delay) % 1.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          0.3 + (0.7 * (1 - (animValue - 0.5).abs() * 2).clamp(0.0, 1.0))
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress bar
  Widget _buildProgressBar() {
    return Positioned(
      bottom: 50,
      left: 40,
      right: 40,
      child: FadeInUp(
        delay: const Duration(milliseconds: 1800),
        duration: const Duration(milliseconds: 400),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  minHeight: 3,
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build version info
  Widget _buildVersionInfo() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FadeIn(
        delay: const Duration(milliseconds: 2000),
        duration: const Duration(milliseconds: 400),
        child: Text(
          'v${AppConfig.appVersion}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  final double animation;
  
  BackgroundPatternPainter({required this.animation});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final spacing = 50.0;
    final offset = animation * spacing;
    
    // Draw diagonal lines
    for (double i = -size.width; i < size.width + size.height; i += spacing) {
      final startX = i + offset;
      final startY = 0.0;
      final endX = i + size.height + offset;
      final endY = size.height;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
    
    // Draw circles
    for (int i = 0; i < 5; i++) {
      final x = (size.width / 6) * (i + 1);
      final y = size.height * 0.3 + (animation * 20);
      final radius = 2.0 + (animation.abs() * 3);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(0.1),
      );
    }
  }
  
  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}