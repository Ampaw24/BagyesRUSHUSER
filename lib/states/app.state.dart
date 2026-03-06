import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/auth.service.dart';

class IUser {
  String token = '';
  String phone = '';
  String name = '';
  String address = '';
  String id = '';
}

// define all state variables here;
class AppState with ChangeNotifier {
  IUser user = IUser();
  ISignup signupData = ISignup();

  get userInfo => user;
  get payload => signupData;

  void setPayload(ISignup data) {
    signupData.otp = data.otp;
    signupData.phone = data.phone;
  }

  void setID(IUser data) {
    user.id = data.id;
  }

  void setUser(data) {
    user = data;
  }

  void setUserName(IUser data) {
    user.name = data.name;
  }

  void setUserAddress(IUser data) {
    user.address = data.address;
  }

  void setUserToken(String token) {
    user.token = token;
  }

  void setUserPhone(IUser data) {
    user.phone = data.phone;
  }

  void loadProfile(Function callabck) async {
    try {
      var response = await getDetails(user.id, user.token)
          .then((res) => jsonDecode(res.body));
      if (response['success']) {
        user = response['data'];
        callabck();
      }
    } catch (err) {
      log(err.toString());
    }
  }
}
