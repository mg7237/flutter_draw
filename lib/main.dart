// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';

/// Hard coded variables

// Each section is equal to half of vertical distance between 2 milestones
// Number includes 1 additional section height reserved for end of path on top of UI and
// another 1 section in the bottom for first milestone
// So number of sections = number of max milestones * 2 + 2
const int kNumberOfSections = 8; //

const int kNumberOfMilestones =
    3; // Actual number of milestones completed; minimum 1

// Use to define steepness of curve, lesser value >> steeper curve
const int kControlPoint = 50;

// Keep track if the current milestone is on th right of center or left of center

/// End Hard Code vars

Path createAnimatedPath(
  Path originalPath,
  double animationPercent,
) {
  // ComputeMetrics can only be iterated once!
  final totalLength = originalPath
      .computeMetrics()
      .fold(0.0, (double prev, PathMetric metric) => prev + metric.length);

  final currentLength = totalLength * animationPercent;

  return extractPathUntilLength(originalPath, currentLength);
}

Path extractPathUntilLength(
  Path originalPath,
  double length,
) {
  var currentLength = 0.0;

  final path = Path();

  var metricsIterator = originalPath.computeMetrics().iterator;

  while (metricsIterator.moveNext()) {
    var metric = metricsIterator.current;

    var nextLength = currentLength + metric.length;

    final isLastSegment = nextLength > length;
    if (isLastSegment) {
      final remainingLength = length - currentLength;
      final pathSegment = metric.extractPath(0.0, remainingLength);

      path.addPath(pathSegment, Offset.zero);
      break;
    } else {
      // There might be a more efficient way of extracting an entire path
      final pathSegment = metric.extractPath(0.0, metric.length);
      path.addPath(pathSegment, Offset.zero);
    }

    currentLength = nextLength;
  }

  return path;
}

void main() => runApp(
      MaterialApp(
        home: AnimatedPathDemo(),
      ),
    );

class AnimatedPathPainter extends CustomPainter {
  final Animation<double> _animation;

  AnimatedPathPainter(this._animation) : super(repaint: _animation);

  Path _pathToNextMilestone(Size size, Path pathIn, int currentMilestone) {
    late double heightTop;
    late double heightMid;

    if ((currentMilestone / 2) == (currentMilestone ~/ 2)) {
      heightTop = size.height *
          ((kNumberOfSections - ((currentMilestone * 2) - 1))) /
          kNumberOfSections;

      heightMid = size.height *
          ((kNumberOfSections - ((currentMilestone - 1) * 2))) /
          kNumberOfSections;

      pathIn
        ..quadraticBezierTo(
            (size.width) - kControlPoint, heightMid, size.width / 2, heightMid)
        ..quadraticBezierTo(
            kControlPoint + 0.0, heightMid, kControlPoint + 0.0, heightTop);
    } else {
      heightTop = size.height *
          ((kNumberOfSections - ((currentMilestone * 2) - 1))) /
          kNumberOfSections;

      heightMid = size.height *
          ((kNumberOfSections - ((currentMilestone - 1) * 2))) /
          kNumberOfSections;

      pathIn
        ..quadraticBezierTo(
            kControlPoint + 0.0, heightMid, size.width / 2, heightMid)
        ..quadraticBezierTo(size.width - kControlPoint + 0.0, heightMid,
            size.width - kControlPoint + 0.0, heightTop);
    }
    return pathIn;
  }

  Path _createAnyPath(Size size) {
    Path path = Path()
      ..moveTo(size.width / 2, size.height)
      // ..lineTo(size.height, size.width / 2)
      // ..lineTo(size.height / 2, size.width)
      ..quadraticBezierTo(
          size.width - kControlPoint,
          size.height - kControlPoint, // * 1 * 3 / 4
          size.width - kControlPoint,
          size.height * ((kNumberOfSections - 1) / kNumberOfSections));

    if (kNumberOfMilestones > 1) {
      for (int i = 2; i <= kNumberOfMilestones; i++) {
        path = _pathToNextMilestone(size, path, i);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final animationPercent = _animation.value;

    print("Painting + $animationPercent - $size");
    final path = createAnimatedPath(_createAnyPath(size), animationPercent);

    final Paint paint = Paint();
    paint.color = Colors.redAccent;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AnimatedPathDemo extends StatefulWidget {
  @override
  _AnimatedPathDemoState createState() => _AnimatedPathDemoState();
}

class _AnimatedPathDemoState extends State<AnimatedPathDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animated Paint')),
      body: Stack(children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration:
              const BoxDecoration(color: Color.fromARGB(100, 189, 189, 189)),
          child: CustomPaint(painter: AnimatedPathPainter(_controller)),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _startAnimation,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
