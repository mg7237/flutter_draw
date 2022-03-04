import 'package:flutter/material.dart';

class RoadMapData {
  int currentMilestone;
  List<Milestone> milestones = [];
  RoadMapData(this.currentMilestone, this.milestones);
}

class Milestone {
  String type;
  String title;
  String? clarity;
  Progress? progress;
  double? height;
  Milestone(
      {required this.type,
      required this.title,
      this.clarity,
      this.progress,
      this.height});
}

class Progress {
  int total;
  int completed;

  Progress({required this.total, required this.completed});
}

class MilestoneDetail {
  double height;
  Widget detailWidget;
  MilestoneDetail({required this.height, required this.detailWidget});
}
