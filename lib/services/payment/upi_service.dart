// import 'package:upi_india/upi_india.dart';

// class UpiService {
//   final _upiIndia = UpiIndia();

//   List<UpiApp>? apps;

//   Future<List<UpiApp>?> getapps() async {
//     await _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
//       apps = value;
//     }).catchError((e) {
//       apps = [];
//       print(e.toString());
//     });

//     return apps;
//   }

//   Future<UpiResponse> initiateTransaction(UpiApp app) async {
//     return _upiIndia.startTransaction(
//       app: app,
//       receiverUpiId: "8100382099@ptyes",
//       receiverName: 'Samvabya Sarkar',
//       amount: 1.00,
//       transactionRefId: '',
//     );
//   }

//   // Future<UpiTransactionResponse> doUpiTransation(ApplicationMeta appMeta) async {
//   //   final UpiTransactionResponse response = await upiPay.initiateTransaction(
//   //     amount: '100.00',
//   //     app: appMeta.upiApplication,
//   //     receiverName: 'John Doe',
//   //     receiverUpiAddress: 'john@doe',
//   //     transactionRef: 'UPITXREF0001',
//   //     transactionNote: 'A UPI Transaction',
//   //   );
//   //   print(response.status);
//   //   return response;
//   // }
// }
