import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/theme.dart';
import '../utils/currency_formatter.dart';

/// Modern glassmorphic card with backdrop blur effect
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.color = Colors.white,
    this.padding,
    this.margin,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Enhanced Glassmorphic Card with premium effects
class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool showShimmer;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.blur = 25.0,
    this.opacity = 0.15,
    this.color = Colors.white,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.gradientColors,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors!,
                    )
                  : null,
              color: gradientColors == null ? color.withOpacity(opacity) : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (showShimmer) {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Animated Glassmorphic Container with hover effects
class AnimatedGlassContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final EdgeInsets? padding;

  const AnimatedGlassContainer({
    super.key,
    required this.child,
    this.onTap,
    this.width = double.infinity,
    this.height = 120,
    this.padding,
  });

  @override
  State<AnimatedGlassContainer> createState() => _AnimatedGlassContainerState();
}

class _AnimatedGlassContainerState extends State<AnimatedGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                      0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1 + (0.05 * _glowAnimation.value)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2 + (0.1 * _glowAnimation.value)),
                        width: 1.5,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced expense card with modern design and animations
class ModernExpenseCard extends StatefulWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index;

  const ModernExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    required this.index,
  });

  @override
  State<ModernExpenseCard> createState() => _ModernExpenseCardState();
}

class _ModernExpenseCardState extends State<ModernExpenseCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppColors.fastAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.expense['amount'] as double;
    final title = widget.expense['title'] as String;
    final category = widget.expense['category'] as String;
    final date = DateTime.parse(widget.expense['date'] as String);
    
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
            widget.onTap();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          },
          child: AnimatedContainer(
            duration: AppColors.fastAnimation,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : AppColors.cardShadow,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Category icon with modern styling
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(category),
                          _getCategoryColor(category).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(category).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Expense details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCategory(category),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCategoryColor(category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount with modern styling
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${CurrencyFormatter.formatWithCurrency(amount)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.onEdit != null || widget.onDelete != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onEdit != null)
                              _ModernIconButton(
                                icon: Icons.edit_outlined,
                                onTap: widget.onEdit!,
                                color: AppColors.primary,
                              ),
                            if (widget.onEdit != null && widget.onDelete != null)
                              const SizedBox(width: 8),
                            if (widget.onDelete != null)
                              _ModernIconButton(
                                icon: Icons.delete_outline,
                                onTap: widget.onDelete!,
                                color: Colors.red[400]!,
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'food':
        return 'Alimentation';
      case 'transportation':
        return 'Transport';
      case 'entertainment':
        return 'Divertissement';
      case 'shopping':
        return 'Shopping';
      case 'health':
        return 'Santé';
      case 'education':
        return 'Éducation';
      case 'other':
        return 'Autre';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }
}

/// Modern icon button with hover and press effects
class _ModernIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ModernIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<_ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<_ModernIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppColors.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppColors.fastAnimation,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.color.withOpacity(_isPressed ? 0.2 : 0.1),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Modern bottom navigation bar
class ModernBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const ModernBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: AppColors.elevatedShadow,
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildNavItem(context, index, item);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, BottomNavItem item) {
    final isSelected = index == currentIndex;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: AppColors.normalAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
            ? AppColors.primary.withOpacity(0.15) 
            : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppColors.normalAnimation,
              child: Icon(
                item.icon,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppColors.normalAnimation,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

/// Modern floating action button with sub-actions
class ModernFloatingActionButton extends StatefulWidget {
  final List<FABAction> actions;

  const ModernFloatingActionButton({
    super.key,
    required this.actions,
  });

  @override
  State<ModernFloatingActionButton> createState() => _ModernFloatingActionButtonState();
}

class _ModernFloatingActionButtonState extends State<ModernFloatingActionButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppColors.normalAnimation,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.75)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Sub FABs
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -(70.0 * (index + 1)) * _scaleAnimation.value,
                  ),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: action.color ?? Theme.of(context).primaryColor,
                    heroTag: action.label,
                    elevation: 8,
                    onPressed: () {
                      _toggle();
                      action.onPressed();
                    },
                    child: Icon(action.icon, color: Colors.white),
                  ),
                ),
              );
            },
          );
        }),
        
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: FloatingActionButton(
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 12,
                onPressed: _toggle,
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}

class FABAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  FABAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });
}

/// Shimmer loading effect for better UX
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _animation.value, -0.3),
              end: Alignment(1.0 + _animation.value, 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Modern button with loading and press effects
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isPrimary;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isPrimary = true,
    this.fullWidth = false,
    this.padding,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _onTapDown : null,
            onTapUp: widget.onPressed != null ? _onTapUp : null,
            onTapCancel: widget.onPressed != null ? _onTapCancel : null,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              decoration: BoxDecoration(
                gradient: widget.isPrimary
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: widget.isPrimary ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: widget.isPrimary
                    ? null
                    : Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                boxShadow: widget.isPrimary && !widget.isLoading
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              padding: widget.padding ?? 
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isPrimary 
                          ? Colors.white 
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isPrimary 
                            ? Colors.white 
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}