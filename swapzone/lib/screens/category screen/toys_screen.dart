// lib/screens/category screen/toys_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ToysScreen extends StatefulWidget {
  const ToysScreen({super.key});

  @override
  State<ToysScreen> createState() => _ToysScreenState();
}

class _ToysScreenState extends State<ToysScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _conditionController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _ageGroupController = TextEditingController();

  // Images (max 10)
  final List<File> _images = [];

  // Subcategory selection
  String? selectedSubcategory;

  // Dynamic fields
  final Map<String, TextEditingController> _extraControllers = {};

  final Map<String, List<String>> subcategoryFields = {
    "Toys": [
      "Type (Action Figure, Puzzle, Doll, etc.)",
      "Material",
      "Safety Certification",
    ],
    "Baby Gear": [
      "Type (Stroller, Car Seat, High Chair, etc.)",
      "Age/Weight Range",
      "Safety Features",
      "Dimensions / Foldability",
    ],
    "Kids’ Clothing": [
      "Size",
      "Material",
      "Color / Pattern",
      "Type (Shirt, Dress, Pants, Pajamas, etc.)",
    ],
  };

  // Brand colors
  final Color teal = const Color(0xFF009688);
  final Color orange = const Color(0xFFF7941D);

  void _updateDynamicFields(String subcategory) {
    // Dispose existing dynamic controllers first
    _extraControllers.forEach((_, ctrl) => ctrl.dispose());
    _extraControllers.clear();

    for (var field in subcategoryFields[subcategory] ?? []) {
      _extraControllers[field] = TextEditingController();
    }
    setState(() {});
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    try {
      final List<XFile>? pickedFiles = await picker.pickMultiImage(imageQuality: 75);
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var xfile in pickedFiles) {
          if (_images.length >= 10) break;
          _images.add(File(xfile.path));
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
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
        builder: (_) => AlertDialog(
          title: const Text("Missing Subcategory"),
          content: const Text("Please select a subcategory before submitting."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid Price"),
          content: const Text("Please enter a valid number for the price."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
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

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await ApiService.createProduct(
      token: token,
      sellerId: sellerId,
      title: _titleController.text,
      category: "Toys, Kids & Baby",
      subcategory: selectedSubcategory!,
      price: price,
      description: _descController.text,
      images: List<File>.from(_images),
      extraDetails: {
        "Age Group": _ageGroupController.text,
        ...extraDetails,
      },
    );

    if (mounted) Navigator.of(context).pop();

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
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool isNumber = false,
        bool required = false,
        IconData icon = Icons.edit,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: teal),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    _ageGroupController.dispose();

    _extraControllers.forEach((_, ctrl) => ctrl.dispose());
    _extraControllers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: teal,
        elevation: 0,
        title: const Text("Toys, Kids & Baby", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subcategory dropdown
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: selectedSubcategory,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category, color: teal),
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

            // Common fields
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField("Title / Name", _titleController, required: true, icon: Icons.label),
                      const SizedBox(height: 12),
                      _buildTextField("Brand", _brandController, icon: Icons.business),
                      const SizedBox(height: 12),
                      _buildTextField("Age Group (0–2Y, 3–5Y, 6–12Y, 12+)", _ageGroupController, icon: Icons.child_care),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Condition", _conditionController, icon: Icons.check_circle_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField("Price", _priceController, isNumber: true, required: true, icon: Icons.price_change)),
                        ],
                      ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick from gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                    if (photo != null) {
                      if (_images.length < 10) {
                        setState(() => _images.add(File(photo.path)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 10 images allowed")));
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Dynamic fields
            if (selectedSubcategory != null) ...[
              Card(
                elevation: 2,
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
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildTextField(entry.key, entry.value, icon: Icons.info_outline),
                        );
                      }).toList()
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitProduct,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Submit Product", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
