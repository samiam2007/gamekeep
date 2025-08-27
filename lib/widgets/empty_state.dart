import 'package:flutter/material.dart';
import '../utils/theme.dart';

class EmptyState extends StatefulWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    Key? key,
    required this.type,
    this.title,
    this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    ));

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildIllustration(config),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        widget.title ?? config.title,
                        style: AppTheme.headlineMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle ?? config.subtitle,
                        style: AppTheme.bodyLarge.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.action != null) ...[
                        const SizedBox(height: 24),
                        widget.action!,
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(EmptyStateConfig config) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.primaryColor.withOpacity(0.1),
            config.secondaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: config.primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          // Inner ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: config.secondaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.primaryColor, config.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              config.icon,
              size: 50,
              color: Colors.white,
            ),
          ),
          // Decorative dots
          ...List.generate(8, (index) {
            final angle = (index * 45) * (3.14159 / 180);
            return Transform.translate(
              offset: Offset(
                90 * (angle.toString().contains('1.5') ? 1.4 : 1) * 
                    (angle.toString().contains('3.1') ? -1 : 1),
                90 * (angle.toString().contains('0.7') ? 1.4 : 1) * 
                    (angle.toString().contains('4.7') ? -1 : 1),
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: config.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  EmptyStateConfig _getConfig() {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return EmptyStateConfig(
          icon: Icons.casino,
          title: 'No Games Yet',
          subtitle: 'Start building your collection by adding your first game!',
          primaryColor: AppTheme.primaryColor,
          secondaryColor: AppTheme.secondaryColor,
        );
      case EmptyStateType.noFriends:
        return EmptyStateConfig(
          icon: Icons.people_outline,
          title: 'No Friends Added',
          subtitle: 'Connect with friends to share and borrow games',
          primaryColor: AppTheme.secondaryColor,
          secondaryColor: AppTheme.accentColor,
        );
      case EmptyStateType.noResults:
        return EmptyStateConfig(
          icon: Icons.search_off,
          title: 'No Results Found',
          subtitle: 'Try adjusting your search or filters',
          primaryColor: AppTheme.warningColor,
          secondaryColor: AppTheme.primaryColor,
        );
      case EmptyStateType.noHistory:
        return EmptyStateConfig(
          icon: Icons.history,
          title: 'No Play History',
          subtitle: 'Start logging your game sessions to track your plays',
          primaryColor: AppTheme.successColor,
          secondaryColor: AppTheme.secondaryColor,
        );
      case EmptyStateType.noLoans:
        return EmptyStateConfig(
          icon: Icons.swap_horiz,
          title: 'No Active Loans',
          subtitle: 'Your games are all accounted for',
          primaryColor: AppTheme.primaryColor,
          secondaryColor: AppTheme.successColor,
        );
      case EmptyStateType.error:
        return EmptyStateConfig(
          icon: Icons.error_outline,
          title: 'Something Went Wrong',
          subtitle: 'Please try again or check your connection',
          primaryColor: AppTheme.errorColor,
          secondaryColor: AppTheme.warningColor,
        );
      case EmptyStateType.offline:
        return EmptyStateConfig(
          icon: Icons.cloud_off,
          title: 'You\'re Offline',
          subtitle: 'Check your internet connection and try again',
          primaryColor: Colors.grey,
          secondaryColor: Colors.blueGrey,
        );
      case EmptyStateType.comingSoon:
        return EmptyStateConfig(
          icon: Icons.rocket_launch,
          title: 'Coming Soon',
          subtitle: 'This feature is under development',
          primaryColor: AppTheme.primaryLight,
          secondaryColor: AppTheme.accentColor,
        );
    }
  }
}

enum EmptyStateType {
  noGames,
  noFriends,
  noResults,
  noHistory,
  noLoans,
  error,
  offline,
  comingSoon,
}

class EmptyStateConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;

  const EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class AnimatedEmptyState extends StatefulWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Widget? action;

  const AnimatedEmptyState({
    Key? key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _illustrationController;
  late AnimationController _textController;
  late Animation<double> _illustrationScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    _illustrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _illustrationScale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _illustrationController,
      curve: Curves.easeInOut,
    ));

    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _illustrationController.repeat(reverse: true);
    _textController.forward();
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _illustrationScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _illustrationScale.value,
                  child: widget.illustration,
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          style: AppTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subtitle,
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.action != null) ...[
                          const SizedBox(height: 24),
                          widget.action!,
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}