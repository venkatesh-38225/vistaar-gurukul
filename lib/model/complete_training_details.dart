class CompleteTrainingDetail {
  List<D>? d;

  CompleteTrainingDetail({this.d});

  CompleteTrainingDetail.fromJson(Map<String, dynamic> json) {
    if (json['d'] != null) {
      d = <D>[];
      json['d'].forEach((v) {
        d!.add(D.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (d != null) {
      data['d'] = d!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class D {
  String? sType;
  String? bothStatus;
  String? completedPercentage;
  String? contentEndDatetime;
  String? contentStartDatetime;
  String? contentStatus;
  String? testDecision;
  String? testEndDatetime;
  String? testStartDatetime;
  String? testStatus;
  int? totalScore;
  int? traingId;

  D(
      {this.sType,
      this.bothStatus,
      this.completedPercentage,
      this.contentEndDatetime,
      this.contentStartDatetime,
      this.contentStatus,
      this.testDecision,
      this.testEndDatetime,
      this.testStartDatetime,
      this.testStatus,
      this.totalScore,
      this.traingId});

  D.fromJson(Map<String, dynamic> json) {
    sType = json['__type'];
    bothStatus = json['BothStatus'];
    completedPercentage = json['CompletedPercentage'];
    contentEndDatetime = json['ContentEndDatetime'];
    contentStartDatetime = json['ContentStartDatetime'];
    contentStatus = json['ContentStatus'];
    testDecision = json['TestDecision'];
    testEndDatetime = json['TestEndDatetime'];
    testStartDatetime = json['TestStartDatetime'];
    testStatus = json['TestStatus'];
    totalScore = json['TotalScore'];
    traingId = json['TraingId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['__type'] = sType;
    data['BothStatus'] = bothStatus;
    data['CompletedPercentage'] = completedPercentage;
    data['ContentEndDatetime'] = contentEndDatetime;
    data['ContentStartDatetime'] = contentStartDatetime;
    data['ContentStatus'] = contentStatus;
    data['TestDecision'] = testDecision;
    data['TestEndDatetime'] = testEndDatetime;
    data['TestStartDatetime'] = testStartDatetime;
    data['TestStatus'] = testStatus;
    data['TotalScore'] = totalScore;
    data['TraingId'] = traingId;
    return data;
  }
}
