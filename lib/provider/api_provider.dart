import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/model/training_content.dart';
import 'package:gurukul/model/training_test.dart';
import 'package:path_provider/path_provider.dart';

import '../common/shared_pref.dart';
import '../model/login.dart';
import '../model/login.dart' as loginD;
import '../model/training.dart';
import '../model/training.dart' as trainingD;
import '../model/complete_training_details.dart' as completeTrainingDetailsD;
import 'dart:async';

class UserProvider with ChangeNotifier {
  Dio dio = Dio();

  Login _user = Login();

  List _handleOptions = [];
  Map _selectedAnswers = {};
  int _marks = 0;
  int _trainingPageTrack = 0;

//pdf notifiers
  int _pageTrack = -1;
  bool _pageSwipeHint = true;
  int _latestPdfPage = 0;
  int _totalPage = 0;
  bool _isScrollable = true;
  bool _pdfLoaded = false;

  Map<String, int> _contentCompleteTrackPerc = {"onPage": 0, "totalPage": 70};
  Map _trainingStatusAndProgress = {
    "Completed": [],
    "InProgress": [],
    "New": [],
    "Others": [],
  };

  Map<int, trainingD.D> _otherTrainingList = {};

  double _inProgressPerc = 0.0;
  double _completedPerc = 0.0;
  double _newPerc = 0.0;

  double _otherTrainingListLength = 0.0;
  int _completedPdfPage = 0;

  Login get login => _user;

  List get handleOptions => _handleOptions;

  Map get selectedAnswers => _selectedAnswers;

  int get getMarks => _marks;

  int get getPageTrack => _pageTrack;

  bool get pageSwipeHint => _pageSwipeHint;

  Map<String, int> get contentCompleteTrackPerc => _contentCompleteTrackPerc;

  Map get trainingStatusAndProgress => _trainingStatusAndProgress;

  double get inProgressPerc => _inProgressPerc;

  double get completedPerc => _completedPerc;

  double get newPerc => _newPerc;

  double get otherTrainingListLength => _otherTrainingListLength;

  Map<int, trainingD.D> get otherTrainingList => _otherTrainingList;

  int get trainingPageTrack => _trainingPageTrack;

  //pdf getters
  int get completedPdfPage => _completedPdfPage;

  int get latestPdfPage => _latestPdfPage;

  int get totalPage => _totalPage;

  bool get isScrollable => _isScrollable;

  bool get pdfLoaded => _pdfLoaded;

  bool isLoading = false;

  set setUser(Login user) {
    _user = user;
    notifyListeners();
  }

  Future setPercAndStatus() async {
    UserPreference().getUser().then((value) {
      loginD.D data = value;

      _fetchAndProcessTrainingData(data, "Y");
      // _fetchAndProcessTrainingData(data, "N");
    });
  }

  void _fetchAndProcessTrainingData(loginD.D data, String mandatory) {
    _trainingStatusAndProgress.clear();
    _trainingStatusAndProgress = {
      "Completed": [],
      "InProgress": [],
      "New": [],
      "Others": [],
    };

    final trainingData = {
      "UserId": data.userId,
      "Department": data.department,
      "LangId": data.language.toString(),
      "Mandatory": mandatory,
    };
    print("training data : ${trainingData}");
    dio.post(trainingUrl, data: trainingData).then((response) {
      if (response.statusCode == 200) {
        final training = Training.fromJson(jsonDecode(response.toString()));

        for (var element in training.d!) {
          if (element.trainingStatus!.toLowerCase() == "completed") {
            _trainingStatusAndProgress['Completed'].add({
              "mandatory": element.mandatory,
              "trainingName": element.trainingName,
              "trainingId": element.id,
              "trainingType": element.trainingType,
              "cutOff": element.cutOffMarks,
            });
            debugPrint("cutOff: ${element.cutOffMarks}");
          }
          if (element.trainingStatus!.toLowerCase() == "new") {
            _trainingStatusAndProgress['New'].add(element);
          }
          if (element.trainingStatus!.toLowerCase() == "inprogress") {
            // debugPrint(
            //     "completed = ${element.completedPercentage} and runTime = ${element.completedPercentage.runtimeType}");
            // if (element.trainingStatus!.toLowerCase() != "completed" &&
            //     element.trainingType != "T") {
            // if (double.parse(element.completedPercentage ?? "0.0") < 100.0) {
            _trainingStatusAndProgress['InProgress'].add(element);
            // }
            // } else {
            //   _trainingStatusAndProgress['New'].add(element);
            // }
          }
        }
        if (training.d!.isNotEmpty) {
          _completedPerc = _trainingStatusAndProgress['Completed'].length /
              training.d!.length;
          _newPerc =
              _trainingStatusAndProgress['New'].length / training.d!.length;
          _inProgressPerc = _trainingStatusAndProgress['InProgress'].length /
              training.d!.length;
        }

        debugPrint(
            "completed = $_completedPerc, new = $_newPerc, progress = $_inProgressPerc");
        // debugPrint(
        //     "length inProgress = ${_trainingStatusAndProgress['InProgress'].length}");
        notifyListeners();
      }
    });
  }

