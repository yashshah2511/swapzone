import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapzone/services/api_service.dart';

class UpdateProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;

  const UpdateProductScreen({super.key, required this.product, required this.userId});

  @override
  State<UpdateProductScreen> createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _subcategoryController;
  Map<String, TextEditingController> _extraDetailsControllers = {};
  List<String> _oldImages = [];
  List<XFile> _newImages = [];
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Predefined categories
  final List<String> _categories = [
    'Electronics & Gadgets',
    'Fashion & Clothing',
    'Books, Media & Hobbies',
    'Home & Living',
    'Sports & Outdoors',
    'Beauty & Personal Care',
    'Automotive',
    'Toys, Kids & Baby',
  ];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product['title']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _descriptionController = TextEditingController(text: widget.product['description']);
    _subcategoryController = TextEditingController(text: widget.product['subcategory']);

    final extraDetails = Map<String, dynamic>.from(widget.product['extraDetails'] ?? {});
    extraDetails.forEach((key, value) {
      _extraDetailsControllers[key] = TextEditingController(text: value.toString());
    });

    _oldImages = List<String>.from(widget.product['images'] ?? []);

    // Preselect category
    _selectedCategory = widget.product['category'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _subcategoryController.dispose();
    _extraDetailsControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage();
    if (pickedImages != null) {
      setState(() {
        _newImages.addAll(pickedImages);
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // Prepare extraDetails map
    Map<String, String> updatedExtraDetails = {};
    _extraDetailsControllers.forEach((key, controller) {
      updatedExtraDetails[key] = controller.text;
    });

    final result = await ApiService.updateProductWithImages(
      widget.userId,
      widget.product['_id'],
      {
        "title": _titleController.text.trim(),
        "price": double.tryParse(_priceController.text) ?? 0,
        "description": _descriptionController.text.trim(),
        "category": _selectedCategory ?? widget.product['category'],
        "subcategory": _subcategoryController.text.trim(),
        "extraDetails": updatedExtraDetails,
        "oldImages": _oldImages, // keep remaining images
      },
      _newImages, // send new images
    );

    setState(() => isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product updated successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${result['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Product"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter price" : null,
              ),
              const SizedBox(height: 16),

              // ✅ Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? "Please select a category" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subcategoryController,
                decoration: const InputDecoration(
                  labelText: "Subcategory",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter subcategory" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Extra Details dynamically
              ..._extraDetailsControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),

              // Old Images
              if (_oldImages.isNotEmpty) ...[
                const Text("Current Images"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _oldImages.map((img) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(
                          img,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _oldImages.remove(img);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        )
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // New Images
              if (_newImages.isNotEmpty) ...[
                const Text("New Images"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _newImages.map((img) {
                    return Image.file(
                      File(img.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Images"),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Update Product",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
