// otp_provider.dart
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/constants.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPProvider extends ChangeNotifier { 
  late TwilioFlutter twilioFlutter;
  final Random _random = Random();
  String? _generatedOTP;
  String? phoneOTP;
  bool _isLoading = false;
  TextEditingController otpController = TextEditingController();
  bool _hasInitialOTPSent = false;
  bool get hasInitialOTPSent => _hasInitialOTPSent;
  bool isOTPhidden = true;

  void toggleOTPVisibility() {
    isOTPhidden = !isOTPhidden;
    notifyListeners();
  }

  void setInitialOTPSent() {
    _hasInitialOTPSent = true;
  }

  void reset() {
    _hasInitialOTPSent = false;
    resetOTP();
  }

  OTPProvider() {
    twilioFlutter = TwilioFlutter(
      accountSid: Constant.TWILIO_ACCOUNT_SID,
      authToken: Constant.TWILIO_AUTH_TOKEN,
      twilioNumber: Constant.TWILIO_PHONE_NUMBER,
    );
  }

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _generateOTP() {
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += _random.nextInt(10).toString();
    }
    _generatedOTP = otp;
    return otp;
  }

  Future<void> sendOTPViaEmail(String email) async {
    try {
      setLoading(true);
      final String otp = _generateOTP();

      debugPrint('✅Sending OTP: $otp to email: $email');

      final smtpServer = gmail(
        Constant.EMAIL_USERNAME,
        Constant.EMAIL_PASSWORD,
      );
      final message = Message()
        ..from = const Address(Constant.EMAIL_USERNAME, 'Street Buddy')
        ..recipients.add(email)
        ..subject = 'Your Street Buddy Verification Code'
        ..html = '''
          <h2>Welcome to Street Buddy!</h2>
          <p>Your verification code is: <strong>$otp</strong></p>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        ''';

      await send(message, smtpServer);
    } catch (e) {
      print('Error sending email OTP: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> sendOTPViaSMS(String phoneNumber) async {
    try {
      setLoading(true);
      String num = phoneNumber;
      final String otp = _generateOTP();

      debugPrint('✅Sending OTP: $otp to number: $num');

      await twilioFlutter.sendSMS(
        toNumber: num,
        messageBody:
            'Your Street Buddy verification code is: $otp. This code will expire in 10 minutes.',
      );
    } catch (e) {
      debugPrint('Error sending SMS OTP: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> sendOTPPhone(String phoneNumber) async {
    try {
      setLoading(true);
      String num = '+$phoneNumber';
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: num,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {},
        codeSent: (String verificationId, int? resendToken) {
          phoneOTP = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print('Error sending SMS OTP: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTP(String enteredOTP) async {
    try {
      setLoading(true);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_generatedOTP == null) {
        throw Exception('No OTP has been generated yet');
      }

      return enteredOTP == _generatedOTP;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTPPhone(String enteredOTP) async {
    try {
      setLoading(true);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_generatedOTP == null) {
        throw Exception('No OTP has been generated yet');
      }

      return true;
    } finally {
      setLoading(false);
    }
  }

  void resetOTP() {
    _generatedOTP = null;
    otpController.clear();
  }

  @override
  void dispose() {
    resetOTP();
    otpController.dispose();
    super.dispose();
  }
}
