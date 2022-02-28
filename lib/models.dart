class RoadMapData {
  int currentMilestone;
  List<Milestone> milestones = [];
  RoadMapData(this.currentMilestone, this.milestones);
}

class Milestone {
  String type;
  String title;
  String? clarity;
  double? height;
  Progress? progress;
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
