import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapzone/screens/profile_screen.dart';
import 'package:swapzone/screens/ProductDetailScreen.dart';
import 'package:swapzone/screens/CartScreen.dart';
import 'login_screen.dart';
import 'sell_category_screen.dart';
import 'orders_screen.dart';
import '../services/api_service.dart';
import 'my_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = [
    'All',
    'Electronics & Gadgets',
    'Fashion & Clothing',
    'Books, Media & Hobbies',
    'Home & Living',
    'Sports & Outdoors',
    'Beauty & Personal Care',
    'Automotive',
    'Toys, Kids & Baby'
  ];

  String selectedCategory = 'All';
  String searchQuery = '';
  bool isSearching = false;

  String? token;
  String? userId;

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> cartItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthToken();
  }

  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userId = prefs.getString('userId');

    if (token == null || token!.isEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      await _fetchProducts();
      await _fetchCart();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);

    if (token == null || userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final result = await ApiService.getAllProducts(token!, userId!);

    if (result['success']) {
      setState(() {
        allItems = List<Map<String, dynamic>>.from(result['data']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load products')),
      );
    }
  }

  Future<void> _fetchCart() async {
    if (token == null || userId == null) return;

    final result = await ApiService.getCart(token!, userId!);

    if (result['success']) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(result['data']);
      });
    }
  }

  void _ensureLoggedIn(Function action) {
    if (token == null || token!.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      action();
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    final result = await ApiService.addToCart(item['_id']);
    if (result['success']) {
      await _fetchCart();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['success'] ? "✅ Success" : "❌ Failed"),
        content: Text(result['message'] ??
            (result['success']
                ? "'${item['title']}' has been added to your cart!"
                : "Could not add item to cart.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveFromCart(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove from Cart"),
        content: Text(
            "Are you sure you want to remove '${item['title']}' from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _removeFromCart(item);
    }
  }

  Future<void> _removeFromCart(Map<String, dynamic> item) async {
    if (token == null || userId == null) return;

    final result = await ApiService.removeFromCart(item['_id'], token!, userId!);
    if (result['success']) {
      await _fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from cart")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to remove")),
      );
    }
  }

  Future<void> _showAddToCartConfirmation(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add to Cart"),
        content: Text("Do you want to add '${item['title']}' to your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _addToCart(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = allItems.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item['category'] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item['title']!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF009688),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSearching
              ? TextField(
            key: const ValueKey('searchField'),
            autofocus: true,
            onChanged: (value) => setState(() => searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search items...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          )
              : const Text(
            'SwapZone',
            key: ValueKey('titleText'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          // 🔍 Search
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) searchQuery = '';
                isSearching = !isSearching;
              });
            },
          ),

          // 🏪 My Products Button (new)
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: "My Products",
            onPressed: () => _ensureLoggedIn(() async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              final currentUserId = prefs.getString("userId");
              if (currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyProductsScreen(userId: currentUserId),
                  ),
                );
              }
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildCategorySection(),
              _buildItemGrid(filteredItems),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ensureLoggedIn(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellCategoryScreen()),
          );
        }),
        backgroundColor: const Color(0xFFF7941D),
        child: const Icon(Icons.sell, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCategorySection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => setState(() => selectedCategory = category),
              selectedColor: const Color(0xFF009688),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              elevation: 2,
              pressElevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final imageUrl = (item['images'] != null && item['images'].isNotEmpty)
              ? item['images'][0]
              : null;

          final isInCart =
          cartItems.any((cartItem) => cartItem['_id'] == item['_id']);

          return InkWell(
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("selectedProductId", item['_id']);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
              );
            },
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      image: imageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: imageUrl == null
                        ? const Center(
                        child: Icon(Icons.image,
                            size: 50, color: Colors.white))
                        : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${item['price'] ?? ''}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "${item['category'] ?? ''} > ${item['subcategory'] ?? ''}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          isInCart
                              ? ElevatedButton.icon(
                            onPressed: () =>
                                _ensureLoggedIn(() {
                                  _confirmRemoveFromCart(item);
                                }),
                            icon: const Icon(Icons.remove_shopping_cart,
                                size: 18),
                            label: const Text("Remove from Cart"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              minimumSize:
                              const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                          )
                              : ElevatedButton.icon(
                            onPressed: () =>
                                _ensureLoggedIn(() {
                                  _showAddToCartConfirmation(item);
                                }),
                            icon: const Icon(Icons.add_shopping_cart,
                                size: 18),
                            label: const Text("Add to Cart"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFF7941D),
                              foregroundColor: Colors.white,
                              minimumSize:
                              const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
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
                icon: const Icon(Icons.home, color: Color(0xFF009688)),
                onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.shopping_cart, color: Color(0xFF009688)),
                onPressed: () => _ensureLoggedIn(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                })),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.grey),
              onPressed: () => _ensureLoggedIn(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.rule_folder_outlined,
                  color: Colors.grey),
              onPressed: () => _ensureLoggedIn(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
