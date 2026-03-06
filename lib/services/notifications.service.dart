import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:bagyesrushappusernew/constant/baseurl.dart';

Future<http.Response> getCustomerNotifications(token, id) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    "Access-Control-Allow-Origin": "*",
  };
  return http.post(Uri.parse("$BASEURL/notifications/customer/$id"),
      headers: headers);
}

Future<http.Response> updateNotification(token, data) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    "Access-Control-Allow-Origin": "*",
  };
  return http.put(Uri.parse("$BASEURL/notifications/update"),
      headers: headers, body: jsonEncode(data));
}
