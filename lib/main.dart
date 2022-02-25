// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

/// Hard coded variables

// Each section is equal to half of vertical distance between 2 milestones
// Number includes 1 additional section height reserved for end of path on top of UI and
// another 1 section in the bottom for first milestone
// So number of sections = number of max milestones * 2 + 2
const int kNumberOfSections = 10; //

const int kNumberOfMilestones =
    5; // Actual number of milestones completed; minimum 1

// Use to define steepness of curve, lesser value >> steeper curve
const kControlPoint = 70.0;

// Keep track if the current milestone is on th right of center or left of center

// Milestone image size (IconSize) is within a square container
const kIconSize = 50.0;

const kCardDistance = 30.0;

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

void main() {
  // We need to call it manually,
  // because we going to call setPreferredOrientations()
  // before the runApp() call
  WidgetsFlutterBinding.ensureInitialized();

  // Than we setup preferred orientations,
  // and only after it finished we run our app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(const MaterialApp(home: AnimatedPathDemo())));
}

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
      ..quadraticBezierTo(
          size.width - kControlPoint,
          size.height, // * 1 * 3 / 4
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
  const AnimatedPathDemo({Key? key}) : super(key: key);

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
      period: const Duration(seconds: 5),
    );
  }

  List<Widget> _drawTriangleAndCards(Size size) {
    List<Widget> widgets = [];
    for (int i = 1; i <= (kNumberOfSections / 2); i++) {
      if ((i / 2) == (i ~/ 2)) {
        widgets.add(Positioned(
            left: kControlPoint - (kIconSize / 2) + 4,
            top: ((kNumberOfSections - ((i * 2) - 1)) /
                    kNumberOfSections *
                    size.height) -
                (kIconSize / 2),
            child: Row(
              children: [
                SizedBox(
                    width: kIconSize + 0.0,
                    height: kIconSize + 0.0,
                    child: SvgPicture.asset('assets/roadmap_topic.svg')),
                Column(children: [
                  Text(
                    'MileStone Number: $i',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Container(
                      height: 70,
                      width: 100,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5))),
                      child: const Center(
                        child:
                            Text('Sample Card', style: TextStyle(fontSize: 12)),
                      ))
                ]),
              ],
            )));
      } else {
        widgets.add(Positioned(
            right: kControlPoint - (kIconSize / 2), //  (kIconSize / 2)
            top: (size.height *
                    (kNumberOfSections - ((i * 2) - 1)) /
                    kNumberOfSections) -
                20,
            child: Row(
              children: [
                Column(children: [
                  Text(
                    'MileStone Number: $i',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Container(
                      height: 70,
                      width: 100,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5))),
                      child: const Center(
                        child:
                            Text('Sample Card', style: TextStyle(fontSize: 12)),
                      ))
                ]),
                SizedBox(
                    width: kIconSize + 0.0,
                    height: kIconSize + 0.0,
                    child: SvgPicture.asset('assets/roadmap_topic.svg')),
              ],
            )));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    Size size = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    return Scaffold(
        //appBar: AppBar(title: const Text('Animated Paint')),
        body: Stack(children: [
          // Container(
          //   height: MediaQuery.of(context).size.height,
          //   width: MediaQuery.of(context).size.width,
          //   decoration:
          //       const BoxDecoration(color: Color.fromARGB(100, 189, 189, 189)),
          //   child: CustomPaint(painter: AnimatedPathPainter(_controller)),
          // ),
          Container(
            height: size.height,
            width: size.width,
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 189, 189, 189)),
            child: CustomPaint(
                painter: AnimatedPathPainter(_controller), size: size),
          ),
          Stack(children: _drawTriangleAndCards(size)),
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: _startAnimation,
          child: const Icon(Icons.play_arrow),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat);
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
