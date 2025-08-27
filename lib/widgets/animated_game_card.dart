import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_model.dart';
import '../utils/theme.dart';

class AnimatedGameCard extends StatefulWidget {
  final GameModel game;
  final VoidCallback onTap;
  final bool isSelected;

  const AnimatedGameCard({
    Key? key,
    required this.game,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<AnimatedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.01,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateY(_rotationAnimation.value)
                ..scale(_scaleAnimation.value),
              child: AnimatedContainer(
                duration: AppTheme.mediumAnimation,
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.all(_isHovered ? 4 : 8),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            theme.cardColor,
                            theme.cardColor.withOpacity(0.95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(_isHovered ? 20 : 16),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryColor
                        : _isHovered
                            ? AppTheme.primaryColor.withOpacity(0.3)
                            : Colors.transparent,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ]
                      : AppTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isHovered ? 20 : 16),
                  child: Stack(
                    children: [
                      // Game Image with parallax effect
                      AnimatedContainer(
                        duration: AppTheme.mediumAnimation,
                        height: _isHovered ? 185 : 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.8),
                              AppTheme.secondaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.game.coverImage.isNotEmpty)
                              AnimatedScale(
                                scale: _isHovered ? 1.1 : 1.0,
                                duration: AppTheme.longAnimation,
                                curve: Curves.easeOut,
                                child: CachedNetworkImage(
                                  imageUrl: widget.game.coverImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => _buildPlaceholder(),
                                  errorWidget: (context, url, error) => _buildPlaceholder(),
                                ),
                              )
                            else
                              _buildPlaceholder(),
                            
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withOpacity(isDark ? 0.95 : 0.98),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.game.title,
                                style: AppTheme.headlineSmall.copyWith(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Game info chips
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.people_outline,
                                    '${widget.game.minPlayers}-${widget.game.maxPlayers}',
                                    AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    Icons.timer_outlined,
                                    '${widget.game.playTime}m',
                                    AppTheme.secondaryColor,
                                  ),
                                ],
                              ),

                              // BGG Rank badge
                              if (widget.game.bggRank != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.heroGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'BGG #${widget.game.bggRank}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Status indicator
                              if (!widget.game.isAvailable) ...[
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: AppTheme.shortAnimation,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.game.currentBorrowerId != null
                                        ? 'Loaned'
                                        : 'Unavailable',
                                    style: const TextStyle(
                                      color: AppTheme.warningColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Hover overlay
                      if (_isHovered)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: AppTheme.shortAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.casino,
          size: 60,
          color: Colors.white54,
        ),
      ),
    );
  }
}