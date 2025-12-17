import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    final res = await ApiService.getAllOrders();
    if (res['success'] == true) {
      setState(() {
        orders = res['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load orders")),
      );
    }
  }

  Future<void> _deleteOrder(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Order", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.deleteOrder(id);
    if (result['success'] == true) {
      setState(() => orders.removeWhere((o) => o['_id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete order")),
      );
    }
  }

  // 🔹 Bottom Sheet with Details (Fixed Overflow + Themed + Back Button)
  void _showOrderDetails(dynamic order) {
    final product = order['productId'] ?? {};
    final buyer = order['buyerId'] ?? {};
    final seller = order['sellerId'] ?? {};

    final imageUrl = (product['images'] != null && (product['images'] as List).isNotEmpty)
        ? product['images'][0]
        : "https://via.placeholder.com/150";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9FAFB),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        product['title'] ?? "Unknown Product",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C9A7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 1),
                const Text(
                  "🛒 Order Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailText("Order ID", order['_id']),
                _detailText("Status", order['orderStatus']),
                _detailText("Payment Method", order['paymentMethod']),
                _detailText("Payment Status", order['paymentStatus']),
                _detailText("Total Amount", "₹${order['totalAmount']}"),
                _detailText("Placed On", order['createdAt']?.toString().substring(0, 10) ?? 'N/A'),

                const Divider(thickness: 1),
                const Text(
                  "👤 Buyer Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailText("Name", buyer['name']),
                _detailText("Email", buyer['email']),

                const Divider(thickness: 1),
                const Text(
                  "🏪 Seller Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailText("Name", seller['name']),
                _detailText("Email", seller['email']),

                const Divider(thickness: 1),
                const Text(
                  "📦 Product Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailText("Category", product['category']),
                _detailText("Subcategory", product['subcategory']),
                _detailText("Price", "₹${product['price']}"),
                _detailText("Description", product['description']),
                const SizedBox(height: 10),
                if (product['images'] != null && (product['images'] as List).isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (product['images'] as List).length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product['images'][i],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 25),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text("Back"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailText(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value?.toString() ?? "N/A", overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Orders"),
        backgroundColor: const Color(0xFF00C9A7),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
          : orders.isEmpty
          ? const Center(
        child: Text(
          "No orders found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final product = order['productId'] ?? {};
          final buyer = order['buyerId'] ?? {};
          final seller = order['sellerId'] ?? {};
          final imageUrl = (product['images'] != null &&
              (product['images'] as List).isNotEmpty)
              ? product['images'][0]
              : "https://via.placeholder.com/150";

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 6,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                product['title'] ?? "Unknown Product",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00C9A7)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Buyer: ${buyer['name'] ?? 'N/A'}"),
                  Text("Seller: ${seller['name'] ?? 'N/A'}"),
                  Text("Payment: ${order['paymentMethod']}"),
                  Text("Status: ${order['orderStatus']}"),
                  Text("Total: ₹${order['totalAmount']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    tooltip: "View Details",
                    onPressed: () => _showOrderDetails(order),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOrder(order['_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
