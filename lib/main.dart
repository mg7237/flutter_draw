import 'dart:ui';
import 'dart:convert';
import 'models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/scheduler.dart';

/// Hard coded variables

// Use to define steepness of curve, lesser value >> steeper curve
const kControlPoint = 50.0;

List<Milestone> milestones = []; // All milestones array check Milestone Model

// Milestone image size (IconSize) is within a square container
const kIconSize = 50.0;

int numberOfMilestones = 0; // Current Milestone number

double kLineHeight = 20.0; // Used for card dimensions

const kCardDistance =
    30.0; // Distance of card from the malestone point on the curve

double heightGap = 80.0; // Left, Right milestone height difference

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
  bool init = true;
  Size size = const Size(0, 0);
  double totalHeight =
      0; // Canvas height = Sum of all milestone heights in above array

  double totalWidth = 0;
  final GlobalKey _masterContainerKey = GlobalKey();
  List<GlobalKey> rowKeys = [];
  List<Widget> columnWidgets = [];
  Column masterColumn = Column(children: const []);

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.duration = Duration(seconds: numberOfMilestones);
    _controller.forward();
  }

  Widget milestoneInformation(int milestoneNumberLocal) {
    late Widget milestoneDetail;

    String title = milestones[milestoneNumberLocal].title;
    if ((milestones[milestoneNumberLocal].title) != '' &&
        milestones[milestoneNumberLocal].title.length > 55) {
      title = title.substring(0, 53) + ' ...';
    }

    switch (milestones[milestoneNumberLocal].type) {
      case 'starting-point':
        milestoneDetail =
            SizedBox(width: 50, child: Text(title, style: kTextStyle));
        break;
      case 'topic':
        milestoneDetail = Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 180, child: Text(title, style: kTextStyle)),
            const SizedBox(height: 5),
            card
          ],
        );
        break;
      case 'preconcept':
        milestoneDetail = Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: Text(title, style: kTextStyle)),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                    alignment: Alignment.centerRight,
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
        );

        break;
      case 'classwork': // Same logic as homework
      case 'homework':
        milestoneDetail = Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 200, child: Text(title, style: kTextStyle)),
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
                percent:
                    (milestones[milestoneNumberLocal].progress?.completed ??
                            0) /
                        (milestones[milestoneNumberLocal].progress?.total ?? 1),
                backgroundColor: Colors.white,
                progressColor: Colors.green,
                barRadius: const Radius.circular(5))
          ],
        );
        break;
    }
    return milestoneDetail;
  }

  void _milestoneWidgets(double width) {
    SizedBox heightBox = SizedBox(height: heightGap);
    SizedBox widthBox = const SizedBox(width: kControlPoint);
    SizedBox dataDistanceBox = const SizedBox(width: kCardDistance);
    columnWidgets = [];
    rowKeys = [];

    for (int i = 0; i < milestones.length; i++) {
      late Widget row;
      Widget milestoneData = milestoneInformation(i);
      GlobalKey rowKey = GlobalKey();
      if ((i / 2) != (i ~/ 2)) {
        // Even milestone = Icon on left of UI
        row = Row(
            key: rowKey,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widthBox,
              Image(image: AssetImage('assets/${milestones[i].type}.png')),
              dataDistanceBox,
              milestoneData
            ]);
      } else {
        // Odd milestone = Icon on right of UI
        row = Row(
            key: rowKey,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              milestoneData,
              dataDistanceBox,
              Image(image: AssetImage('assets/${milestones[i].type}.png')),
              widthBox
            ]);
      }
      // Inserting in reverse order so that Column is built from top to bottom
      // While we add widgets from below to top

      columnWidgets.insert(0, row);
      if (i != milestones.length - 1) columnWidgets.insert(0, heightBox);
      rowKeys.insert(0, rowKey);
    }

    masterColumn = Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: columnWidgets);

    return;
  }

  @override
  Widget build(BuildContext context) {
    _milestoneWidgets(MediaQuery.of(context).size.width);
    if (totalHeight > 0 && MediaQuery.of(context).size.width > 0) {
      double dy = totalHeight.ceil().toDouble();
      double dx = MediaQuery.of(context).size.width.floor().toDouble();
      size = Size(dx, dy);
      init = false;
    }
    if (!init) _startAnimation();

    return SafeArea(
      child: Scaffold(
          body: SingleChildScrollView(
        reverse: true,
        child: Container(
          alignment: Alignment.bottomCenter,
          key: _masterContainerKey,
          child: Container(
            width: double.infinity,
            decoration:
                const BoxDecoration(color: Color.fromRGBO(45, 69, 156, 1.0)),
            child: Stack(children: [
              (init)
                  ? const SizedBox()
                  : CustomPaint(
                      painter: AnimatedPathPainter(_controller), size: size),
              (init)
                  ? const SizedBox()
                  : CustomPaint(painter: DashPathPainter(size)),
              masterColumn,
              Positioned(
                  bottom: 0,
                  left: (size.width / 2) - (kIconSize / 2),
                  child: const SizedBox(
                      height: kIconSize,
                      width: kIconSize,
                      child: Image(image: AssetImage('assets/rocket.png')))),
            ]),
          ),
        ),
      )),
    );
  }

  void _getWidgetInfo(BuildContext context) {
    final RenderBox renderBox =
        _masterContainerKey.currentContext?.findRenderObject() as RenderBox;
    final Size renderSize =
        renderBox.size; // or _masterContainerKey.currentContext?.size
    print('Size: ${renderSize.width}, ${renderSize.height}');

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    print('Offset: ${offset.dx}, ${offset.dy}');
    print(
        'Position: ${(offset.dx + renderSize.width) / 2}, ${(offset.dy + renderSize.height) / 2}');
    totalHeight = renderSize.height;
    if (totalHeight > 0 && milestones.isNotEmpty) {
      for (int i = 0; i < milestones.length; i++) {
        final RenderBox renderBoxWidget =
            rowKeys[i].currentContext?.findRenderObject() as RenderBox;
        milestones[i].height = renderBoxWidget.size.height;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // if (SchedulerBinding.instance?.schedulerPhase ==
    //     SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance
        ?.addPostFrameCallback((_) => _getWidgetInfo(context));
    card = Container(
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

    // }

    _controller = AnimationController(
      vsync: this,
    );
    _readData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _readData() {
    try {
      Map<String, dynamic> mapData = jsonDecode(jsonData);
      numberOfMilestones = mapData['currentMilestone'];
      List<dynamic> milestonesData = mapData['milestones'];
      for (int i = 0; i < milestonesData.length; i++) {
        if (milestonesData[i]['progress'] != null) {
          milestones.add(Milestone(
              type: milestonesData[i]['type'],
              title: milestonesData[i]['title'],
              clarity: milestonesData[i]['clarity'],
              progress: Progress(
                  completed: milestonesData[i]['progress']['completed'],
                  total: milestonesData[i]['progress']['total'])));
        } else {
          milestones.add(Milestone(
              type: milestonesData[i]['type'],
              title: milestonesData[i]['title'],
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

    //print("Painting + $animationPercent - $size");
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

Path _pathToNextMilestone(
    double prevHeight, double width, Path pathIn, int currentMilestone) {
  double offsetHeight = 100;
  double offsetwidth = 30;
  double heightTop = prevHeight -
      (heightGap +
          ((milestones[currentMilestone].height ?? 0.0) / 2) +
          ((milestones[currentMilestone - 1].height ?? 0.0) / 2));

  double heightMid = prevHeight - ((prevHeight - heightTop) / 2);

  if ((currentMilestone / 2) != (currentMilestone ~/ 2)) {
    // Current Milestone on left
    pathIn
      ..quadraticBezierTo(width - kControlPoint - offsetwidth,
          prevHeight - offsetHeight, width / 2, heightMid)
      ..quadraticBezierTo(kControlPoint + offsetwidth, heightTop + offsetHeight,
          kControlPoint, heightTop);
    // width - kControlPoint, heightMid, width / 2, heightMid)
    //..quadraticBezierTo(kControlPoint, heightMid, kControlPoint, heightTop);
  } else {
    // Milestone on right
    pathIn
      ..quadraticBezierTo(kControlPoint + offsetwidth,
          prevHeight - offsetHeight, width / 2, heightMid)
      ..quadraticBezierTo(width - kControlPoint - offsetwidth,
          heightTop + offsetHeight, width - kControlPoint, heightTop);
    // ..quadraticBezierTo(kControlPoint, heightMid, width / 2, heightMid)
    // ..quadraticBezierTo(
    //     width - kControlPoint, heightMid, width - kControlPoint, heightTop);
  }
  return pathIn;
}

Path _createAnyPath(Size size, int drawTill) {
  double firstMilestoneHeight = size.height - ((milestones[0].height ?? 0) / 2);
  Path path = Path()
    ..moveTo(size.width / 2, size.height)
    ..quadraticBezierTo(
        size.width - kControlPoint - 10,
        firstMilestoneHeight + 10,
        size.width - kControlPoint - ((3 * kIconSize) / 2),
        firstMilestoneHeight);

  double prevHeight = firstMilestoneHeight;
  for (int i = 1; i < drawTill; i++) {
    path = _pathToNextMilestone(prevHeight, size.width, path, i);
    prevHeight -= (heightGap +
        ((milestones[i].height ?? 0) / 2) +
        ((milestones[i - 1].height ?? 0) / 2));
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
