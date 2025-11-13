import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stitch_flutter/services/weather_service.dart';

/// 天气图标组件库
/// 根据设计示例实现SVG风格的图标
class WeatherIcon extends StatelessWidget {
  final WeatherType type;
  final double size;
  final Color? color;

  const WeatherIcon({
    super.key,
    required this.type,
    this.size = 48.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _getWeatherPainter(type, color),
      ),
    );
  }

  CustomPainter _getWeatherPainter(WeatherType type, Color? color) {
    switch (type) {
      case WeatherType.sunny:
        return _SunnyIconPainter(color: color ?? const Color(0xFFFBBF24));
      case WeatherType.cloudy:
        return _CloudyIconPainter(color: color ?? const Color(0xFF00C2FF));
      case WeatherType.rainy:
        return _RainyIconPainter(color: color ?? const Color(0xFF00C2FF));
      case WeatherType.snowy:
        return _SnowyIconPainter(color: color ?? const Color(0xFF00C2FF));
      case WeatherType.foggy:
        return _CloudyIconPainter(color: color ?? Colors.grey);
    }
  }
}

/// 晴天图标画笔
class _SunnyIconPainter extends CustomPainter {
  final Color color;

  _SunnyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.18;

    // 中心圆
    canvas.drawCircle(center, radius, paint);

    // 8条射线
    final rayLength = size.width * 0.12;
    final innerRadius = radius + size.width * 0.04;
    final outerRadius = innerRadius + rayLength;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final x1 = center.dx + innerRadius * math.cos(angle);
      final y1 = center.dy + innerRadius * math.sin(angle);
      final x2 = center.dx + outerRadius * math.cos(angle);
      final y2 = center.dy + outerRadius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 多云图标画笔
class _CloudyIconPainter extends CustomPainter {
  final Color color;

  _CloudyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // 云朵路径（基于设计示例的SVG路径）
    final w = size.width;
    final h = size.height;
    
    path.moveTo(w * 0.735, h * 0.615);
    path.cubicTo(w * 0.825, h * 0.615, w * 0.9, h * 0.54, w * 0.9, h * 0.45);
    path.cubicTo(w * 0.9, h * 0.36, w * 0.825, h * 0.285, w * 0.735, h * 0.285);
    path.cubicTo(w * 0.735, h * 0.195, w * 0.66, h * 0.12, w * 0.57, h * 0.12);
    path.cubicTo(w * 0.495, h * 0.12, w * 0.435, h * 0.18, w * 0.42, h * 0.255);
    path.cubicTo(w * 0.405, h * 0.24, w * 0.375, h * 0.225, w * 0.345, h * 0.225);
    path.cubicTo(w * 0.285, h * 0.225, w * 0.24, h * 0.27, w * 0.24, h * 0.33);
    path.cubicTo(w * 0.24, h * 0.3375, w * 0.2415, h * 0.345, w * 0.243, h * 0.3525);
    path.cubicTo(w * 0.1845, h * 0.3705, w * 0.15, h * 0.4245, w * 0.15, h * 0.4875);
    path.cubicTo(w * 0.15, h * 0.5565, w * 0.2085, h * 0.615, w * 0.2775, h * 0.615);
    path.lineTo(w * 0.735, h * 0.615);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 雨天图标画笔
class _RainyIconPainter extends CustomPainter {
  final Color color;

  _RainyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 先画云
    _CloudyIconPainter(color: color).paint(canvas, size);

    // 画雨滴
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    
    // 两个圆形雨滴
    canvas.drawCircle(Offset(w * 0.4, h * 0.78), w * 0.04, paint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.78), w * 0.04, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 雪天图标画笔
class _SnowyIconPainter extends CustomPainter {
  final Color color;

  _SnowyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 先画云
    _CloudyIconPainter(color: color).paint(canvas, size);

    // 画雪花
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    
    // 左边雪花
    _drawSnowflake(canvas, Offset(w * 0.4, h * 0.79), w * 0.07, paint);
    
    // 右边雪花
    _drawSnowflake(canvas, Offset(w * 0.6, h * 0.79), w * 0.07, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, double size, Paint paint) {
    // 垂直线
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
    // 水平线
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    // 对角线1
    canvas.drawLine(
      Offset(center.dx - size * 0.7, center.dy - size * 0.7),
      Offset(center.dx + size * 0.7, center.dy + size * 0.7),
      paint,
    );
    // 对角线2
    canvas.drawLine(
      Offset(center.dx + size * 0.7, center.dy - size * 0.7),
      Offset(center.dx - size * 0.7, center.dy + size * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

