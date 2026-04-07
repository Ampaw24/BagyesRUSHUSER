import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:bagyesrushappusernew/constant/baseurl.dart';

Future<http.Response> placeCustomerOrder(String token, Map<String, dynamic> data) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  return http.post(
    Uri.parse("$BASEURL/orders/init"),
    headers: headers,
    body: jsonEncode(data),
  );
}

Future<http.Response> getCustomerOrders(String token, String id) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    "Access-Control-Allow-Origin": "*"
  };
  return http.get(Uri.parse("$BASEURL/orders/customer/$id"), headers: headers);
}
