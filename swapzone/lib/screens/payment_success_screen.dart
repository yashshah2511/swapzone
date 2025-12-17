import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const PaymentSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Successful"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text("Your order has been placed successfully!",
                  style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text("Order ID: ${order['_id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Total Paid: ₹${order['totalAmount']}"),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("Go to Home"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
