import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../services/api_service.dart';
import 'checkout_screen.dart'; // 🔹 Make sure CheckoutScreen exists

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  int activeIndex = 0;

  String? token;
  String? userId;
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("userId");
    String? productId = prefs.getString("selectedProductId");

    if (token == null || productId == null) {
      setState(() => isLoading = false);
      return;
    }

    final result = await ApiService.getProductById(token!, productId);
    if (result['success']) {
      setState(() {
        product = result['data'];
        isLoading = false;
      });
      await _checkIfInCart(productId);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkIfInCart(String productId) async {
    if (token == null || userId == null) return;
    final cartResult = await ApiService.getCart(token!, userId!);
    if (cartResult['success']) {
      final cartItems = List<Map<String, dynamic>>.from(cartResult['data']);
      setState(() {
        isInCart = cartItems.any((item) => item['_id'] == productId);
      });
    }
  }

  Future<void> _toggleCart() async {
    if (product == null || token == null || userId == null) return;

    final productId = product!['_id'];
    if (isInCart) {
      final result = await ApiService.removeFromCart(productId, token!, userId!);
      if (result['success']) {
        setState(() => isInCart = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Removed from cart")));
      }
    } else {
      final result = await ApiService.addToCart(productId);
      if (result['success']) {
        setState(() => isInCart = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Added to cart")));
      }
    }
  }

  void _buyNow() {
    if (product == null) return;

    // 🔹 Navigate to CheckoutScreen with full product map
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          product: product!, // ✅ Pass the whole product map
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        title: const Text(
          "Product Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
          ? const Center(child: Text("Product not found"))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Carousel Slider
            if (product!['images'] != null && product!['images'].isNotEmpty)
              Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: product!['images'].length,
                    itemBuilder: (context, index, realIndex) {
                      final img = product!['images'][index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "${ApiService.baseUrl}/uploads/$img",
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 280,
                      viewportFraction: 1,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      onPageChanged: (index, reason) {
                        setState(() => activeIndex = index);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSmoothIndicator(
                    activeIndex: activeIndex,
                    count: product!['images'].length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Color(0xFF009688),
                      dotColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 100),
                ),
              ),

            // 🔹 Product Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFFF7941D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(2, 2))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product!['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${product!['price'] ?? ''}",
                      style: const TextStyle(
                          fontSize: 20, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${product!['category']} > ${product!['subcategory'] ?? ''}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product!['description'] ?? 'No description',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _buyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Buy Now",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isInCart ? Colors.redAccent : const Color(0xFFF7941D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isInCart ? "Remove from Cart" : "Add to Cart",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Extra Details
            if (product!['extraDetails'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Specifications",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        ...product!['extraDetails'].entries.map<Widget>((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(entry.value.toString()),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 🔹 Posted Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Posted on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(product!['createdAt']))}",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
