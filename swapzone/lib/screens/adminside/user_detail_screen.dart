import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("selectedUserId");
    final token = prefs.getString("token"); // 🔑 take token from prefs

    if (userId == null || token == null) {
      setState(() => isLoading = false);
      return;
    }

    final result = await ApiService.getUserProfile(userId, token);

    if (result['success']) {
      setState(() {
        userData = result['user'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to load profile")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: const Color(0xFF00C9A7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No user data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData!['profileImage'] != null
                      ? NetworkImage(userData!['profileImage'])
                      : null,
                  backgroundColor: Colors.teal.shade100,
                  child: userData!['profileImage'] == null
                      ? Text(
                    userData!['name'] != null
                        ? userData!['name'][0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                        fontSize: 40, color: Colors.white),
                  )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  userData!['name'] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(userData!['email'] ?? "No email"),
                const Divider(height: 30, thickness: 1),

                _buildInfoRow("Phone", userData!['phone'] ?? "-"),
                _buildInfoRow("DOB", userData!['dob'] ?? "-"),
                _buildInfoRow("Gender", userData!['gender'] ?? "-"),
                _buildInfoRow("Address", userData!['address'] ?? "-"),
                _buildInfoRow("Role", userData!['role'] ?? "-"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
