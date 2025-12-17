import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'payment_success_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = 'COD';
  Razorpay? _razorpay;
  String? token;
  String? userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    await _loadSession();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
      userId = prefs.getString("userId");
    });
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(msg: "Payment Successful 🎉");

    final result = await ApiService.verifyPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      product: widget.product,
      token: token!,
      userId: userId!,
    );

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(order: result['order']),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Verification failed: ${result['message']}");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment failed: ${response.message}",
      backgroundColor: Colors.redAccent,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }

  Future<void> _payOnline() async {
    if (token == null || userId == null) {
      Fluttertoast.showToast(msg: "Session expired. Please login again.");
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.createRazorpayOrder(
      product: widget.product,
      token: token!,
      userId: userId!,
    );

    setState(() => _isLoading = false);

    if (result['success'] != true) {
      Fluttertoast.showToast(msg: "Order creation failed: ${result['message']}");
      return;
    }

    var options = {
      'key': result['key'],
      'amount': result['razorpayOrder']['amount'],
      'name': 'SwapZone',
      'order_id': result['razorpayOrder']['id'],
      'description': 'Purchase of ${widget.product['title']}',
      'theme.color': '#009688',
      'prefill': {'contact': '', 'email': ''},
    };

    _razorpay!.open(options);
  }

  Future<void> _placeOrder() async {
    if (token == null || userId == null) {
      Fluttertoast.showToast(msg: "Session expired. Please login again.");
      return;
    }

    if (paymentMethod == "COD") {
      setState(() => _isLoading = true);

      final result = await ApiService.createOrder(
        product: widget.product,
        paymentMethod: "COD",
        token: token!,
        userId: userId!,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Order Placed Successfully ✅");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(order: result['order']),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Order failed: ${result['message']}");
      }
    } else {
      _payOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double price = (product['price'] ?? 0).toDouble();
    final double deliveryCharge = price * 0.2;
    final double appCharge = price * 0.1;
    final double totalAmount = price + deliveryCharge + appCharge;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF009688)))
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Details Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF009688), Color(0xFFF7941D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2))
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text("₹${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(product['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Price Breakdown
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Price Breakdown",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Divider(),
                        _buildPriceRow("Product Price", price),
                        _buildPriceRow(
                            "Delivery Charge (20%)", deliveryCharge),
                        _buildPriceRow("App Charge (10%)", appCharge),
                        const Divider(),
                        _buildPriceRow("Total Amount", totalAmount,
                            isTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Select Payment Method",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _paymentCard("Cash on Delivery", "COD",
                    paymentMethod == "COD", Icons.money),
                _paymentCard("Online Payment (Razorpay)", "Online",
                    paymentMethod == "Online", Icons.payment),
              ],
            ),
          ),
          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text("₹${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Place Order",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Custom Payment Card
  Widget _paymentCard(
      String title, String value, bool isSelected, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7F1) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF009688) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color:
                      isSelected ? const Color(0xFF009688) : Colors.black87,
                      fontSize: 16)),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF009688), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text("₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
