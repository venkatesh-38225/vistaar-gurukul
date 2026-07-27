class TrainingContent {
  List<D>? d;

  TrainingContent({this.d});

  TrainingContent.fromJson(Map<String, dynamic> json) {
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
  String? btn;
  String? content;
  String? docName;
  int? id;
  String? imageName;
  String? imagePath;
  String? pDFName;
  String? pPTName;
  String? videoName;
  int? trainingId;

  D(
      {this.sType,
      this.btn,
      this.content,
      this.docName,
      this.id,
      this.imageName,
      this.imagePath,
      this.pDFName,
      this.pPTName,
      this.videoName,
      this.trainingId});

  D.fromJson(Map<String, dynamic> json) {
    sType = json['__type'];
    btn = json['Btn'];
    content = json['Content'];
    docName = json['DocName'];
    id = json['Id'];
    imageName = json['ImageName'];
    imagePath = json['ImagePath'];
    pDFName = json['PDFName'];
    pPTName = json['PPTName'];
    videoName = json['VideoName'];
    trainingId = json['trainingId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['__type'] = sType;
    data['Btn'] = btn;
    data['Content'] = content;
    data['DocName'] = docName;
    data['Id'] = id;
    data['ImageName'] = imageName;
    data['ImagePath'] = imagePath;
    data['PDFName'] = pDFName;
    data['PPTName'] = pPTName;
    data['VideoName'] = videoName;
    data['trainingId'] = trainingId;
    return data;
  }
}
