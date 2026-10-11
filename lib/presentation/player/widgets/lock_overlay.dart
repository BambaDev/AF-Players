import 'package:flutter/material.dart';

class LockOverlay extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onToggleLock;

  const LockOverlay({
    super.key,
    required this.isLocked,
    required this.onToggleLock,
  });

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay>
    with SingleTickerProviderStateMixin {
  bool _buttonVisible = true;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    if (widget.isLocked) {
      _fadeController.value = 1.0;
      _scheduleHide();
    }
  }

  @override
  void didUpdateWidget(LockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocked && !oldWidget.isLocked) {
      _showButton();
    }
  }

  void _showButton() {
    setState(() => _buttonVisible = true);
    _fadeController.forward();
    _scheduleHide();
  }

  void _scheduleHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.isLocked) {
        _fadeController.reverse().then((_) {
          if (mounted) setState(() => _buttonVisible = false);
        });
      }
    });
  }

  void _onTapAnywhere() {
    if (!_buttonVisible) {
      _showButton();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLocked) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTapAnywhere,
      child: SizedBox.expand(
        child: Stack(
          children: [
            if (_buttonVisible)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: widget.onToggleLock,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Deverrouiller',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
