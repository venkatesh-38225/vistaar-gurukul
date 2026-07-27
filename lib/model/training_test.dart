class TrainingTest {
  List<D>? d;

  TrainingTest({this.d});

  TrainingTest.fromJson(Map<String, dynamic> json) {
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
  String? language;
  int? opt1;
  String? opt1Text;
  int? opt2;
  String? opt2Text;
  int? opt3;
  String? opt3Text;
  int? opt4;
  String? opt4Text;
  int? opt5;
  String? opt5Text;
  String? questionDetails;
  int? wtopt1;
  int? wtopt2;
  int? wtopt3;
  int? wtopt4;
  int? wtopt5;

  D(
      {this.sType,
      this.id,
      this.language,
      this.opt1,
      this.opt1Text,
      this.opt2,
      this.opt2Text,
      this.opt3,
      this.opt3Text,
      this.opt4,
      this.opt4Text,
      this.opt5,
      this.opt5Text,
      this.questionDetails,
      this.wtopt1,
      this.wtopt2,
      this.wtopt3,
      this.wtopt4,
      this.wtopt5});

  D.fromJson(Map<String, dynamic> json) {
    sType = json['__type'];
    id = json['Id'];
    language = json['Language'];
    opt1 = json['Opt1'];
    opt1Text = json['Opt1Text'];
    opt2 = json['Opt2'];
    opt2Text = json['Opt2Text'];
    opt3 = json['Opt3'];
    opt3Text = json['Opt3Text'];
    opt4 = json['Opt4'];
    opt4Text = json['Opt4Text'];
    opt5 = json['Opt5'];
    opt5Text = json['Opt5Text'];
    questionDetails = json['QuestionDetails'];
    wtopt1 = json['Wtopt1'];
    wtopt2 = json['Wtopt2'];
    wtopt3 = json['Wtopt3'];
    wtopt4 = json['Wtopt4'];
    wtopt5 = json['Wtopt5'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['__type'] = sType;
    data['Id'] = id;
    data['Language'] = language;
    data['Opt1'] = opt1;
    data['Opt1Text'] = opt1Text;
    data['Opt2'] = opt2;
    data['Opt2Text'] = opt2Text;
    data['Opt3'] = opt3;
    data['Opt3Text'] = opt3Text;
    data['Opt4'] = opt4;
    data['Opt4Text'] = opt4Text;
    data['Opt5'] = opt5;
    data['Opt5Text'] = opt5Text;
    data['QuestionDetails'] = questionDetails;
    data['Wtopt1'] = wtopt1;
    data['Wtopt2'] = wtopt2;
    data['Wtopt3'] = wtopt3;
    data['Wtopt4'] = wtopt4;
    data['Wtopt5'] = wtopt5;
    return data;
  }
}
