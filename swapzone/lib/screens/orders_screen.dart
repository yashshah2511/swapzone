import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapzone/screens/profile_screen.dart';
import 'package:swapzone/screens/CartScreen.dart';
import 'package:swapzone/screens/home_screen.dart';
import 'package:swapzone/screens/order_details_screen.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> buyOrders = [];
  List<Map<String, dynamic>> sellOrders = [];
  bool isLoading = true;
  String? userId;
  String? token;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("userId");

    if (userId != null && token != null) {
      await _fetchOrders();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);

    final buyResult = await ApiService.getBuyerOrders(token!, userId!);
    final sellResult = await ApiService.getSellerOrders(token!, userId!);

    setState(() {
      buyOrders = _extractOrders(buyResult);
      sellOrders = _extractOrders(sellResult);
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _extractOrders(Map<String, dynamic> result) {
    if (result['success'] == true && result['data'] is List) {
      return List<Map<String, dynamic>>.from(result['data']);
    } else if (result['data']?['data'] is List) {
      return List<Map<String, dynamic>>.from(result['data']['data']);
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: "Buy Orders"),
            Tab(icon: Icon(Icons.sell_outlined), text: "Sell Orders"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(buyOrders, "No Buy Orders Found"),
          _buildOrderList(sellOrders, "No Sell Orders Found"),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF7941D),
        child: const Icon(Icons.sell, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 80),
            const SizedBox(height: 10),
            Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        final product = order['productId'] is Map ? order['productId'] : {};
        final buyer = order['buyerId'] is Map ? order['buyerId'] : {};
        final seller = order['sellerId'] is Map ? order['sellerId'] : {};

        final productTitle = product['title'] ?? 'Unknown Product';
        final productPrice = product['price'] ?? 0;
        final orderStatus = order['orderStatus'] ?? 'Unknown';
        final paymentStatus = order['paymentStatus'] ?? 'Unknown';
        final buyerName = buyer['name'] ?? 'N/A';
        final sellerName = seller['name'] ?? 'N/A';

        List<String> imagesList = [];
        if (product['images'] != null) {
          if (product['images'] is List) {
            imagesList = List<String>.from(product['images'].map((e) => e.toString()));
          } else if (product['images'] is String) {
            imagesList = [product['images']];
          }
        }
        String? imageUrl = imagesList.isNotEmpty ? imagesList[0] : null;

        return GestureDetector(
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('selectedOrderId', order['_id']);

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(
                  orderId: order['_id'],
                  token: token ?? '',
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009688), Color(0xFFF7941D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 2)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(imageUrl, width: 55, height: 55, fit: BoxFit.cover)
                    : Container(
                  width: 55,
                  height: 55,
                  color: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.image, color: Colors.white),
                ),
              ),
              title: Text(
                productTitle,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("₹$productPrice",
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text("Order Status: $orderStatus",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Payment: $paymentStatus",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Buyer: $buyerName",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Seller: $sellerName",
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.grey),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            const SizedBox(width: 40),
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
              icon: const Icon(Icons.rule_folder_outlined, color: Color(0xFF009688)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
