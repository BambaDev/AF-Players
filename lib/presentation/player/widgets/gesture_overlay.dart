import 'package:flutter/material.dart';
import 'seek_indicator.dart';

class GestureOverlay extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final ValueChanged<double> onVolumeChange;
  final ValueChanged<double> onBrightnessChange;
  final double currentVolume;
  final bool isLocked;
  final int seekSeconds;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const GestureOverlay({
    super.key,
    required this.onTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onVolumeChange,
    required this.onBrightnessChange,
    required this.currentVolume,
    this.isLocked = false,
    this.seekSeconds = 10,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
  Offset _doubleTapPosition = Offset.zero;
  bool _showSeekForward = false;
  bool _showSeekBackward = false;

  bool _isDragging = false;
  bool _isDragRight = false;
  double _dragIndicatorValue = 0.0;
  double _dragStartValue = 0.0;
  bool _panDirectionDecided = false;
  bool _isPanVertical = false;
  double _panStartX = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTapDown: (details) {
            _doubleTapPosition = details.localPosition;
          },
          onDoubleTap: _handleDoubleTap,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: const SizedBox.expand(),
        ),
        _buildSeekIndicators(),
        if (_isDragging) _buildDragIndicator(),
      ],
    );
  }

  void _handleDoubleTap() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isRight = _doubleTapPosition.dx > screenWidth / 2;

    if (isRight) {
      setState(() => _showSeekForward = true);
      widget.onDoubleTapRight();
    } else {
      setState(() => _showSeekBackward = true);
      widget.onDoubleTapLeft();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _panDirectionDecided = false;
    _isPanVertical = false;
    _panStartX = details.localPosition.dx;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_panDirectionDecided) {
      final dx = (details.localPosition.dx - _panStartX).abs();
      final dy = details.delta.dy.abs();
      if (dx > 20) {
        _panDirectionDecided = true;
        _isPanVertical = false;
        return;
      }
      if (dy > 5) {
        _panDirectionDecided = true;
        _isPanVertical = true;
        final screenWidth = MediaQuery.of(context).size.width;
        _isDragRight = _panStartX > screenWidth / 2;
        _dragStartValue = _isDragRight ? widget.currentVolume : 0.5;
        _dragIndicatorValue = _dragStartValue;
        setState(() => _isDragging = true);
      }
      return;
    }

    if (_isDragging && _isPanVertical) {
      final screenHeight = MediaQuery.of(context).size.height;
      final delta = -details.delta.dy / (screenHeight * 0.7);
      _dragIndicatorValue = (_dragIndicatorValue + delta).clamp(0.0, 1.0);
      setState(() {});
      if (_isDragRight) {
        widget.onVolumeChange(_dragIndicatorValue);
      } else {
        widget.onBrightnessChange(_dragIndicatorValue);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _panDirectionDecided = false;
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity < -300 && widget.onSwipeLeft != null) {
      widget.onSwipeLeft!();
    } else if (velocity > 300 && widget.onSwipeRight != null) {
      widget.onSwipeRight!();
    }
    _panDirectionDecided = false;
  }

  Widget _buildSeekIndicators() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width / 2,
          child: Center(
            child: SeekIndicator(
              visible: _showSeekBackward,
              isForward: false,
              seconds: widget.seekSeconds,
              onAnimationComplete: () {
                if (mounted) setState(() => _showSeekBackward = false);
              },
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width / 2,
          child: Center(
            child: SeekIndicator(
              visible: _showSeekForward,
              isForward: true,
              seconds: widget.seekSeconds,
              onAnimationComplete: () {
                if (mounted) setState(() => _showSeekForward = false);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDragIndicator() {
    final icon = _isDragRight
        ? (_dragIndicatorValue == 0
            ? Icons.volume_off
            : _dragIndicatorValue < 0.5
                ? Icons.volume_down
                : Icons.volume_up)
        : (_dragIndicatorValue < 0.33
            ? Icons.brightness_low
            : _dragIndicatorValue < 0.66
                ? Icons.brightness_medium
                : Icons.brightness_high);

    final percentage = (_dragIndicatorValue * 100).round();

    return Center(
      child: Container(
        width: 48,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: RotatedBox(
                quarterTurns: -1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _dragIndicatorValue,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
