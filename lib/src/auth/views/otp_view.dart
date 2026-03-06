import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import '../../../constant/constant.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../../core/router/router.dart';

class OTPView extends StatefulWidget {
  const OTPView({super.key});

  @override
  _OTPViewState createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final TextEditingController _otpController = TextEditingController();

  void signup(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final storedData = authViewModel.state.signupData;

    // Check if we have stored signup data (from signup flow) or just phone (from login flow)
    final data = storedData != null
        ? {...storedData, 'otp': _otpController.text.trim()}
        : {
            'phone': authViewModel.state.user?.phone ?? '',
            'otp': _otpController.text.trim(),
          };

    authViewModel.signup(data).then((_) {
      final state = authViewModel.state;
      if (state.status == AuthStatus.authenticated) {
        AppNavigator.toHome(context);
      } else if (state.status == AuthStatus.error) {
        CustomDialog.showError(
          context: context,
          title: 'Oops!',
          subtitle: state.errorMessage ?? 'Verification failed',
          iconPath: AssetImages.bagyesLogo,
          isLottie: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final authViewModel = context.watch<AuthViewModel>();
    final loading = authViewModel.state.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
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
            child: ListView(
              children: [
                Container(
                  padding: EdgeInsets.all(fixPadding * 2.0),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Verify your phone number',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'Enter the OTP sent to your mobile number',
                        style: greySmallTextStyle,
                      ),
                      SizedBox(height: 50.0),
                      Container(
                        width: width / 1.5,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 150.0,
                              height: 50.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  width: 0.2,
                                  color: Colors.grey,
                                ),
                              ),
                              child: TextField(
                                controller: _otpController,
                                style: blackHeadingTextStyle,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(18.0),
                                  border: InputBorder.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(top: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Didn\'t receive a code?',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () => authViewModel.sendOtp(
                                '',
                              ), // Should pass phone
                              child: Text(
                                'Request again',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 30),
                        child: InkWell(
                          onTap: () {
                            if (!loading) {
                              signup(context);
                            }
                          },
                          child: AnimatedContainer(
                            width: width,
                            height: buttonHeight,
                            padding: EdgeInsets.all(fixPadding * 1.0),
                            duration: Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.red,
                            ),
                            child: loading
                                ? SpinKitCircle(size: 20, color: Colors.white)
                                : Text(
                                    authViewModel.state.signupData != null
                                        ? 'Verify and Create Account'
                                        : 'Verify',
                                    style: whiteBottonTextStyle,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
