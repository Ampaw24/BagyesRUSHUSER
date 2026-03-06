import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bagyesrushappusernew/constant/baseurl.dart';

abstract class IResponse {
  bool success = false;
  String message = '';
  Object data = Object();
}

class ISignup {
  String phone = '';
  String otp = '';
}

Future<http.Response> userSignup(data) {
  const headers = {
    'Content-Type': 'application/json',
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": 'true',
    "Access-Control-Allow-Headers":
        "Origin,Content-Type,Access-Control-Allow-Origin, Accept",
  };
  return http.post(Uri.parse("$BASEURL/customers/signup"),
      headers: headers, body: jsonEncode(data));
}
//TODO::  Auth 
Future<http.Response> sendOtp(data) {
  const headers = {
    'Content-Type': 'application/json',
    "Access-Control-Allow-Origin": "*",
  };
  return http.post(Uri.parse("$BASEURL/otp/send"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> updateUser(token, data) {
  const headers = {
    'Content-Type': 'application/json',
    "Access-Control-Allow-Origin": "*",
  };
  return http.post(Uri.parse("$BASEURL/otp/send"),
      headers: headers, body: data);
}

Future<http.Response> getDetails(token, id) {
  const headers = {
    'Content-Type': 'application/json',
    "Access-Control-Allow-Origin": "*",
  };
  return http.post(Uri.parse("$BASEURL/customers/details/$id"),
      headers: headers);
}
