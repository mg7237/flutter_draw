import 'dart:ui';
import 'dart:convert';
import 'models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Hard coded variables

// Use to define steepness of curve, lesser value >> steeper curve
const kControlPoint = 75.0;

List<Milestone> milestones = []; // All milestones array check Milestone Model

// Milestone image size (IconSize) is within a square container
const kIconSize = 50.0;

int numberOfMilestones = 0; // Current Milestone number

/// Milestone Detail Widget - 1 line height; used to calculate the widget
/// height depending on milestone type
late double kLineHeight = 20.0;

const kCardDistance =
    50.0; // Distance of card from the malestone point on the curve

late Widget card; // Common card for all milestone which need card

int kMaxTitleLength = 30; // Title Length

TextStyle kTextStyle = const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.bold);

TextStyle kTextStyleSmall = const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    color: Colors.white,
    fontWeight: FontWeight.bold);
const jsonData =
    '{"currentMilestone":3,"milestones":[{"type":"starting-point","title":"Precap"},{"type":"topic","title":"Basic of Electric X Current Basic of Electric Current X Basic of Electric Current"},{"type":"preconcept","title":"Electric Charge","clarity":"20%"},{"type":"topic","title":"Details of Ohm'
    's Law"},{"type":"topic","title":"Velocity, Mebility and Current"},{"type":"topic","title":"Relation Between Temperature and Resitivity"},{"type":"classwork","title":"Classwork WS","progress":{"total":20,"completed":10}},{"type":"homework","title":"Homework","progress":{"total":26,"completed":18}}]}';

/// End Hard Code vars

class AnimatedPath extends StatefulWidget {
  const AnimatedPath({Key? key}) : super(key: key);

  @override
  _AnimatedPathState createState() => _AnimatedPathState();
}

