// ignore_for_file: avoid_print

import 'dart:ui';
import 'dart:convert';
import 'models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

/// Hard coded variables

// Each section is equal to half of vertical distance between 2 milestones
// Number includes 1 additional section height reserved for end of path on top of UI and
// another 1 section in the bottom for first milestone
// So number of sections = number of max milestones * 2 + 2
const int kNumberOfSections = 10; //

const int kMaxMilestones = 5; // Maximum milestones
const int kMilestonesCompleted =
    3; // Actual number of milestones completed; minimum 1

// Use to define steepness of curve, lesser value >> steeper curve
const kControlPoint = 70.0;

// Keep track if the current milestone is on th right of center or left of center

// Milestone image size (IconSize) is within a square container
const kIconSize = 50.0;

const kCardDistance = 30.0;

const jsonData =
    '{"currentMilestone":3,"milestones":[{"type":"starting-point","title":"Precap"},{"type":"topic","title":"Basic of Electric Current"},{"type":"preconcept","title":"Electric Charge","clarity":"20%"},{"type":"topic","title":"Details of Ohm'
    's Law"},{"type":"topic","title":"Velocity, Mebility and Current"},{"type":"topic","title":"Relation Between Temperature and Resitivity"},{"type":"classwork","title":"Classwork WS","progress":{"total":20,"completed":10}},{"type":"homework","title":"Homework","progress":{"total":26,"completed":18}}]}';

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
      .then((value) => runApp(const MaterialApp(home: AnimatedPath())));
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

    // dashArray: CircularIntervalList<double>([dashSize, gapSize]),
    //   dashOffset: DashOffset.percentage(0.005));

    if (kMilestonesCompleted > 1) {
      for (int i = 2; i <= kMilestonesCompleted; i++) {
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
    paint.color = Colors.green[500] ?? Colors.green;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 10.0;

    canvas.drawPath(path, paint);
    //  canvas.drawRect(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AnimatedPath extends StatefulWidget {
  const AnimatedPath({Key? key}) : super(key: key);

  @override
  _AnimatedPathState createState() => _AnimatedPathState();
}

class _AnimatedPathState extends State<AnimatedPath>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int numberOfMilestones;
  List<Milestone> milestones = [];
  List<double> milestoneHeights = []; // Height of individual milestones
  double totalHeight =
      0; // Canvas height = Sum of all milestone heights in above array

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.duration = const Duration(seconds: 5);
    _controller.forward(
        //period: const Duration(seconds: 5),
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
                30,
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
      Container(
        height: size.height,
        width: size.width,
        decoration:
            const BoxDecoration(color: Color.fromRGBO(45, 69, 156, 1.0)),
        child:
            CustomPaint(painter: AnimatedPathPainter(_controller), size: size),
      ),
      Center(
        child: Container(
          width: size.width,
          height: size.height,
          child: CustomPaint(painter: DashPathPainter(size)),
        ),
      ),
      Stack(children: _drawTriangleAndCards(size)),
    ]));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
    _readData();
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getMilestoneHeight({required type, required title}) {
    return 60.0;
  }

  void _readData() {
    try {
      Map<String, dynamic> mapData = jsonDecode(jsonData);
      numberOfMilestones = mapData['currentMilestone'];
      List<dynamic> milestonesData = mapData['milestones'];
      for (int i = 0; i < milestonesData.length; i++) {
        double height = _getMilestoneHeight(
            type: milestonesData[i]['type'], title: milestonesData[i]['title']);
        if (milestonesData[i]['progress'] != null) {
          milestones.add(Milestone(
              type: milestonesData[i]['type'],
              title: milestonesData[i]['title'],
              clarity: milestonesData[i]['clarity'],
              height: height,
              progress: Progress(
                  completed: milestonesData[i]['progress']['completed'],
                  total: milestonesData[i]['progress']['total'])));
        } else {
          milestones.add(Milestone(
              type: milestonesData[i]['type'],
              title: milestonesData[i]['title'],
              height: height,
              clarity: milestonesData[i]['clarity']));
        }
      }
    } catch (e) {
      print('Exception while parsing json data: ' + e.toString());
    }
    print(milestones);
  }
}

class DashPathPainter extends CustomPainter {
  final Size size;
  DashPathPainter(this.size);

  final Paint blackStroke = Paint()
    ..color = const Color.fromRGBO(82, 101, 171, 1)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

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

    if (kMaxMilestones > 1) {
      for (int i = 2; i <= kMaxMilestones; i++) {
        path = _pathToNextMilestone(size, path, i);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(DashPathPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    Path p = _createAnyPath(size);
    canvas.drawPath(
        dashPath(
          p,
          dashArray: CircularIntervalList<double>(
            <double>[10.0, 5],
          ),
        ),
        blackStroke);
  }
}
