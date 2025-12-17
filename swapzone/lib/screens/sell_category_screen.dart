import 'package:flutter/material.dart';
import 'category screen/electronics_screen.dart';
import 'category screen/fashion_screen.dart';
import 'category screen/home_living_screen.dart';
import 'category screen/beauty_care_screen.dart';
import 'category screen/sports_screen.dart';
import 'category screen/toys_screen.dart';
import 'category screen/books_media_hobbies_screen.dart';
import 'category screen/automotive_screen.dart';

class SellCategoryScreen extends StatelessWidget {
  const SellCategoryScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {"name": "Electronics & Gadgets", "icon": Icons.devices, "screen": ElectronicsScreen()},
    {"name": "Fashion & Clothing", "icon": Icons.checkroom, "screen": FashionScreen()},
    {"name": "Home & Living", "icon": Icons.chair_alt, "screen": HomeLivingScreen()},
    {"name": "Books ,Media& Hobbies", "icon": Icons.book, "screen": BooksMediaHobbiesScreen()},
    {"name": "Beauty & Personal Care","icon": Icons.spa,"screen": BeautyCareScreen(),},
    {"name": "Sports & Outdoors","icon": Icons.sports_soccer,"screen": SportsScreen(),},
    {"name": "Toys, Kids & Baby", "icon": Icons.toys, "screen": ToysScreen()},
    {"name": "Automotive", "icon": Icons.directions_car, "screen": AutomotiveScreen(),}

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF009688), // Teal from logo
        title: const Text(
          "Choose Category",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 items per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                if (category["screen"] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => category["screen"]),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF009688), // teal
                      Color(0xFFF7941D), // orange
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category["icon"],
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category["name"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
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
