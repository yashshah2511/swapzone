class CartProduct {
  final String id;
  final String title;
  final String subcategory;
  final double price;
  final String description;
  final List<String> images;

  CartProduct({
    required this.id,
    required this.title,
    required this.subcategory,
    required this.price,
    required this.description,
    required this.images,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['_id'],
      title: json['title'],
      subcategory: json['subcategory'],
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
