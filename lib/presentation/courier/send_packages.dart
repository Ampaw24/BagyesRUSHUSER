import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/constant/key.dart';
import 'package:bagyesrushappusernew/presentation/courier/route_map.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:bagyesrushappusernew/services/courier.service.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:bagyesrushappusernew/states/courier.state.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'dart:math' show cos, sqrt, asin;

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SendPackages extends StatefulWidget {
  static final kInitialPosition = LatLng(-33.8567844, 151.213108);
  @override
  _SendPackagesState createState() => _SendPackagesState();
}

class _SendPackagesState extends State<SendPackages> {
  IOrder payload = IOrder();
  IUser user = IUser();
  var _storedImage;
  // For Screens
  bool packageTypeScreen = true;
  bool packageSizeWeightScreen = false;
  bool selectPickUpAddressScreen = false;
  bool selectDeliveryAddressScreen = false;
  bool confirmScreen = false;

  // For Package Type
  bool documents = false, parcel = false;

  // For Package Image and Weight Screen
  bool weight = false;
  bool packageUploaded = false;
  String packageImage = '';

  final heightController = TextEditingController();
  final widthController = TextEditingController();
  final depthController = TextEditingController();
  final weightController = TextEditingController();

  // For Pickup Address Screen
  PickResult? selectedPickupPlace;
  final pickupAddressController = TextEditingController();
  bool pickupAddress = false;

  // For Delivery Address Screen
  PickResult? selectedDeliveryPlace;
  final deliveryAddressController = TextEditingController();
  bool deliveryAddress = false;

