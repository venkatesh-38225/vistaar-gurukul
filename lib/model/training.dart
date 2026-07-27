class Training {
  List<D>? d;

  Training({this.d});

  Training.fromJson(Map<String, dynamic> json) {
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
  int? id;
  String? mandatory;
  String? trainingName;
  String? trainingType;
  int? cutOffMarks;
  String? completedPercentage;
  int? noQuestions;
  String? trainingStatus;
  String? geoLocation;

  D({
    this.sType,
    this.id,
    this.mandatory,
    this.trainingName,
    this.trainingType,
    this.cutOffMarks,
    this.completedPercentage,
    this.noQuestions,
    this.trainingStatus,
    this.geoLocation,
  });

  D.fromJson(Map<String, dynamic> json) {
    sType = json['__type'];

    id = json['Id'];
    mandatory = json['Mandatory'];
    trainingName = json['TrainingName'];
    trainingType = json['TrainingType'];
    cutOffMarks = json['CutOffMarks'];
    completedPercentage = json['CompletedPercentage'];
    noQuestions = json['NoQuestions'];
    trainingStatus = json['TrainingStatus'];
    geoLocation = json['GeoLocation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['__type'] = sType;
    data['Id'] = id;
    data['Mandatory'] = mandatory;
    data['TrainingName'] = trainingName;
    data['TrainingType'] = trainingType;
    data['CutOffMarks'] = cutOffMarks;
    data['CompletedPercentage'] = completedPercentage;
    data['NoQuestions'] = noQuestions;
    data['TrainingStatus'] = trainingStatus;
    data['GeoLocation'] = geoLocation;
    return data;
  }
}
