import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:swapzone/models/user_model.dart';
import 'package:swapzone/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final String token;

  const EditProfileScreen({super.key, required this.user, required this.token});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController streetController;
  late TextEditingController pincodeController;

  String? selectedGender;
  String? selectedState;
  String? selectedCity;

  File? _imageFile;

  // State-City mapping
  final Map<String, List<String>> stateCityMap = {
    "Maharashtra": ["Mumbai","Pune","Nagpur","Nashik","Thane","Aurangabad","Kolhapur","Solapur","Amravati","Jalgaon","Satara"],
    "Gujarat": ["Ahmedabad","Surat","Vadodara","Rajkot","Bhavnagar","Jamnagar","Junagadh","Gandhinagar","Morbi","Anand","Mehsana"],
    "Karnataka": ["Bengaluru","Mysuru","Mangalore","Hubballi","Belagavi","Shivamogga","Ballari","Davanagere","Tumakuru","Udupi","Bidar"],
    "Tamil Nadu": ["Chennai","Coimbatore","Madurai","Tiruchirappalli","Salem","Erode","Vellore","Tirunelveli","Thoothukudi","Karur","Dindigul"],
    "Rajasthan": ["Jaipur","Jodhpur","Udaipur","Kota","Bikaner","Ajmer","Alwar","Bhilwara","Sikar","Pali","Chittorgarh"],
    "Telangana": ["Hyderabad","Warangal","Nizamabad","Karimnagar","Khammam","Mahbubnagar","Nalgonda","Adilabad","Ramagundam","Suryapet"],
    "West Bengal": ["Kolkata","Howrah","Asansol","Durgapur","Siliguri","Kharagpur","Malda","Haldia","Bardhaman","Jalpaiguri"],
    "Uttar Pradesh": ["Lucknow","Kanpur","Allahabad","Varanasi","Agra","Noida","Ghaziabad","Meerut","Bareilly","Moradabad","Aligarh","Gorakhpur","Jhansi","Mathura"],
    "Haryana": ["Gurgaon","Faridabad","Panipat","Karnal","Ambala","Hisar","Rohtak","Sonipat","Yamunanagar","Kurukshetra"],
    "Andhra Pradesh": ["Visakhapatnam","Vijayawada","Guntur","Tirupati","Nellore","Kurnool","Rajahmundry","Kakinada","Anantapur","Ongole","Kadapa"],
  };

  List<String> availableCities = [];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user.name ?? '');
    phoneController = TextEditingController(text: widget.user.phoneno ?? '');
    streetController = TextEditingController(text: widget.user.street ?? '');
    pincodeController = TextEditingController(text: widget.user.pincode ?? '');

    // DOB Handling
    if (widget.user.dob != null && widget.user.dob!.isNotEmpty) {
      try {
        DateTime parsed = DateTime.parse(widget.user.dob!);
        dobController = TextEditingController(
            text: DateFormat('dd-MM-yyyy').format(parsed));
      } catch (_) {
        dobController = TextEditingController(text: widget.user.dob ?? '');
      }
    } else {
      dobController = TextEditingController();
    }

    // Gender
    selectedGender = widget.user.gender ?? '';

    // Preselect State & City only if valid
    if (widget.user.state != null && stateCityMap.containsKey(widget.user.state)) {
      selectedState = widget.user.state;
      availableCities = stateCityMap[selectedState]!;
      if (availableCities.contains(widget.user.city)) {
        selectedCity = widget.user.city;
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    DateTime? initialDate;
    try {
      initialDate = DateFormat('dd-MM-yyyy').parse(dobController.text);
    } catch (_) {
      initialDate = DateTime(2000);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Name must contain only letters')),
      );
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Phone number must be exactly 10 digits')),
      );
      return;
    }

    String dobForApi = '';
    if (dobController.text.isNotEmpty) {
      try {
        DateTime parsed = DateFormat('dd-MM-yyyy').parse(dobController.text);
        dobForApi = parsed.toIso8601String().split('T')[0];
      } catch (_) {}
    }

    try {
      final response = await ApiService.updateUserProfile(
        userId: widget.user.userId!,
        name: nameController.text,
        phoneno: phoneController.text,
        dob: dobForApi,
        gender: selectedGender,
        street: streetController.text,
        city: selectedCity ?? '',
        state: selectedState ?? '',
        pincode: pincodeController.text,
        imageFile: _imageFile,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${response['message']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Update failed: $error')),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF009688)) : null,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.black87),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: (selectedGender != null && selectedGender!.isNotEmpty) ? selectedGender : null,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person, color: Color(0xFF009688)),
          labelText: 'Gender',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: (value) => setState(() => selectedGender = value!),
      ),
    );
  }

  Widget _buildStateDropdown() {
    String? dropdownValue =
    stateCityMap.containsKey(selectedState) ? selectedState : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.map, color: Color(0xFF009688)),
          labelText: 'State',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: stateCityMap.keys
            .map((state) => DropdownMenuItem(
          value: state,
          child: Text(state),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedState = value;
            availableCities = stateCityMap[selectedState] ?? [];
            selectedCity = null; // reset city
          });
        },
      ),
    );
  }

  Widget _buildCityDropdown() {
    String? cityDropdownValue =
    (selectedCity != null && availableCities.contains(selectedCity)) ? selectedCity : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: cityDropdownValue,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.location_city, color: Color(0xFF009688)),
          labelText: 'City',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: availableCities
            .map((city) => DropdownMenuItem(
          value: city,
          child: Text(city),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedCity = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileImageProvider = _imageFile != null
        ? FileImage(_imageFile!)
        : (widget.user.profileImage != null
        ? NetworkImage(widget.user.profileImage!)
        : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF009688),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profileImageProvider as ImageProvider<Object>?,
                backgroundColor: const Color(0xFFE0F2F1),
                child: profileImageProvider == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Color(0xFF009688))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField("Name", nameController, icon: Icons.person),
            _buildTextField("Phone", phoneController, icon: Icons.phone),
            _buildTextField("Date of Birth", dobController,
                readOnly: true, onTap: () => _selectDOB(context), icon: Icons.calendar_today),
            _buildGenderDropdown(),
            _buildTextField("Street", streetController, icon: Icons.home),
            _buildStateDropdown(),
            _buildCityDropdown(),
            _buildTextField("Pincode", pincodeController, icon: Icons.pin),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "Update Profile",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
