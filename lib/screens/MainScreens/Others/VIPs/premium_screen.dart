// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
// TODO: fix compatibility issues with UPI Package
import 'package:flutter/material.dart';
// import 'package:street_buddy/services/payment/razorpay_service.dart';
import 'package:street_buddy/services/payment/upi_service.dart';
// import 'package:upi_india/upi_india.dart';
// import 'package:upi_pay/upi_pay.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // List<UpiApp>? apps;

  @override
  void initState() {
    super.initState();
    // RazorpayService().initiate();
  }

  @override
  void dispose() {
    super.dispose();
    // RazorpayService().dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1730125477357-03a906bde005?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'), // Add a premium-related image
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                colors: [Colors.black, Colors.deepPurple, Colors.pink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      'Go Premium\nUnleash Your \nPotential',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              // Features Section
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeatureCard(
                          icon: Icons.headset,
                          title: 'Ad-Free Experience',
                          description: 'No interruptions.',
                          backgroundColor: Colors.purple,
                        ),
                        FeatureCard(
                          icon: Icons.verified,
                          title: 'A verified badge',
                          description:
                              'Your audience can trust that you\'re a real person sharing your real stories.',
                          backgroundColor: Colors.blue,
                        ),
                        FeatureCard(
                          icon: Icons.high_quality,
                          title: 'Increased account protection',
                          description:
                              'Worry less about impersonation with proactive identity monitoring.',
                          backgroundColor: Colors.teal,
                        ),
                        FeatureCard(
                          icon: Icons.devices,
                          title: 'Enhanced support',
                          description:
                              'Contact a help agent via email or chat. At the moment, support is only available in some languages.',
                          backgroundColor: Colors.orange,
                        ),
                        AspectRatio(aspectRatio: 2 / 1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Subscribe Button - Sticky at Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(1),
              child: ElevatedButton(
                onPressed: () async {
                  // apps = await UpiService().getapps();
                  // apps = await UpiService().getapps();

                  // showModalBottomSheet(
                  //   context: context,
                  //   builder: (context) => Padding(
                  //     padding: const EdgeInsets.all(20),
                  //     child: ListView.builder(
                  //       itemCount: apps?.length ?? 0,
                  //       itemBuilder: (context, index) => ListTile(
                  //         title: Text(apps![index].name),
                  //         leading: Image.memory(apps![index].icon),
                  //         onTap: () async {
                  //           Navigator.pop(context);
                  //           await UpiService()
                  //               .initiateTransaction(apps![index])
                  //               .then(
                  //             (response) {
                  //               // print(response.transactionId);
                  //               switch (response.status) {
                  //                 case UpiPaymentStatus.SUCCESS:
                  //                   ScaffoldMessenger.of(context).showSnackBar(
                  //                       SnackBar(content: Text('SUCCESS!')));
                  //                   break;
                  //                 case UpiPaymentStatus.SUBMITTED:
                  //                   ScaffoldMessenger.of(context).showSnackBar(
                  //                       SnackBar(content: Text('SUBMITTED!')));
                  //                   break;
                  //                 case UpiPaymentStatus.FAILURE:
                  //                   ScaffoldMessenger.of(context).showSnackBar(
                  //                       SnackBar(content: Text('FAILURE!')));
                  //                   break;
                  //                 default:
                  //                   ScaffoldMessenger.of(context).showSnackBar(
                  //                       SnackBar(
                  //                           content:
                  //                               Text('Something went wrong!')));
                  //               }
                  //             },
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Subscribe Now - \$9.99/month',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;

  const FeatureCard({super.key, 
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
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
