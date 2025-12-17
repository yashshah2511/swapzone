import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final String token;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.token,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final result = await ApiService.getOrderDetails(widget.token, widget.orderId);
    setState(() {
      orderDetails = result['success'] ? result['data'] : null;
      isLoading = false;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF009688),
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : orderDetails == null
          ? const Center(child: Text("Failed to load order details"))
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildOrderContent(),
        ),
      ),
    );
  }

  Widget _buildOrderContent() {
    final product = orderDetails!['product'] ?? {};
    final seller = orderDetails!['seller'] ?? {};
    final buyer = orderDetails!['buyer'] ?? {};
    final images = List<String>.from(product['images'] ?? []);
    final orderDate = orderDetails!['createdAt'] ?? DateTime.now().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Product Image
        if (images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              images.first,
              height: 230,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 18),

        // 🔹 Product Info
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF009688), Color(0xFFF7941D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(2, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['title'] ?? 'Unknown Product',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "₹${product['price'] ?? 'N/A'}",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['description'] ?? 'No description available',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 🔹 Order Status
        _buildSectionTitle("Order Summary"),
        _buildInfoCard([
          _infoRow("Order ID", orderDetails!['_id'] ?? "N/A"),
          _infoRow("Order Date", DateFormat('dd MMM yyyy').format(DateTime.parse(orderDate))),
          _infoRow("Order Status", orderDetails!['orderStatus'] ?? "Pending"),
          _infoRow("Payment Method", orderDetails!['paymentMethod'] ?? "N/A"),
          _infoRow("Payment Status", orderDetails!['paymentStatus'] ?? "Unpaid"),
          _infoRow("Total Amount", "₹${orderDetails!['totalAmount'] ?? 0}"),
        ]),

        const SizedBox(height: 20),

        // 🔹 Buyer & Seller
        _buildSectionTitle("People Involved"),
        _buildInfoCard([
          _infoRow("Buyer", buyer['name'] ?? "N/A"),
          _infoRow("Buyer Email", buyer['email'] ?? "N/A"),
          const Divider(),
          _infoRow("Seller", seller['name'] ?? "N/A"),
          _infoRow("Seller Email", seller['email'] ?? "N/A"),
        ]),

        const SizedBox(height: 25),

        // 🔹 Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _gradientButton(Icons.message, "Contact", Colors.green, Colors.teal),
            _gradientButton(Icons.local_shipping, "Track", Colors.orange, Colors.deepOrange),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF009688),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(1, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                    color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton(IconData icon, String text, Color c1, Color c2) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: c1.withOpacity(0.4), blurRadius: 6, offset: const Offset(2, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