  // Calculate Distance Between two Locations
  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return (12742 * asin(sqrt(a)));
  }

  Future<void> _takePictureByGallery() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (imageFile == null) {
      return;
    }

    // Directory appDir = await getApplicationDocumentsDirectory();
    // String fileName = imageFile.path;
    // final savedImage = File(imageFile.path).copy('${appDir.path}/$fileName');

    setState(() {
      _storedImage = File(imageFile.path);
    });

    if (_storedImage != null) {
      Uint8List imagebytes = await imageFile.readAsBytes();
      String base64string = base64.encode(imagebytes);

      setState(() {
        payload.img = base64string;
      });
    }
  }

  void placeOrder(BuildContext context) {
    user = context.read<AppState>().userInfo;
    var token = user.token;
    var id = user.id;
    if (payload.img == '') return;
    final data = new Map<String, String>();
    data['img'] = payload.img;
    data['weight'] = payload.weight;
    data['pickUpLocation'] = payload.pickUpLocation;
    data['deliveryLocation'] = payload.deliveryLocation;
    data['packageType'] = payload.packageType;
    data['customer'] = id;

    var response = placeCustomerOrder(
      token,
      data,
    ).then((response) => response.body);
    response.then((res) {
      var resp = jsonDecode(res) as Map<String, dynamic>;
      switch (resp['success']) {
        case true:
          CustomDialog.showSuccess(
            context: context,
            title: 'Hello',
            subtitle: 'Order Successfully Placed',
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
          );
          break;
        default:
          CustomDialog.showError(
            context: context,
            title: 'Oops!',
            subtitle: resp['message'],
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Hero(
      tag: 'Send Packages',
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: scaffoldBgColor,
          elevation: 0.0,
          titleSpacing: 0.0,
          title: Text(
            (packageTypeScreen)
                ? 'Select Package Type'
                : (packageSizeWeightScreen)
                ? 'Enter Package Size and Weight'
                : (selectPickUpAddressScreen)
                ? 'Select Pickup Address'
                : (selectDeliveryAddressScreen)
                ? 'Select Delivery Address'
                : (confirmScreen)
                ? 'Confirm Details'
                : '',
            style: appBarBlackTextStyle,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: blackColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: (packageTypeScreen)
                  ? selectPackageTypeScreen()
                  : (packageSizeWeightScreen)
                  ? enterPackageSizeWeightScreen()
                  : (selectPickUpAddressScreen)
                  ? selectPickupAddressScreenCode()
                  : (selectDeliveryAddressScreen)
                  ? selectDeliveryAddressScreenCode()
                  : (confirmScreen)
                  ? confirmScreenCode()
                  : Container(),
            ),
            Container(
              width: width,
              height: 85.0,
              color: whiteColor,
              alignment: Alignment.center,
              padding: EdgeInsets.all(fixPadding * 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  (packageTypeScreen) ? Container() : backButton(),
                  continueButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  selectPackageTypeScreen() {
    double width = MediaQuery.of(context).size.width;
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.all(fixPadding * 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // For Document Start
              InkWell(
                onTap: () {
                  setState(() {
                    documents = true;
                    parcel = false;
                    payload.packageType = 'documents';
                  });
                },
                child: Container(
                  width: (width - (fixPadding * 6.0)) / 2.0,
                  child: Column(
                    children: [
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        padding: EdgeInsets.only(
                          top: fixPadding * 2.0,
                          bottom: fixPadding * 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: greyColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            width: 0.8,
                            color: (documents)
                                ? primaryColor
                                : greyColor.withOpacity(0.2),
                          ),
                        ),
                        child: Container(
                          width: (width - (fixPadding * 6.0)) / 2.0,
                          padding: EdgeInsets.only(right: fixPadding * 2.0),
                          height: 170.0,
                          alignment: Alignment.topRight,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/icons/document_type.png',
                              ),
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          child: Container(
                            width: 26.0,
                            height: 26.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (documents) ? primaryColor : greyColor,
                              borderRadius: BorderRadius.circular(13.0),
                              border: Border.all(
                                width: 1.0,
                                color: (documents) ? primaryColor : greyColor,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              color: (documents) ? whiteColor : greyColor,
                              size: 18.0,
                            ),
                          ),
                        ),
                      ),
                      heightSpace,
                      Text('Documents', style: blackLargeTextStyle),
                    ],
                  ),
                ),
              ),
              // For Document End

              // For Parcel Start
              InkWell(
                onTap: () {
                  setState(() {
                    documents = false;
                    parcel = true;
                    payload.packageType = 'parcel';
                  });
                },
                child: Container(
                  width: (width - (fixPadding * 6.0)) / 2.0,
                  child: Column(
                    children: [
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        padding: EdgeInsets.only(
                          top: fixPadding * 2.0,
                          bottom: fixPadding * 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: greyColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            width: 0.8,
                            color: (parcel)
                                ? primaryColor
                                : greyColor.withOpacity(0.2),
                          ),
                        ),
                        child: Container(
                          width: (width - (fixPadding * 6.0)) / 2.0,
                          padding: EdgeInsets.only(right: fixPadding * 2.0),
                          height: 170.0,
                          alignment: Alignment.topRight,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/icons/parcel_type.png'),
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          child: Container(
                            width: 26.0,
                            height: 26.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (parcel) ? primaryColor : greyColor,
                              borderRadius: BorderRadius.circular(13.0),
                              border: Border.all(
                                width: 1.0,
                                color: (parcel) ? primaryColor : greyColor,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              color: (parcel) ? whiteColor : greyColor,
                              size: 18.0,
                            ),
                          ),
                        ),
                      ),
                      heightSpace,
                      Text('Parcel', style: blackLargeTextStyle),
                    ],
                  ),
                ),
              ),
              // For Parcel End
            ],
          ),
        ),
      ],
    );
  }

  enterPackageSizeWeightScreen() {
    double width = MediaQuery.of(context).size.width;
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.all(fixPadding * 2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: 20, bottom: 50),
                width: width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.all(10),
                      child: Image.asset(
                        AssetImages.bagyesLogo,
                        fit: BoxFit.contain,
                      ),
                    ),
                    InkWell(
                      onTap: () => {
                        _takePictureByGallery(),
                        setState(() {
                          packageUploaded = true;
                        }),
                      },
                      child: _storedImage != null
                          ? Image.file(
                              _storedImage,
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.fitHeight,
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Icon(Icons.arrow_upward, size: 40),
                            ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Text('Tap to upload image'),
                    ),
                  ],
                ),
              ),
              // Weight Start
              Text('Weight', style: primaryColorHeadingTextStyle),
              heightSpace,
              Container(
                width: width - (fixPadding * 4.0),
                height: 50.0,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    width: 0.8,
                    color: greyColor.withValues(alpha: 0.6),
                  ),
                ),
                child: TextField(
                  style: inputTextStyle,
                  keyboardType: TextInputType.number,
                  controller: weightController,
                  decoration: InputDecoration(
                    hintText: 'Please Enter Package Weight in kg',
                    hintStyle: inputTextStyle,
                    contentPadding: EdgeInsets.all(10.0),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) {
                    if (weightController.text != '') {
                      setState(() {
                        weight = true;
                        payload.weight = v.trim();
                      });
                    } else {
                      setState(() {
                        weight = false;
                      });
                    }
                  },
                ),
              ),
              heightSpace,
              Text('Enter weight in kg', style: infoTextStyle),
              // Weight End
            ],
          ),
        ),
      ],
    );
  }

  // Pickup Address Screen Start
  selectPickupAddressScreenCode() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return ListView(
      children: [
        Container(
          width: width,
          height: height - 85.0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  child: Text("Load Google Map"),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return PlacePicker(
                            apiKey: googleMapKey,
                            initialPosition: SendPackages.kInitialPosition,
                            useCurrentLocation: true,
                            selectInitialPosition: true,

                            //usePlaceDetailSearch: true,
                            onPlacePicked: (result) {
                              selectedPickupPlace = result;
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                            selectedPlaceWidgetBuilder:
                                (_, selectedPlace, state, isSearchBarFocused) {
                                  return isSearchBarFocused
                                      ? Container()
                                      : FloatingCard(
                                          bottomPosition: 0.0,
                                          leftPosition: 0.0,
                                          rightPosition: 0.0,
                                          width: 500,
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child:
                                              state == SearchingState.Searching
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : ElevatedButton(
                                                  child: Text(
                                                    "Pick This Place",
                                                  ),
                                                  onPressed: () {
                                                    print(
                                                      selectedPlace!
                                                          .geometry!
                                                          .location,
                                                    );
                                                    Navigator.pop(
                                                      context,
                                                      selectedPlace,
                                                    );
                                                    setState(() {});
                                                  },
                                                ),
                                        );
                                },
                          );
                        },
                      ),
                    );

                    setState(() {
                      selectedPickupPlace = result;
                    });
                  },
                ),
                Container(
                  padding: EdgeInsets.all(fixPadding * 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Place marker on google map at pickup location',
                        style: greySmallTextStyle,
                      ),
                      heightSpace,
                      (selectedPickupPlace == null)
                          ? Container()
                          : Text(
                              selectedPickupPlace!.formattedAddress ?? "",
                              textAlign: TextAlign.center,
                              style: inputTextStyle,
                            ),
                      (selectedPickupPlace == null) ? Container() : heightSpace,
                      Text(
                        'Pickup Address',
                        style: primaryColorHeadingTextStyle,
                      ),
                      heightSpace,
                      Container(
                        width: width - (fixPadding * 4.0),
                        height: 120.0,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(
                            width: 0.8,
                            color: greyColor.withOpacity(0.6),
                          ),
                        ),
                        child: TextField(
                          style: inputTextStyle,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          controller: pickupAddressController,
                          decoration: InputDecoration(
                            hintText: 'Please enter exact pickup address',
                            hintStyle: inputTextStyle,
                            contentPadding: EdgeInsets.all(10.0),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) {
                            if (pickupAddressController.text != '') {
                              setState(() {
                                pickupAddress = true;
                                payload.pickUpLocation = v.trim();
                              });
                            } else {
                              setState(() {
                                pickupAddress = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // Pickup Address Screen End

  // Delivery Address Screen Start
  selectDeliveryAddressScreenCode() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return ListView(
      children: [
        Container(
          width: width,
          height: height - 85.0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  child: Text("Load Google Map"),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return PlacePicker(
                            apiKey: googleMapKey,
                            initialPosition: SendPackages.kInitialPosition,
                            useCurrentLocation: true,
                            selectInitialPosition: true,

                            //usePlaceDetailSearch: true,
                            onPlacePicked: (result) {
                              selectedDeliveryPlace = result;
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                            selectedPlaceWidgetBuilder:
                                (_, selectedPlace, state, isSearchBarFocused) {
                                  return isSearchBarFocused
                                      ? Container()
                                      : FloatingCard(
                                          bottomPosition: 0.0,
                                          leftPosition: 0.0,
                                          rightPosition: 0.0,
                                          width: 500,
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          child:
                                              state == SearchingState.Searching
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : ElevatedButton(
                                                  child: Text(
                                                    "Pick This Place",
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(
                                                      context,
                                                      selectedPlace,
                                                    );
                                                    setState(() {});
                                                  },
                                                ),
                                        );
                                },
                          );
                        },
                      ),
                    );

                    setState(() {
                      selectedDeliveryPlace = result;
                    });
                  },
                ),
                Container(
                  padding: EdgeInsets.all(fixPadding * 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Place marker on google map at delivery location',
                        style: greySmallTextStyle,
                      ),
                      heightSpace,
                      (selectedDeliveryPlace == null)
                          ? Container()
                          : Text(
                              selectedDeliveryPlace!.formattedAddress ?? "",
                              textAlign: TextAlign.center,
                              style: inputTextStyle,
                            ),
                      (selectedDeliveryPlace == null)
                          ? Container()
                          : heightSpace,
                      Text(
                        'Delivery Address',
                        style: primaryColorHeadingTextStyle,
                      ),
                      heightSpace,
                      Container(
                        width: width - (fixPadding * 4.0),
                        height: 120.0,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(
                            width: 0.8,
                            color: greyColor.withOpacity(0.6),
                          ),
                        ),
                        child: TextField(
                          style: inputTextStyle,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          controller: deliveryAddressController,
                          decoration: InputDecoration(
                            hintText: 'Please enter exact pickup address',
                            hintStyle: inputTextStyle,
                            contentPadding: EdgeInsets.all(10.0),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) {
                            if (deliveryAddressController.text != '') {
                              setState(() {
                                deliveryAddress = true;
                                payload.deliveryLocation = v.trim();
                              });
                            } else {
                              setState(() {
                                deliveryAddress = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // Delivery Address Screen End

  // Confirm Screen Start
  confirmScreenCode() {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomSheet: Wrap(
        children: [
          Material(
            elevation: 7.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    right: fixPadding * 2.0,
                    left: fixPadding * 2.0,
                    top: fixPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Start
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pickup', style: blackLargeTextStyle),
                            heightSpace,
                            Text(
                              pickupAddressController.text,
                              style: inputTextStyle,
                            ),
                          ],
                        ),
                      ),
                      // Pickup End
                      // Delivery Start
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery', style: blackLargeTextStyle),
                            heightSpace,
                            Text(
                              deliveryAddressController.text,
                              style: inputTextStyle,
                            ),
                          ],
                        ),
                      ),
                      // Delivery End
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.only(
                    right: fixPadding * 2.0,
                    left: fixPadding * 2.0,
                    bottom: fixPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size Start
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size', style: blackLargeTextStyle),
                            heightSpace,
                            Text(
                              '${heightController.text} x ${widthController.text} x ${depthController.text} cm',
                              style: inputTextStyle,
                            ),
                          ],
                        ),
                      ),
                      // Size End
                      // Weight Start
                      Container(
                        width: (width - (fixPadding * 6.0)) / 2.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weight', style: blackLargeTextStyle),
                            heightSpace,
                            Text(
                              '${weightController.text} kg',
                              style: inputTextStyle,
                            ),
                          ],
                        ),
                      ),
                      // Weight End
                    ],
                  ),
                ),
                Container(
                  color: lightPrimaryColor,
                  padding: EdgeInsets.all(fixPadding),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Distance: ${(calculateDistance(selectedPickupPlace!.geometry!.location.lat, selectedPickupPlace!.geometry!.location.lng, selectedDeliveryPlace!.geometry!.location.lat, selectedDeliveryPlace!.geometry!.location.lng)).toStringAsFixed(2)} km',
                        style: primaryColorHeadingTextStyle,
                      ),
                      SizedBox(height: 5.0),
                      Text('Price: \$15', style: primaryColorHeadingTextStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RouteMap(
        sourceLat: selectedPickupPlace!.geometry!.location.lat,
        sourceLang: selectedPickupPlace!.geometry!.location.lng,
        destinationLat: selectedDeliveryPlace!.geometry!.location.lat,
        destinationLang: selectedDeliveryPlace!.geometry!.location.lng,
      ),
    );
  }
  // Confirm Screen End

  // Back Button Start
  backButton() {
    double width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () {
        if (packageSizeWeightScreen) {
          setState(() {
            packageTypeScreen = true;
            packageSizeWeightScreen = false;
          });
        }
        if (selectPickUpAddressScreen) {
          setState(() {
            selectPickUpAddressScreen = false;
            packageSizeWeightScreen = true;
          });
        }

        if (selectDeliveryAddressScreen) {
          setState(() {
            selectDeliveryAddressScreen = false;
            selectPickUpAddressScreen = true;
          });
        }

        if (confirmScreen) {
          setState(() {
            confirmScreen = false;
            selectDeliveryAddressScreen = true;
          });
        }
      },
      child: Container(
        width: (width - (fixPadding * 6.0)) / 2.0,
        padding: EdgeInsets.all(fixPadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(width: 1.0, color: blackColor),
        ),
        child: Text('Back', style: blackLargeTextStyle),
      ),
    );
  }
  // Back Button End

  // Continue Button Start
  continueButton() {
    double width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () {
        if (packageTypeScreen) {
          if (documents || parcel) {
            setState(() {
              packageTypeScreen = false;
              packageSizeWeightScreen = true;
            });
          }
        } else if (packageSizeWeightScreen) {
          if (packageUploaded && weight) {
            setState(() {
              packageSizeWeightScreen = false;
              selectPickUpAddressScreen = true;
            });
          }
        } else if (selectPickUpAddressScreen) {
          if (pickupAddress) {
            setState(() {
              selectPickUpAddressScreen = false;
              selectDeliveryAddressScreen = true;
            });
          }
        } else if (selectDeliveryAddressScreen) {
          if (deliveryAddress) {
            setState(() {
              selectDeliveryAddressScreen = false;
              confirmScreen = true;
            });
          }
        } else if (confirmScreen) {
          AppNavigator.toPayment(context);
        }
      },
      child: Container(
        width: (width - (fixPadding * 6.0)) / 2.0,
        padding: EdgeInsets.all(fixPadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            width: 1.0,
            color: (packageTypeScreen)
                ? (documents || parcel)
                      ? primaryColor
                      : greyColor
                : (packageSizeWeightScreen)
                ? (packageUploaded && weight)
                      ? primaryColor
                      : greyColor
                : (selectPickUpAddressScreen)
                ? (pickupAddress)
                      ? primaryColor
                      : greyColor
                : (selectDeliveryAddressScreen)
                ? (deliveryAddress)
                      ? primaryColor
                      : greyColor
                : (confirmScreen)
                ? primaryColor
                : greyColor,
          ),
          color: (packageTypeScreen)
              ? (documents || parcel)
                    ? primaryColor
                    : greyColor
              : (packageSizeWeightScreen)
              ? (packageUploaded && weight)
                    ? primaryColor
                    : greyColor
              : (selectPickUpAddressScreen)
              ? (pickupAddress)
                    ? primaryColor
                    : greyColor
              : (selectDeliveryAddressScreen)
              ? (deliveryAddress)
                    ? primaryColor
                    : greyColor
              : (confirmScreen)
              ? primaryColor
              : greyColor,
        ),
        child: Text(
          (confirmScreen) ? 'Pay' : 'Continue',
          style: whiteLargeTextStyle,
        ),
      ),
    );
  }

  // Continue Button End
}
