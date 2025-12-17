import 'package:flutter/material.dart';
import 'package:swapzone/services/api_service.dart';
import 'update_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  final String userId;
  const MyProductsScreen({super.key, required this.userId});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> myProducts = [];
  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    _fetchMyProducts();
  }

  Future<void> _fetchMyProducts() async {
    setState(() => isLoading = true);
    final result = await ApiService.getProductsBySeller(widget.userId);
    if (result['success']) {
      final activeProducts = List<Map<String, dynamic>>.from(result['data'])
          .where((prod) => prod['isActive'] == true)
          .toList();

      setState(() {
        myProducts = activeProducts;
        expanded = List<bool>.filled(myProducts.length, false);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to fetch products")),
      );
    }
  }

  Future<void> _deleteProduct(String productId, int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.deleteProduct(widget.userId, productId);
    if (result['success']) {
      setState(() {
        myProducts.removeAt(index);
        expanded.removeAt(index);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Product deleted")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'] ?? "Failed")));
    }
  }

  Widget _buildExtraDetails(Map<String, dynamic> details) {
    if (details.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            "${entry.key}: ${entry.value}",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        elevation: 2,
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : myProducts.isEmpty
          ? const Center(
        child: Text(
          "No products uploaded yet.",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchMyProducts,
        color: const Color(0xFF009688),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: myProducts.length,
          itemBuilder: (context, index) {
            final prod = myProducts[index];
            final image = (prod['images'] != null && prod['images'].isNotEmpty)
                ? prod['images'][0]
                : null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
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
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    expanded[index] = !expanded[index];
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        image: image != null
                            ? DecorationImage(
                            image: NetworkImage(image), fit: BoxFit.cover)
                            : null,
                        color: image == null ? Colors.grey[300] : null,
                      ),
                      child: image == null
                          ? const Center(
                          child: Icon(Icons.image, size: 50, color: Colors.white))
                          : null,
                    ),

                    // Product Info
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['title'] ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${prod['price']}",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70),
                          ),

                          if (expanded[index]) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Category: ${prod['category']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              "Subcategory: ${prod['subcategory']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Description: ${prod['description'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            _buildExtraDetails(Map<String, dynamic>.from(
                                prod['extraDetails'] ?? {})),
                            const SizedBox(height: 6),
                            Text(
                              "Created: ${DateTime.parse(prod['createdAt']).toLocal()}",
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UpdateProductScreen(
                                            product: prod, userId: widget.userId),
                                      ),
                                    );
                                  },
                                  child: const Text("Update"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _deleteProduct(prod['_id'], index),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
