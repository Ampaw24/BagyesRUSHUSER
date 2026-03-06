import 'dart:convert';

import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/services/auth.service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/app.state.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String name = 'Ellison Perry';
  String phone = '123456789';
  String email = 'test@abc.com';
  var nameController = TextEditingController();
  var phoneController = TextEditingController();
  var emailController = TextEditingController();

  bool loading = false;
  IUser user = IUser();

  @override
  void initState() {
    super.initState();
    nameController.text = name;
    phoneController.text = phone;
    emailController.text = email;
  }

  Future<void> updateProfile(BuildContext context) async {
    try {
      user = context.read<AppState>().userInfo;
      var token = user.token;
      var id = user.id;
      Map<String, dynamic> data = {};
      String name = nameController.text;
      String email = nameController.text;

      if ((name == '') && (email == '')) {
        throw Exception('No update has been made');
      }

      data['name'] = name;

      if (email != '') {
        data['email'] = email;
      }

      setState(() {
        loading = true;
      });

      Map d = {"id": id, "data": data};

      Map<String, dynamic> response = await updateUser(
        token,
        d,
      ).then((value) => jsonDecode(value.body));

      setState(() {
        loading = false;
      });

      switch (response['success']) {
        case true:
          context.read<AppState>().loadProfile(() {
            setState(() {});
          });
          break;
        default:
          CustomDialog.showError(
            context: context,
            title: 'Oops!',
            subtitle: response['message'],
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
          );
          break;
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      CustomDialog.showError(
        context: context,
        title: 'Oops!',
        subtitle: e.toString(),
        iconPath: AssetImages.bagyesLogo,
        isLottie: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    changeFullName() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomDialog(
          config: CustomDialogConfig(
            title: "Change Full Name",
            subtitle: "Enter your full name below",
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
            showCancelButton: true,
            confirmText: 'Okay',
            cancelText: 'Cancel',
            onConfirm: () {
              setState(() {
                name = nameController.text;
              });
              Navigator.pop(context); // Manually pop the dialog
            },
            onCancel: () {
              Navigator.pop(context); // Manually pop the dialog
            },
            content: TextField(
              controller: nameController,
              style: blackBottonTextStyle,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Enter Your Full Name',
                hintStyle: greySmallTextStyle,
              ),
            ),
          ),
        ),
      );
    }

    changePassword() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomDialog(
          config: CustomDialogConfig(
            title: "Change Your Password",
            subtitle: "Update your security credentials",
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
            showCancelButton: true,
            confirmText: 'Okay',
            cancelText: 'Cancel',
            onConfirm: () {
              // TODO: Implement password change logic
            },
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Old Password',
                    hintStyle: greySmallTextStyle,
                  ),
                ),
                TextField(
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: greySmallTextStyle,
                  ),
                ),
                TextField(
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm New Password',
                    hintStyle: greySmallTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    changePhoneNumber() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomDialog(
          config: CustomDialogConfig(
            title: "Change Phone Number",
            subtitle: "Enter your new phone number below",
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
            showCancelButton: true,
            confirmText: 'Okay',
            cancelText: 'Cancel',
            onConfirm: () {
              setState(() {
                phone = phoneController.text;
              });
            },
            content: TextField(
              controller: phoneController,
              style: blackHeadingTextStyle,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
                hintStyle: greySmallTextStyle,
              ),
            ),
          ),
        ),
      );
    }

    changeEmail() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomDialog(
          config: CustomDialogConfig(
            title: "Change Email",
            subtitle: "Enter your new email address below",
            iconPath: AssetImages.bagyesLogo,
            isLottie: false,
            showCancelButton: true,
            confirmText: 'Okay',
            cancelText: 'Cancel',
            onConfirm: () {
              setState(() {
                email = emailController.text;
              });
            },
            content: TextField(
              controller: emailController,
              style: blackHeadingTextStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter Email',
                hintStyle: greySmallTextStyle,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(fixPadding),
              alignment: Alignment.center,
              child: Text('Save', style: blueSmallTextStyle),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Profile Image Start
              InkWell(
                onTap: _selectOptionBottomSheet,
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  margin: EdgeInsets.all(fixPadding * 4.0),
                  alignment: Alignment.bottomRight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(width: 2.0, color: whiteColor),
                    image: DecorationImage(
                      image: AssetImage('assets/user.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    height: 22.0,
                    width: 22.0,
                    margin: EdgeInsets.all(fixPadding / 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11.0),
                      border: Border.all(
                        width: 1.0,
                        color: whiteColor.withValues(alpha: 0.7),
                      ),
                      color: Colors.orange,
                    ),
                    child: Icon(Icons.add, color: whiteColor, size: 15.0),
                  ),
                ),
              ),
              // Profile Image End
              // Full Name Start
              InkWell(onTap: changeFullName, child: getTile('Full Name', name)),
              // Full Name End
              // Password Start
              InkWell(
                onTap: changePassword,
                child: getTile('Password', '******'),
              ),
              // Password End
              // Phone Start
              InkWell(onTap: changePhoneNumber, child: getTile('Phone', phone)),
              // Phone End
              // Email Start
              InkWell(onTap: changeEmail, child: getTile('Email', email)),
              // Email End
            ],
          ),
        ],
      ),
    );
  }

  getTile(String title, String value) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(
        right: fixPadding,
        left: fixPadding,
        bottom: fixPadding * 1.5,
      ),
      padding: EdgeInsets.only(
        right: fixPadding,
        left: fixPadding,
        top: fixPadding * 2.0,
        bottom: fixPadding * 2.0,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 1.5,
            spreadRadius: 1.5,
            color: Colors.grey[200]!,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: width - 80.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  width: (width - 80.0) / 2.4,
                  child: Text(title, style: greyNormalTextStyle),
                ),
                Container(
                  width: (width - 80.0) / 2.0,
                  child: Text(value, style: blackHeadingTextStyle),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.0,
            color: Colors.grey.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet for Select Options (Camera or Gallery) Start Here
  void _selectOptionBottomSheet() {
    double width = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          color: whiteColor,
          child: new Wrap(
            children: <Widget>[
              Container(
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: width,
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          'Choose Option',
                          textAlign: TextAlign.center,
                          style: blackHeadingTextStyle,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: width,
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.camera_alt,
                                color: Colors.black.withValues(alpha: 0.7),
                                size: 18.0,
                              ),
                              SizedBox(width: 10.0),
                              Text('Camera', style: inputTextStyle),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: width,
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.photo_album,
                                color: Colors.black.withOpacity(0.7),
                                size: 18.0,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Upload from Gallery',
                                style: inputTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Bottom Sheet for Select Options (Camera or Gallery) Ends Here
}
