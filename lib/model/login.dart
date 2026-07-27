class Login {
  D? d;

  Login({this.d});

  Login.fromJson(Map<String, dynamic> json) {
    d = json['d'] != null ? D.fromJson(json['d']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (d != null) {
      data['d'] = d!.toJson();
    }
    return data;
  }
}

class D {
  String? sType;
  String? branchid;
  String? branchname;
  String? cluster;
  String? department;
  String? designation;
  String? email;
  int? language;
  String? mobile;
  String? role;
  String? state;
  String? status;
  String? userId;
  String? userName;

  D(
      {this.sType,
      this.branchid,
      this.branchname,
      this.cluster,
      this.department,
      this.designation,
      this.email,
      this.language,
      this.mobile,
      this.role,
      this.state,
      this.status,
      this.userId,
      this.userName});

  D.fromJson(Map<String, dynamic> json) {
    sType = json['__type'];
    branchid = json['Branchid'];
    branchname = json['Branchname'];
    cluster = json['Cluster'];
    department = json['Department'];
    designation = json['Designation'];
    email = json['Email'];
    language = json['Language'];
    mobile = json['Mobile'];
    role = json['Role'];
    state = json['State'];
    status = json['Status'];
    userId = json['UserId'];
    userName = json['UserName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['__type'] = sType;
    data['Branchid'] = branchid;
    data['Branchname'] = branchname;
    data['Cluster'] = cluster;
    data['Department'] = department;
    data['Designation'] = designation;
    data['Email'] = email;
    data['Language'] = language;
    data['Mobile'] = mobile;
    data['Role'] = role;
    data['State'] = state;
    data['Status'] = status;
    data['UserId'] = userId;
    data['UserName'] = userName;
    return data;
  }
}
