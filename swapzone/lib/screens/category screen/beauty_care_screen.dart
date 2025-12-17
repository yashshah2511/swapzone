// lib/screens/category screen/beauty_care_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class BeautyCareScreen extends StatefulWidget {
  const BeautyCareScreen({super.key});

  @override
  State<BeautyCareScreen> createState() => _BeautyCareScreenState();
}

class _BeautyCareScreenState extends State<BeautyCareScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _conditionController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  // Images (max 10)
  final List<File> _images = [];

  // Subcategory selection
  String? selectedSubcategory;

  // Dynamic fields
  final Map<String, TextEditingController> _extraControllers = {};

  // Brand colors
  final Color teal = const Color(0xFFF7941D);
  final Color pink = const Color(0xFF009688);

  final Map<String, List<String>> subcategoryFields = {
    "Skincare": [
      "Product Type",
      "Skin Type",
      "Ingredients / Key Actives",
      "Size / Volume",
      "Expiry Date"
    ],
    "Cosmetics": [
      "Product Type",
      "Shade / Color",
      "Finish",
      "Size / Volume",
      "Expiry Date"
    ],
    "Grooming": [
      "Product Type",
      "Power Type",
      "Features"
    ],
    "Wellness": [
      "Product Type",
      "Size / Quantity",
      "Ingredients"
    ],
  };

  void _updateDynamicFields(String subcategory) {
    _extraControllers.forEach((_, ctrl) => ctrl.dispose());
    _extraControllers.clear();
    for (var field in subcategoryFields[subcategory] ?? []) {
      _extraControllers[field] = TextEditingController();
    }
    setState(() {});
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage(imageQuality: 75);
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var xfile in pickedFiles) {
        if (_images.length >= 10) break;
        _images.add(File(xfile.path));
      }
      setState(() {});
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      setState(() {});
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSubcategory == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Missing Subcategory"),
          content: Text("Please select a subcategory before submitting."),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Invalid Price"),
          content: Text("Please enter a valid number for the price."),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    final sellerId = prefs.getString("userId") ?? "";

    Map<String, dynamic> extraDetails = {};
    _extraControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) extraDetails[key] = controller.text;
    });

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await ApiService.createProduct(
      token: token,
      sellerId: sellerId,
      title: _titleController.text,
      category: "Beauty & Personal Care",
      subcategory: selectedSubcategory!,
      price: price,
      description: _descController.text,
      images: List<File>.from(_images),
      extraDetails: extraDetails,
    );

    if (mounted) Navigator.of(context).pop(); // dismiss loading

    if (response['success']) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success ✅"),
          content: const Text("Your product was created successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error ❌"),
          content: Text(response['message'] ?? "Something went wrong"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool required = false, IconData icon = Icons.edit}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: pink),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildImagePickerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < _images.length) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_images[index], fit: BoxFit.cover),
              ),
              Positioned(
                right: -6,
                top: -6,
                child: IconButton(
                  onPressed: () => _removeImage(index),
                  icon: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ),
            ],
          );
        } else {
          return GestureDetector(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey.shade600, size: 20),
                    const SizedBox(height: 4),
                    Text("Add", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _conditionController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _extraControllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: pink,
        title: const Text("Beauty & Personal Care", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Subcategory
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: selectedSubcategory,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category, color: pink),
                    labelText: "Select Subcategory",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: subcategoryFields.keys
                      .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => selectedSubcategory = val);
                    _updateDynamicFields(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Common Fields
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField("Title", _titleController, required: true, icon: Icons.label),
                      const SizedBox(height: 12),
                      _buildTextField("Brand", _brandController, icon: Icons.business),
                      const SizedBox(height: 12),
                      _buildTextField("Condition", _conditionController, icon: Icons.check_circle_outline),
                      const SizedBox(height: 12),
                      _buildTextField("Price", _priceController, isNumber: true, required: true, icon: Icons.price_change),
                      const SizedBox(height: 12),
                      _buildTextField("Description", _descController, icon: Icons.note),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images
            Text("Upload Photos (max 10)", style: titleStyle),
            const SizedBox(height: 8),
            _buildImagePickerGrid(),
            const SizedBox(height: 18),

            // Dynamic Fields
            if (selectedSubcategory != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Details for $selectedSubcategory", style: titleStyle),
                      const SizedBox(height: 10),
                      ..._extraControllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTextField(entry.key, entry.value, icon: Icons.info_outline),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitProduct,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Submit Product"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
