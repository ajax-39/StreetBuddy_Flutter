// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:street_buddy/constants.dart';

// class RazorpayService {
//   final _razorpay = Razorpay();
//   // Get Options from Sam
//   final Map<String, dynamic> _paymentOptions = {
//     'key': 'YOUR_KEY_HERE',
//     'amount': 100,
//     'name': 'Street Buddy',
//     'description': 'Payment for services',
//     'prefill': {'contact': '', 'email': ''}
//   };

//   open() => _razorpay.open(_paymentOptions);

//   initiate() {
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     // Do something when payment succeeds
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     // Do something when payment fails
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     // Do something when an external wallet is selected
//   }

//   dispose() => _razorpay.clear(); // Removes all listeners
// }
