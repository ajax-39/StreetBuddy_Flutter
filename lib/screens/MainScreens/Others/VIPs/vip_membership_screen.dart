import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class VIPMembershipScreen extends StatefulWidget {
  const VIPMembershipScreen({super.key});

  @override
  State<VIPMembershipScreen> createState() => _VIPMembershipScreenState();
}

class _VIPMembershipScreenState extends State<VIPMembershipScreen> {
  bool _isMonthlySelected = true;
  String _selectedPaymentMethod = 'debit'; // debit, credit, upi

  Razorpay? _razorpay;
  bool _isRazorpayInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    debugPrint('🔧 Initializing Razorpay...');
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isRazorpayInitialized = true;
      debugPrint('✅ Razorpay initialized successfully');
    } catch (e) {
      debugPrint('💥 Error initializing Razorpay: $e');
      _isRazorpayInitialized = false;
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing payment system: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing Razorpay instance...');
    _razorpay?.clear();
    debugPrint('✅ Razorpay disposed successfully');
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('🎉 Payment Success! Payment ID: ${response.paymentId}');
    debugPrint('✅ Order ID: ${response.orderId}');
    debugPrint('🔐 Signature: ${response.signature}');

    // Payment success logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment ID: ${response.paymentId}'),
            Text('Order ID: ${response.orderId}'),
            Text('Signature: ${response.signature}'),
            const SizedBox(height: 10),
            const Text('Your VIP membership has been activated!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint(
                  '🚪 Closing payment success dialog and navigating back');
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Failed! Error Code: ${response.code}');
    debugPrint('💥 Error Message: ${response.message}');

    // Payment error logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error Code: ${response.code}'),
            Text('Error Description: ${response.message}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔄 Closing payment error dialog');
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('👛 External Wallet Selected: ${response.walletName}');

    // External wallet logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External Wallet'),
        content: Text('External Wallet Name: ${response.walletName}'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('📱 Closing external wallet dialog');
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startPayment() {
    debugPrint('🚀 Starting payment process...');

    // Check if Razorpay is initialized
    if (!_isRazorpayInitialized || _razorpay == null) {
      debugPrint('❌ Razorpay not initialized!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Payment system not initialized. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the amount based on selected plan
    int amount = _isMonthlySelected ? 299 : 3000;
    String planType = _isMonthlySelected ? 'Monthly' : 'Yearly';

    debugPrint('💰 Amount: ₹$amount ($planType plan)');
    debugPrint('💳 Selected Payment Method: $_selectedPaymentMethod');

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key ID
      'amount': amount * 100, // Amount in paise (multiply by 100)
      'name': 'Street Buddy',
      'description': _isMonthlySelected
          ? 'VIP Monthly Membership'
          : 'VIP Yearly Membership',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': '8888888888', // Replace with user's contact
        'email': 'test@razorpay.com' // Replace with user's email
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    debugPrint('⚙️ Payment options configured:');
    debugPrint('  📋 Amount in paise: ${amount * 100}');
    debugPrint('  📝 Description: ${options['description']}');
    debugPrint('  🔑 Key: ${options['key']}');

    try {
      debugPrint('🎯 Opening Razorpay payment gateway...');
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('💥 Error starting payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VIP Membership',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Choose Your VIP Plan
              const Text(
                'Choose Your VIP Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Plan Card
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMonthlySelected = true;
                  });
                },
                child: Container(
                  height: 84,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isMonthlySelected
                          ? const Color(0xFFFF8C3B)
                          : Colors.grey.shade300,
                      width: _isMonthlySelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _isMonthlySelected
                        ? const Color(0xFFFFF4E6)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Billed monthly',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹299',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'per month',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isMonthlySelected
                                ? const Color(0xFFFF8C3B)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: _isMonthlySelected
                            ? const Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Color(0xFFFF8C3B),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Yearly Plan Card
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMonthlySelected = false;
                  });
                },
                child: Container(
                  height: 84,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_isMonthlySelected
                          ? const Color(0xFFFF8C3B)
                          : Colors.grey.shade300,
                      width: !_isMonthlySelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: !_isMonthlySelected
                        ? const Color(0xFFFFF4E6)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yearly',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Billed annually',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹3000',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'per year',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: !_isMonthlySelected
                                ? const Color(0xFFFF8C3B)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: !_isMonthlySelected
                            ? const Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Color(0xFFFF8C3B),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // VIP Benefits
              const Text(
                'VIP Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Benefits Grid
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBenefitBox(
                      icon: Icons.headphones,
                      color: Colors.deepPurple,
                      bgColor: const Color(0xFFF0E6FF),
                      title: 'Add Free Experience',
                    ),
                    const SizedBox(width: 12),
                    _buildBenefitBox(
                      icon: Icons.flash_on,
                      color: Colors.orange,
                      bgColor: const Color(0xFFFFF0E6),
                      title: 'Faster Access',
                    ),
                    const SizedBox(width: 12),
                    _buildBenefitBox(
                      icon: Icons.verified_user,
                      color: Colors.red,
                      bgColor: const Color(0xFFFFEEEE),
                      title: 'Verified VIP Badge',
                    ),
                    const SizedBox(width: 12),
                    _buildBenefitBox(
                      icon: Icons.article,
                      color: Colors.blue,
                      bgColor: const Color(0xFFE6F4FF),
                      title: 'Premium Content',
                    ),
                    const SizedBox(width: 12),
                    _buildBenefitBox(
                      icon: Icons.people,
                      color: Colors.green,
                      bgColor: const Color(0xFFE6FFE6),
                      title: 'VIP Networking',
                    ),
                    const SizedBox(width: 12),
                    _buildBenefitBox(
                      icon: Icons.support_agent,
                      color: Colors.purple,
                      bgColor: const Color(0xFFF5E6FF),
                      title: 'Priority Support',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Select a Payment Method
              const Text(
                'Select a Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Payment Methods
              _buildPaymentMethod(
                icon: Icons.credit_card,
                title: 'Debit Card',
                value: 'debit',
              ),

              const SizedBox(height: 12),

              _buildPaymentMethod(
                icon: Icons.credit_card,
                title: 'Credit card',
                value: 'credit',
              ),

              const SizedBox(height: 12),

              _buildPaymentMethod(
                icon: Icons.account_balance_wallet,
                title: 'UPI',
                value: 'upi',
              ),

              const SizedBox(height: 14),

              // Security Text
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '100% Secure Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Continue to Pay Button
              SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Pay ₹${_isMonthlySelected ? '299' : '3000'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitBox({
    required IconData icon,
    required Color color,
    required String title,
    required Color bgColor,
  }) {
    return Container(
      height: 99,
      width: 99,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final bool isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        height: 54,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF8C3B) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(0xFFFF8C3B),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
