import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import '../../../constant/constant.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/viewmodels/auth_state.dart';
import '../../../core/router/router.dart';

class OTPView extends StatefulWidget {
  const OTPView({super.key});

  @override
  _OTPViewState createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp(BuildContext context) {
    final vm = context.read<AuthViewmodel>();
    final pendingData = vm.pendingSignupData;

    final data = pendingData != null
        ? {...pendingData, 'otp': _otpController.text.trim()}
        : {'otp': _otpController.text.trim()};

    vm.signup(data);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewmodel>(
      builder: (context, vm, _) {
        // Side effects
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (vm.state is Registered) {
            AppNavigator.toHome(context);
          } else if (vm.state is AuthError) {
            final error = vm.state as AuthError;
            CustomDialog.showError(
              context: context,
              title: 'Oops!',
              subtitle: error.message,
              iconPath: AssetImages.bagyesLogo,
              isLottie: false,
            );
          }
        });

        final loading = vm.state is AuthLoading;
        final double width = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: scaffoldBgColor,
          appBar: AppBar(
            backgroundColor: scaffoldBgColor,
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: blackColor),
              onPressed: () => Navigator.pop(context),
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
                          const Text(
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
                          const SizedBox(height: 50.0),
                          SizedBox(
                            width: width / 1.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
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
                            margin: const EdgeInsets.only(top: 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Didn't receive a code?",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    final phone =
                                        vm.pendingSignupData?['phone']
                                                as String? ??
                                            '';
                                    vm.sendOtp(phone);
                                  },
                                  child: const Text(
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
                            margin: const EdgeInsets.only(top: 30),
                            child: InkWell(
                              onTap: loading
                                  ? null
                                  : () => _submitOtp(context),
                              child: AnimatedContainer(
                                width: width,
                                height: buttonHeight,
                                padding: EdgeInsets.all(fixPadding * 1.0),
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.red,
                                ),
                                child: loading
                                    ? const SpinKitCircle(
                                        size: 20,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        vm.pendingSignupData != null
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
      },
    );
  }
}