class _AnimatedPathState extends State<AnimatedPath>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double totalHeight =
      0; // Canvas height = Sum of all milestone heights in above array
  double topBuffer = 50.0;

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.duration = Duration(seconds: numberOfMilestones);
    _controller.forward();
  }

  MilestoneDetail milestoneInformation(
      int milestoneNumberLocal, double milestoneHeight) {
    late MilestoneDetail milestoneDetail;
    late double height;
    String title = milestones[milestoneNumberLocal].title;
    if ((milestones[milestoneNumberLocal].title) != '' &&
        milestones[milestoneNumberLocal].title.length > 55) {
      title = title.substring(0, 53) + ' ...';
    }
    switch (milestones[milestoneNumberLocal].type) {
      case 'starting-point':
        height = 2 * kLineHeight;
        milestoneDetail = MilestoneDetail(
            height: height,
            detailWidget: Container(
                alignment: Alignment.centerRight,
                height: height,
                width: 150,
                child: Text(title, style: kTextStyle)));
        break;
      case 'topic':
        height = 6 * kLineHeight + 10;
        milestoneDetail = MilestoneDetail(
            height: height,
            detailWidget: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 200,
                    height: (title.length > 30) ? kLineHeight * 2 : kLineHeight,
                    child: Text(title, style: kTextStyle)),
                const SizedBox(height: 5),
                card
              ],
            ));
        break;
      case 'preconcept':
        height = 7 * kLineHeight + 20;
        milestoneDetail = MilestoneDetail(
            height: height,
            detailWidget: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: (title.length > 25) ? kLineHeight * 2 : kLineHeight,
                    width: 200,
                    child: Text(title, style: kTextStyle)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                        alignment: Alignment.centerRight,
                        height: kLineHeight,
                        width: 80,
                        decoration: BoxDecoration(
                            color: const Color(0xffE7BC04),
                            border: Border.all(),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5))),
                        child: Center(
                            child: Text('Preconcept', style: kTextStyleSmall))),
                    const SizedBox(width: 10),
                    Text(
                        (milestones[milestoneNumberLocal].clarity ?? '') +
                            ' Clarity',
                        style: kTextStyleSmall)
                  ],
                ),
                const SizedBox(height: 5),
                card
              ],
            ));

        break;
      case 'classwork': // Same logic as homework
      case 'homework':
        height = 4 * kLineHeight;
        milestoneDetail = MilestoneDetail(
            height: height,
            detailWidget: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: (title.length > 25) ? kLineHeight * 2 : kLineHeight,
                    width: 200,
                    child: Text(title, style: kTextStyle)),
                const SizedBox(height: 5),
                SizedBox(
                  child: Text(
                      milestones[milestoneNumberLocal]
                              .progress!
                              .completed
                              .toString() +
                          ' / ' +
                          milestones[milestoneNumberLocal]
                              .progress!
                              .total
                              .toString(),
                      style: kTextStyle),
                ),
                const SizedBox(height: 5),
                LinearPercentIndicator(
                    width: 150.0,
                    lineHeight: 8.0,
                    percent: (milestones[milestoneNumberLocal]
                                .progress
                                ?.completed ??
                            0) /
                        (milestones[milestoneNumberLocal].progress?.total ?? 1),
                    backgroundColor: Colors.white,
                    progressColor: Colors.green,
                    barRadius: const Radius.circular(5))
              ],
            ));
        break;
    }
    return milestoneDetail;
  }

  List<Widget> _drawMilestones(Size size) {
    double milestoneHeight = 0;
    List<Widget> widgets = [];

    for (int i = 0; i < milestones.length; i++) {
      milestoneHeight += (milestones[i].height ?? 0);
      MilestoneDetail milestoneDetail =
          milestoneInformation(i, milestoneHeight);
      if ((i / 2) != (i ~/ 2)) {
        widgets.add(Positioned(
            left: kControlPoint - (kIconSize / 2) + 5,
            bottom: milestoneHeight - (kIconSize / 2),
            child: SizedBox(
                width: kIconSize,
                height: kIconSize,
                child: Image(
                    image:
                        AssetImage('assets/' + milestones[i].type + '.png')))));

        widgets.add(Positioned(
            left: (i != 0)
                ? kControlPoint + kCardDistance
                : (kControlPoint * 2) + kCardDistance,
            bottom: milestoneHeight - ((milestoneDetail.height) / 2) + 10,
            child: milestoneDetail.detailWidget));
      } else {
        widgets.add(Positioned(
          right: kControlPoint -
              (((i == 0) ? kIconSize * 3 : kIconSize) / 2), //  (kIconSize / 2)
          bottom: milestoneHeight -
              (((i == 0) ? kIconSize * 3 : kIconSize) / 2) -
              10,
          child: SizedBox(
              width: (i == 0) ? kIconSize * 3 : kIconSize,
              height: (i == 0) ? kIconSize * 3 : kIconSize,
              child: Image(
                  image: AssetImage('assets/' + milestones[i].type + '.png'))),
        ));
        widgets.add(Positioned(
            left: kControlPoint,
            bottom: milestoneHeight - ((milestoneDetail.height) / 2) + 10,
            child: milestoneDetail.detailWidget));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    Size size = Size(
      MediaQuery.of(context).size.width,
      totalHeight + topBuffer,
    );
    return SafeArea(
      child: Scaffold(
          body: SingleChildScrollView(
        reverse: true,
        child: Center(
          child: Container(
            height: size.height,
            width: size.width,
            decoration:
                const BoxDecoration(color: Color.fromRGBO(45, 69, 156, 1.0)),
            child: Stack(children: [
              CustomPaint(
                  painter: AnimatedPathPainter(_controller), size: size),
              CustomPaint(painter: DashPathPainter(size)),
              Positioned(
                  bottom: 0 - 15,
                  left: (size.width / 2) - (kIconSize / 2),
                  child: const SizedBox(
                      height: kIconSize,
                      width: kIconSize,
                      child: Image(image: AssetImage('assets/rocket.png')))),
              Stack(
                  children: _drawMilestones(Size(
                MediaQuery.of(context).size.width,
                totalHeight,
              ))),
            ]),
          ),
        ),
      )),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
    _readData();
    _startAnimation();
    card = Container(
        height: 4 * kLineHeight,
        width: 140,
        decoration: BoxDecoration(
            color: const Color(0xffffffff),
            border: Border.all(),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(children: [
          Row(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              child: SizedBox(
                  height: kLineHeight * 1.25,
                  width: kLineHeight,
                  child: const Image(image: AssetImage('assets/brain.png'))),
            ),
            const SizedBox(width: 5),
            const Text('Learn',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ]),
          Divider(
            height: 0.2 * kLineHeight,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: Colors.grey[500],
          ),
          Row(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              child: SizedBox(
                  height: kLineHeight,
                  width: kLineHeight,
                  child: const Image(
                      image: AssetImage('assets/homework_icon.png'))),
            ),
            const SizedBox(width: 5),
            const Text('Homework',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ]),
        ]));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getMilestoneHeight({required String type, required String title}) {
    double height = 200.0;
    if (title.length > kMaxTitleLength) {
      title = title.substring(0, kMaxTitleLength) + ' ...';
    }
    switch (type) {
      case 'starting-point':
        height = 100;
        break;
      case 'topic':
      case 'preconcept':
      case 'classwork':
      case 'homework':
      default:
        height = 200;
        break;
    }
    return height;
  }

  void _readData() {
    try {
      late double height;
      Map<String, dynamic> mapData = jsonDecode(jsonData);
      numberOfMilestones = mapData['currentMilestone'];
      List<dynamic> milestonesData = mapData['milestones'];
      for (int i = 0; i < milestonesData.length; i++) {
        height = _getMilestoneHeight(
            type: milestonesData[i]['type'], title: milestonesData[i]['title']);

        if (i == milestonesData.length - 1) height = 200;

        totalHeight += height;
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
  }
}

class DashPathPainter extends CustomPainter {
  final Size size;
  DashPathPainter(this.size);

  final Paint blackStroke = Paint()
    ..color = const Color.fromRGBO(82, 101, 171, 1)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  @override
  bool shouldRepaint(DashPathPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size ignoreSize) {
    Path p = _createAnyPath(size, milestones.length);
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

class AnimatedPathPainter extends CustomPainter {
  final Animation<double> _animation;

  AnimatedPathPainter(this._animation) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final animationPercent = _animation.value;

    print("Painting + $animationPercent - $size");
    final path = createAnimatedPath(
        _createAnyPath(size, numberOfMilestones), animationPercent);

    final Paint paint = Paint();
    paint.color = Colors.green[500] ?? Colors.green;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 10.0;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

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

Path _pathToNextMilestone(Size size, Path pathIn, int currentMilestone) {
  late double heightTop;
  late double heightMid;
  heightTop = size.height - ((milestones[currentMilestone].height ?? 0.0));

  heightMid = size.height - ((milestones[currentMilestone].height ?? 0.0) / 2);

  if ((currentMilestone / 2) != (currentMilestone ~/ 2)) {
    // Current Milestone on left
    pathIn
      ..quadraticBezierTo(
          size.width - kControlPoint, heightMid, size.width / 2, heightMid)
      ..quadraticBezierTo(kControlPoint, heightMid, kControlPoint, heightTop);
  } else {
    // Milestone on right
    pathIn
      ..quadraticBezierTo(kControlPoint, heightMid, size.width / 2, heightMid)
      ..quadraticBezierTo(size.width - kControlPoint, heightMid,
          size.width - kControlPoint, heightTop);
  }
  return pathIn;
}

Path _createAnyPath(Size size, int drawTill) {
  double firstMilestoneHeight = milestones[0].height ?? 0.0;
  Path path = Path()
    ..moveTo(size.width / 2, size.height)
    ..quadraticBezierTo(size.width - kControlPoint, size.height,
        size.width - kControlPoint, size.height - firstMilestoneHeight);

  double prevHeight = size.height - firstMilestoneHeight;
  for (int i = 1; i < drawTill; i++) {
    size = Size(size.width, prevHeight);
    path = _pathToNextMilestone(size, path, i);
    prevHeight -= milestones[i].height ?? 0;
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
