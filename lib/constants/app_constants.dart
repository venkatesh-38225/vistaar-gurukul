import 'package:gurukul/main.dart';

const imageHero = "imageHero";
const notificationChannelId = 'gurukul';
const noticiationChannelName = 'gurukulName';

//https://productivity.vistaarfinance.net.in:448/Gurukul_docs

String get baseURL => environment!.baseUrl;

// AUTH URLs
String get authBaseUrl => environment!.authBaseUrl;
String get loginUrl => "$authBaseUrl/Login";
String get sendOtpUrl => "$authBaseUrl/otp/SendOtp";
String get verifyOtpUrl => "$authBaseUrl/otp/verifyOTP";
const String authApiKey = "ht9AfQrZmJnu0Gxl";
const String authSource = "Gurukul";

//FETCH TRAINING
String get trainingContentUrl => "$baseURL/GetTrainingContent";
String get trainingTestUrl => "$baseURL/GetTest";
String get trainingUrl => "$baseURL/GetTraining";
String get locationUrl => "$baseURL/ValidateGeoLocation";
String get exploreTrainingByDeptUrl => "$baseURL/GetTrainingByDept";
String get getOtherTrainingsUrl => "$baseURL/GetOtherTrainings";

//ADD, UPDATE GET TRAINING STATUS
String get addTranscriptUrl => "$baseURL/AddTrancript";
String get updateTranscriptUrl => "$baseURL/UpdateUserContentTrancript";
String get updateUserTestTrancriptUrl => "$baseURL/UpdateUserTestTrancript";
String get addUserTestTrancriptDetailsUrl =>
    "$baseURL/AddUserTestTrancriptDetails";
String get getCompletedTrainingDetailsUrl =>
    "$baseURL/GetCompletedTrainingDetails";

//ASSIGN TRAINING
String get assignTrainingToEmployeeUrl => "$baseURL/AssignTrainingToEmployee";

String get addAppKeyUrl => "$baseURL/AddAppKeyMapping";

const String API_TOKEN = "GURUKUL_TOKEN";

// Replace these placeholders before publishing the version-check feature.
const String appVersionApiKey = "ht9AfQrZmJnu0Gxl";
const String appStoreUrl =
    "https://play.google.com/store/apps/details?id=com.vistaar.coachapplication";

String get productivityBaseUrl => environment!.productivityBaseUrl;
String get appVersionUrl =>
    "$productivityBaseUrl/api/shared/GetAppVersion?Platform=Android&applicationName=Gurukul";

//DEV ASSETS
// const trainingContentAssetsUrl =>
//     "https://vistaarapis.vistaarfinance.net.in:469/Gurukul_docs";

//PROD ASSETS
// String get trainingContentAssetsUrl =>
//     "https://vistaarapis.vistaarfinance.net.in:469/Gurukul_docsProd";
String get trainingContentAssetsUrl => environment!.assetUrl;
