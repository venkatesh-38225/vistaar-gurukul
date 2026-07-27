import 'package:hive/hive.dart';
import '../model/login.dart';

class UserPreference {
  Future<bool> setUser(D userData) async {
    final box = await Hive.openBox('userBox');
    box.put('userData', userData.toJson());
    return true;
  }

  // Future<D> getUser() async {
  //   final box = await Hive.openBox('userBox');
  //   var userData = Map<String, dynamic>.from(box.get('userData') as Map);
  //   return D.fromJson(userData);
  // }

  Future<D> getUser() async {
    final box = await Hive.openBox('userBox');
    final storeData = box.get('userData');

    if (storeData == null){
      return D(
        userId: "54321",
        userName: "Demo User",
        role: "User",
        status: "Active",
        language: 1,
        department: "Information & Technology"
      );
    }
    var userData = Map<String, dynamic>.from(box.get('userData') as Map);
    return D.fromJson(userData);
  }

  void removeUser() async {
    final box = await Hive.openBox('userBox');
    box.delete('userData');
  }

  Future<String> getStatus() async {
    final box = await Hive.openBox('userBox');
    var userData = box.get('userData');
    return userData != null ? userData['Status'] : "Failure";
  }
}
