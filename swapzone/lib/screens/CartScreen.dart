import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'productdetailscreen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    final userId = prefs.getString("userId") ?? "";

    final response = await ApiService.getCart(token, userId);
    if (response['success']) {
      final data = response['data'] as List;
      setState(() {
        _products = data.map((p) => CartProduct.fromJson(p)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to load cart")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _removeFromCart(String productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    final userId = prefs.getString("userId") ?? "";

    final response = await ApiService.removeFromCart(productId, token, userId);
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from cart")),
      );
      _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to remove")),
      );
    }
  }

  Future<void> _confirmRemove(String productId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove from Cart"),
        content: const Text(
          "Are you sure you want to remove this product from your cart?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // cancel
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // confirm
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      _removeFromCart(productId);
    }
  }

  Future<void> _goToProductDetails(String productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedProductId", productId);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
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
          "My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return InkWell(
              onTap: () => _goToProductDetails(product.id),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFFF7941D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                        image: product.images.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(product.images[0]),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: product.images.isEmpty
                          ? const Center(
                        child: Icon(Icons.image,
                            size: 50, color: Colors.white),
                      )
                          : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${product.subcategory} • ₹${product.price}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _confirmRemove(product.id),
                                icon: const Icon(Icons.delete,
                                    size: 18),
                                label: const Text("Remove"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(100, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home icon -> navigate to HomeScreen
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF009688)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              // Cart icon -> stay on current screen
              IconButton(
                icon: const Icon(Icons.shopping_cart,
                    color: Color(0xFF009688)),
                onPressed: () {},
              ),
              const SizedBox(width: 40),
              // Profile icon -> navigate to ProfileScreen
              IconButton(
                icon: const Icon(Icons.person, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon:
                const Icon(Icons.rule_folder_outlined, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
