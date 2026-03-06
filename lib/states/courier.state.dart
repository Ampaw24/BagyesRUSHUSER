import 'package:flutter/material.dart';

class IOrder {
  String img = '';
  String weight = '';
  String pickUpLocation = '';
  String deliveryLocation = '';
  String packageType = '';
  String customer = '';
}

class CourierState with ChangeNotifier {
  IOrder orderPayload = IOrder();

  get oPayload => orderPayload;

  void setOrderPayload(IOrder data) {
    orderPayload.img = data.img;
    orderPayload.weight = data.weight;
    orderPayload.customer = data.customer;
    orderPayload.deliveryLocation = data.deliveryLocation;
    orderPayload.pickUpLocation = data.pickUpLocation;
    orderPayload.packageType = data.packageType;
  }
}
