import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:flutter/material.dart';

class Payment extends StatefulWidget {
  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  bool amazon = true,
      card = false,
      paypal = false,
      skrill = false,
      cashOn = false;

  successOrderDialog() {
    CustomDialog.showSuccess(
      context: context,
      title: 'Success!',
      subtitle: 'Order Successfully Placed',
      iconPath: AssetImages.bagyesLogo,
      isLottie: false,
    );

    Future.delayed(const Duration(milliseconds: 3000), () {
      AppNavigator.toHome(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 1.0,
        titleSpacing: 0.0,
        title: Text('Payment', style: appBarTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: blackColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 5.0,
        child: Container(
          color: Colors.white,
          width: width,
          height: 70.0,
          alignment: Alignment.center,
          child: InkWell(
            onTap: () => successOrderDialog(),
            borderRadius: BorderRadius.circular(30.0),
            child: Container(
              width: width - fixPadding * 2.0,
              height: 50.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: primaryColor,
              ),
              child: Text('Continue', style: whiteBottonTextStyle),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            width: width,
            padding: EdgeInsets.all(fixPadding * 2.0),
            color: lightPrimaryColor,
            child: Text('Pay \$15', style: blackLargeTextStyle),
          ),
          getPaymentTile(
            'Pay on Delivery',
            'assets/payment_icon/cash_on_delivery.png',
          ),
          getPaymentTile('Amazon Pay', 'assets/payment_icon/amazon_pay.png'),
          getPaymentTile('Card', 'assets/payment_icon/card.png'),
          getPaymentTile('PayPal', 'assets/payment_icon/paypal.png'),
          getPaymentTile('Skrill', 'assets/payment_icon/skrill.png'),
          Container(height: fixPadding * 2.0),
        ],
      ),
    );
  }

  getPaymentTile(String title, String imgPath) {
    return InkWell(
      onTap: () {
        if (title == 'Pay on Delivery') {
          setState(() {
            cashOn = true;
            amazon = false;
            card = false;
            paypal = false;
            skrill = false;
          });
        } else if (title == 'Amazon Pay') {
          setState(() {
            cashOn = false;
            amazon = true;
            card = false;
            paypal = false;
            skrill = false;
          });
        } else if (title == 'Card') {
          setState(() {
            cashOn = false;
            amazon = false;
            card = true;
            paypal = false;
            skrill = false;
          });
        } else if (title == 'PayPal') {
          setState(() {
            cashOn = false;
            amazon = false;
            card = false;
            paypal = true;
            skrill = false;
          });
        } else if (title == 'Skrill') {
          setState(() {
            cashOn = false;
            amazon = false;
            card = false;
            paypal = false;
            skrill = true;
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          right: fixPadding * 2.0,
          left: fixPadding * 2.0,
          top: fixPadding * 2.0,
        ),
        padding: EdgeInsets.all(fixPadding * 2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
          border: Border.all(
            width: 1.0,
            color: (title == 'Pay on Delivery')
                ? (cashOn)
                      ? primaryColor
                      : Colors.grey[300]!
                : (title == 'Amazon Pay')
                ? (amazon)
                      ? primaryColor
                      : Colors.grey[300]!
                : (title == 'Card')
                ? (card)
                      ? primaryColor
                      : Colors.grey[300]!
                : (title == 'PayPal')
                ? (paypal)
                      ? primaryColor
                      : Colors.grey[300]!
                : (skrill)
                ? primaryColor
                : Colors.grey[300]!,
          ),
          color: whiteColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 70.0,
                  child: Image.asset(
                    imgPath,
                    width: 70.0,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                widthSpace,
                Text(title, style: primaryColorHeadingTextStyle),
              ],
            ),
            Container(
              width: 20.0,
              height: 20.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  width: 1.5,
                  color: (title == 'Pay on Delivery')
                      ? (cashOn)
                            ? primaryColor
                            : Colors.grey[300]!
                      : (title == 'Amazon Pay')
                      ? (amazon)
                            ? primaryColor
                            : Colors.grey[300]!
                      : (title == 'Card')
                      ? (card)
                            ? primaryColor
                            : Colors.grey[300]!
                      : (title == 'PayPal')
                      ? (paypal)
                            ? primaryColor
                            : Colors.grey[300]!
                      : (skrill)
                      ? primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Container(
                width: 10.0,
                height: 10.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: (title == 'Pay on Delivery')
                      ? (cashOn)
                            ? primaryColor
                            : Colors.transparent
                      : (title == 'Amazon Pay')
                      ? (amazon)
                            ? primaryColor
                            : Colors.transparent
                      : (title == 'Card')
                      ? (card)
                            ? primaryColor
                            : Colors.transparent
                      : (title == 'PayPal')
                      ? (paypal)
                            ? primaryColor
                            : Colors.transparent
                      : (skrill)
                      ? primaryColor
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