  Future<dynamic> getLocation(BuildContext context,
      {required int trainingId}) async {
    loginD.D data = await UserPreference().getUser();

    Position? position = await geoLocation();

    if (position != null) {
      final locationData = {
        "UserID": "${data.userId}, T.id: $trainingId",
        "Latitude": position.latitude, //"12.907780"
        "Longitude": position.longitude // "77.606613"
      };

      Response response = await dio.post(locationUrl, data: locationData);
      if (response.statusCode == 200) {
        final location = jsonDecode(response.toString());

        return location;
      } else {
        throw Exception("Failed to fetch location");
      }
    } else {
      return null;
    }
  }

  Future<Position?> geoLocation() async {
    Position? currentPosition = await getCurrentPosition();
    if (currentPosition != null) {
      return currentPosition;
    } else {
      return null;
    }
  }

  static Future<Position?> getCurrentPosition() async {
    Position? currentPosition;
    try {
      if (await checkLocationPermission()) {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
      } else if (await requestLocationPermission()) {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint(
          "Error fetching current position: $e. Falling back to last known position.");
      try {
        currentPosition = await Geolocator.getLastKnownPosition();
      } catch (ex) {
        debugPrint("Error fetching last known position: $ex");
      }
    }
    return currentPosition;
  }

  /// Check Location Permission
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        {
          return true;
        }
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        {
          return await requestLocationPermission();
        }
      default:
        {
          return await requestLocationPermission();
        }
    }
  }

  /// Request Location Permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission requestPermission = await Geolocator.requestPermission();
    switch (requestPermission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        {
          return true;
        }
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        {
          return false;
        }
      default:
        {
          return false;
        }
    }
  }

  Future<Training> getTrainingData({required String isMandatory}) async {
    loginD.D data = await UserPreference().getUser();
    print("Data, ${jsonEncode(data)}");

    final trainingData = {
      "UserId": data.userId,
      "Department": data.department,
      "LangId": data.language.toString(),
      "Mandatory": isMandatory,
    };

    Response response = await dio.post(trainingUrl, data: trainingData);

    if (response.statusCode == 200) {
      final training = Training.fromJson(jsonDecode(response.toString()));
      return training;
    } else {
      throw Exception("Failed to fetch training");
    }
  }

  /// trying to update in progress list
