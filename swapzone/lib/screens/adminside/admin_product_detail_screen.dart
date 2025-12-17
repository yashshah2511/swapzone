import 'package:flutter/material.dart';

class AdminProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final images = product['images'] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(product['title'] ?? 'Product Details'),
        backgroundColor: const Color(0xFF00C9A7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Image Carousel
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.isEmpty ? 1 : images.length,
                itemBuilder: (context, index) {
                  final img = images.isEmpty
                      ? "https://via.placeholder.com/250"
                      : images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['title'] ?? "No Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${product['price']}",
              style: const TextStyle(
                  fontSize: 20, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Category: ${product['category']} > ${product['subcategory']}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Divider(height: 30),
            Text(
              product['description'] ?? "No description provided.",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Text(
              "Seller: ${product['seller']?['name'] ?? 'Unknown'}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Text(
              "Email: ${product['seller']?['email'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
