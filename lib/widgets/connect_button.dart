// ============================================================
// widgets/connect_button.dart
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vpn_models.dart';

class ConnectButton extends StatefulWidget {
  final VpnStatus status;
  final VoidCallback onTap;

  const ConnectButton({super.key, required this.status, required this.onTap});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ConnectButton old) {
    super.didUpdateWidget(old);
    if (widget.status == VpnStatus.connecting ||
        widget.status == VpnStatus.disconnecting) {
      _rotateCtrl.repeat();
    } else {
      _rotateCtrl.stop();
      _rotateCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  bool get _isConnected => widget.status == VpnStatus.connected;
  bool get _isBusy =>
      widget.status == VpnStatus.connecting ||
      widget.status == VpnStatus.disconnecting;

  Color get _primaryColor {
    if (_isConnected) return const Color(0xFF00E5FF);
    if (widget.status == VpnStatus.error) return const Color(0xFFEF4444);
    return const Color(0xFF7B61FF);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isBusy ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _rotateCtrl]),
        builder: (_, __) {
          final scale = _isConnected ? _pulseAnim.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Middle ring
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Rotating arc (when connecting)
                  if (_isBusy)
                    Transform.rotate(
                      angle: _rotateCtrl.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(170, 170),
                        painter: _ArcPainter(color: _primaryColor),
                      ),
                    ),

                  // Main button circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withOpacity(0.08),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isConnected
                                ? Icons.lock
                                : _isBusy
                                    ? Icons.sync
                                    : Icons.power_settings_new,
                            key: ValueKey(widget.status),
                            color: _primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isConnected
                              ? 'ON'
                              : _isBusy
                                  ? '...'
                                  : 'OFF',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
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
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 1,
      ),
      0,
      math.pi * 1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