/*
  Future<void> getImProgressData({required String isMandatory}) async {
    log('getImProgressData');
isLoading  = true;
    loginD.D data = await UserPreference().getUser();
    final trainingData = {
      "UserId": data.userId,
      "Department": data.department,
      "LangId": data.language.toString(),
      "Mandatory": isMandatory,
    };
    Response response = await dio.post(trainingUrl, data: trainingData);
    if (response.statusCode == 200) {
      _trainingStatusAndProgress['InProgress'].clear();
      final training = Training.fromJson(jsonDecode(response.toString()));
      for (var element in training.d!) {
        if (element.trainingStatus!.toLowerCase() == "inprogress") {
          _trainingStatusAndProgress['InProgress'].add(element);
        }
      }
      isLoading  = true;
      log('training length - ${_trainingStatusAndProgress['InProgress'].length}');
      if (training.d!.isNotEmpty) {
        _inProgressPerc = _trainingStatusAndProgress['InProgress'].length /
            training.d!.length;
      }
      notifyListeners();
    }
  }
*/

  // Stream<Training> getOtherTrainingStream() {
  //   StreamController<Training> controller = StreamController<Training>();

  //   UserPreference().getUser().then((value) {
  //     loginD.D data = value;

  //     final otherTrainingData = {
  //       "UserId": data.userId,
  //     };

  //     dio.post(getOtherTrainingsUrl, data: otherTrainingData).then((response) {
  //       if (response.statusCode == 200) {
  //         final training = Training.fromJson(jsonDecode(response.toString()));
  //         controller.add(training);
  //         _otherTrainingListLength = training.d!.length.toDouble();
  //         debugPrint("number of other = $_otherTrainingListLength");
  //         notifyListeners();
  //       } else {
  //         controller.addError("Failed to fetch training");
  //       }
  //       controller.close();
  //     }).catchError((error) {
  //       controller.addError(error.toString());
  //       controller.close();
  //     });
  //   });

  //   return controller.stream;
  // }

  Future<Training> getOtherTrainingData() async {
    loginD.D data = await UserPreference().getUser();

    final otherTrainingData = {
      "UserId": data.userId,
    };

    Response response =
        await dio.post(getOtherTrainingsUrl, data: otherTrainingData);

    if (response.statusCode == 200) {
      final training = Training.fromJson(jsonDecode(response.toString()));
      _otherTrainingListLength = training.d!.length.toDouble();
      debugPrint("number of other = $_otherTrainingListLength");
      notifyListeners();
      return training;
    } else {
      throw Exception("Failed to fetch training");
    }
  }

  Stream<Training> getExploreTrainingByDeptStream(
      {required String department}) {
    StreamController<Training> controller = StreamController<Training>();

    UserPreference().getUser().then((value) {
      // loginD.D data = value;

      final exploreTrainingData = {
        "Department": department,
      };

      dio
          .post(exploreTrainingByDeptUrl, data: exploreTrainingData)
          .then((response) {
        if (response.statusCode == 200) {
          final training = Training.fromJson(jsonDecode(response.toString()));
          controller.add(training);
        } else {
          controller.addError("Failed to fetch training");
        }
        controller.close();
      }).catchError((error) {
        controller.addError(error.toString());
        controller.close();
      });
    });

    return controller.stream;
  }

  Future getTrainingContent({required int trainingId}) async {
    TrainingContent trainingContent = TrainingContent();
    // Response response = await dio.post(trainingContentUrl,
    //     data: {"TrainingId": 1}).then((value) {
    //   _contentCompleteTrackPerc['totalPage'] =
    //       TrainingContent.fromJson(jsonDecode(value.toString())).d!.length;

    //   return value;
    // });
    //FIXME: uncomment this when all the documents are tested
    Response response = await dio.post(trainingContentUrl,
        data: {"TrainingId": "$trainingId"}).then((value) {
      _contentCompleteTrackPerc['totalPage'] =
          TrainingContent.fromJson(jsonDecode(value.toString())).d!.length;

      return value;
    });

    trainingContent = TrainingContent.fromJson(jsonDecode(response.toString()));

    return trainingContent.d;
  }

  Future<File> createFileOfPdfUrl(String url) async {
    Completer<File> completer = Completer();
    debugPrint("Start download file from internet!");
    try {
      // "https://berlin2017.droidcon.cod.newthinking.net/sites/global.droidcon.cod.newthinking.net/files/media/documents/Flutter%20-%2060FPS%20UI%20of%20the%20future%20%20-%20DroidconDE%2017.pdf";
      // final url = "https://pdfkit.org/docs/guide.pdf";
      // final url = "http://www.pdf995.com/samples/pdf.pdf";
      final filename = url.substring(url.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      debugPrint("Download files");
      debugPrint("${dir.path}/$filename");
      File file = File("${dir.path}/$filename");

      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  Future getTrainingTest({required int trainingId}) async {
    TrainingTest trainingTest = TrainingTest();
    debugPrint("getTrainingTest: $trainingId");

    Response response = await dio.post(
      trainingTestUrl,
      data: {"TrainingId": trainingId},
      // data: {"TrainingId": "2"},
    ).then((value) {
      _handleOptions = TrainingTest.fromJson(jsonDecode(value.toString()))
          .d!
          .map((e) => false)
          .toList();
      return value;
    });

    trainingTest = TrainingTest.fromJson(jsonDecode(response.toString()));
    _marks = 0;
    notifyListeners();
    return trainingTest.d;
  }

  void userSelect(
      {required String correctOption,
      required String selectedOption,
      required int questionIndex}) {
    // If the question has not been answered before, initialize it
    if (_selectedAnswers[questionIndex.toString()] == null) {
      _selectedAnswers[questionIndex.toString()] = {};
    }

    // Update the correct and selected options for the question
    _selectedAnswers[questionIndex.toString()]['correct'] = correctOption;
    _selectedAnswers[questionIndex.toString()]['selectedOption'] =
        selectedOption;
    notifyListeners();
  }

  void addTranscript(
      {required dynamic trainingId, required String trainingType}) async {
    var savedData = await UserPreference().getUser();

    Map<String, dynamic> addTranscriptData = {
      "UserId": savedData.userId!,
      "TrainingId": trainingId is int
          ? trainingId
          : (int.tryParse(trainingId.toString()) ?? trainingId),
      "Type": trainingType,
    };

    debugPrint("AddTrancript request body = $addTranscriptData");
    try {
      Response response =
          await dio.post(addTranscriptUrl, data: addTranscriptData);
      debugPrint(
          "AddTrancript response (${response.statusCode}) = ${response.data}");
    } catch (e) {
      debugPrint("Error in addTranscript: $e");
    }
  }

  Future<int> updateTranscript(
      {required dynamic trainingId,
      required String completedPerc,
      required String contentStatus,
      required String bothStatus,
      required String contentName}) async {
    var savedData = await UserPreference().getUser();

    Map<String, dynamic> updateTranscriptData = {
      "UserId": savedData.userId!,
      "EmailId": savedData.email!,
      "UserName": savedData.userName!,
      "TestName": contentName,
      "TrainingId": trainingId.toString(),
      "CompletedPercentage": completedPerc,
      "ContentStatus": contentStatus,
      "BothStattus": bothStatus,
    };
    int d = 0;
    debugPrint(
        "UpdateUserContentTrancript request body = $updateTranscriptData");
    try {
      Response response =
          await dio.post(updateTranscriptUrl, data: updateTranscriptData);
      debugPrint(
          "UpdateUserContentTrancript response (${response.statusCode}) = ${response.data}");
      d = jsonDecode(response.toString())['d'];
    } catch (e) {
      debugPrint("Error in updateTranscript: $e");
    }

    return d;
  }

  Future<int> updateTestTranscript({
    required dynamic trainingId,
    required String testDecision,
    required String testStatus,
    required String bothStatus,
    required String totalMarks,
    required String testName,
  }) async {
    var savedData = await UserPreference().getUser();

    Map<String, dynamic> updateTranscriptData = {
      "UserId": savedData.userId!,
      "EmailId": savedData.email!,
      "UserName": savedData.userName!,
      "TestName": testName,
      "TrainingId": trainingId.toString(),
      "TestDecision": testDecision,
      "TestStatus": testStatus,
      // "BothStattus": bothStatus,
      "BothStatus": bothStatus,
      "TotalMarks": totalMarks,
      // "TotalMarks": testStatus.toLowerCase() == "p" ? totalMarks : "0",
    };
    int d = 0;
    debugPrint("UpdateUserTestTrancript request body = $updateTranscriptData");
    try {
      Response response = await dio.post(updateUserTestTrancriptUrl,
          data: updateTranscriptData);
      debugPrint(
          "UpdateUserTestTrancript response (${response.statusCode}) = ${response.data}");
      d = jsonDecode(response.toString())['d'];
    } on DioException catch (e) {
      debugPrint(
          "UpdateUserTestTrancript error response (${e.response?.statusCode}) = ${e.response?.data}");
      debugPrint("Error in updateTestTranscript: $e");
    } catch (e) {
      debugPrint("Error in updateTestTranscript: $e");
    }

    return d;
  }

  Future<int> assignTrainingToEmployee(
      {required dynamic trainingId, required String department}) async {
    var savedData = await UserPreference().getUser();

    Map<String, dynamic> assignTrainingToEmployeeData = {
      "UserId": savedData.userId!,
      "TrainingId": trainingId is int
          ? trainingId
          : (int.tryParse(trainingId.toString()) ?? trainingId),
      "Departmnet": department
    };
    int d = 0;

    Response response = await dio.post(assignTrainingToEmployeeUrl,
        data: assignTrainingToEmployeeData);
    d = jsonDecode(response.toString())['d'];
    debugPrint("response = $d");

    return d;
    // return 1;
  }

  Future<int> addUserTestTrancriptDetails(
      {required String trainingId,
      required List<int> Qid,
      required List<int?> OpSelected}) async {
    // Map<String, dynamic> testDetailsData = {
    //   "Tid": 2,
    //   "QId": [10, 20, 30, 40, 50],
    //   "OpSelected": [1, 2, 3, 4, 4]
    // };
    Map<String, dynamic> testDetailsData = {
      "Tid": trainingId,
      "QId": Qid,
      "OpSelected": OpSelected
    };
    debugPrint("AddUserTestTrancriptDetails request body = $testDetailsData");
    Response response =
        await dio.post(addUserTestTrancriptDetailsUrl, data: testDetailsData);
    debugPrint(
        "AddUserTestTrancriptDetails response (${response.statusCode}) = ${response.data}");
    int d = jsonDecode(response.toString())['d'];
    return d;
  }

  Future<completeTrainingDetailsD.CompleteTrainingDetail>
      setCompletedTrainingDetails() async {
    // Map<String, dynamic> testDetailsData = {
    //   "Tid": 2,
    //   "QId": [10, 20, 30, 40, 50],
    //   "OpSelected": [1, 2, 3, 4, 4]
    // };
    loginD.D userData = await UserPreference().getUser();
    Map<String, dynamic> getCompletedTrainingDetailsData = {
      "UserId": userData.userId
    };
    Response response = await dio.post(getCompletedTrainingDetailsUrl,
        data: getCompletedTrainingDetailsData);
    // debugPrint("d = ${jsonDecode(response.toString()).runtimeType}");
    // completeTrainingDetailsD.D d = jsonDecode(response.toString());
    completeTrainingDetailsD.CompleteTrainingDetail completedTrainingDetails =
        completeTrainingDetailsD.CompleteTrainingDetail.fromJson(
            jsonDecode(response.toString()));
    // debugPrint("response getCompletedTrainingDetailsUrl = ${completedTrainingDetails.}");

    return completedTrainingDetails;
  }

  set setOtherTrainingList(trainingD.D training) {
    _otherTrainingList[training.id!] = training;
  }

  void resetUserSelect() {
    _selectedAnswers = {};
    notifyListeners();
  }

  void setPageTrack(List<int> pageNo, int totalPage) {
    _pageTrack = pageNo.fold(-1, math.max); //[1,2,3,1,3] //3
    if (_pageTrack == totalPage - 1) {
      _pageTrack = -1;

      if (totalPage > 0) {
        debugPrint("setting page swipe");
        _pageSwipeHint = false;
      }
    }
    // debugPrint("_pageTrack = $_pageTrack, totalPage = $totalPage");
    notifyListeners();
  }

  set addMarks(int mark) {
    _marks = mark;
    notifyListeners();
  }

  void setContentCompleteTrackPerc(onPage, totalPage) {
    // "onPage": 0,"totalPage":70
    debugPrint("totalPage from api = $totalPage");

    _contentCompleteTrackPerc['onPage'] = onPage;
    _contentCompleteTrackPerc['totalPage'] = totalPage;
    notifyListeners();
  }

  set setTrainingPageTrack(int page) {
    debugPrint("page training = $page ");
    _trainingPageTrack = page;
    notifyListeners();
  }

  set setCompletedPdfPages(int page) {
    _completedPdfPage = page;
    notifyListeners();
  }

  set setLatestPdfPage(
    int page,
  ) {
    debugPrint("setting page change = $page");
    _latestPdfPage = page;
    notifyListeners();
  }

  set setTotalPdfPage(int total) {
    debugPrint("setting total change = $total");
    _totalPage = total;
    notifyListeners();
  }

  set setPdfLoaded(bool pdfLoad) {
    debugPrint("setting page pdf load = $pdfLoad");
    _pdfLoaded = pdfLoad;
    notifyListeners();
  }

  set setIsScrollable(bool isScroll) {
    debugPrint("isScrollable pdf page = $isScroll");
    _isScrollable = isScroll;
    notifyListeners();
  }

  void reset() {
    _handleOptions = [];
    _selectedAnswers = {};
    _marks = 0;
    _pageTrack = -1;
    _pageSwipeHint = true;
    _contentCompleteTrackPerc = {"onPage": 0, "totalPage": 70};
    _trainingStatusAndProgress = {
      "Completed": [],
      "InProgress": [],
      "New": [],
      "Others": [],
    };

    _otherTrainingList = {};

    _inProgressPerc = 0.0;
    _completedPerc = 0.0;
    _newPerc = 0.0;

    _otherTrainingListLength = 0.0;
    _completedPdfPage = 0;
    notifyListeners();
  }
}
