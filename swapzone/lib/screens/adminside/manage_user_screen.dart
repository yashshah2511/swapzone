import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import 'user_detail_screen.dart';

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({super.key});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  String selectedRole = "user";
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);

    final result = await ApiService.getAllUsers(selectedRole);

    if (result['success']) {
      setState(() {
        users = result['data'];
        filteredUsers = users;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to fetch users')),
      );
    }
  }

  void _filterUsers(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Future<void> _openUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedUserId", userId);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'User List - Role: ${selectedRole.toUpperCase()}',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Role'],
                data: filteredUsers.map((user) => [
                  user['name'] ?? '',
                  user['email'] ?? '',
                  user['role'] ?? ''
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: const Color(0xFF00C9A7),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Download PDF",
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 🔹 Role selector
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Users"),
                    selected: selectedRole == "user",
                    onSelected: (_) {
                      setState(() => selectedRole = "user");
                      _fetchUsers();
                      searchController.clear();
                    },
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: selectedRole == "user" ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("Admins"),
                    selected: selectedRole == "admin",
                    onSelected: (_) {
                      setState(() => selectedRole = "admin");
                      _fetchUsers();
                      searchController.clear();
                    },
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: selectedRole == "admin" ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: "Search by name or email...",
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 🔹 User/Admin list
            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
                  : filteredUsers.isEmpty
                  ? const Center(
                  child: Text(
                    "No records found",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ))
                  : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    elevation: 6,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          user['name'] != null
                              ? user['name'][0].toUpperCase()
                              : "U",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user['name'] ?? "Unknown"),
                      subtitle: Text(user['email'] ?? "No email"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: user['role'] == 'admin'
                              ? Colors.redAccent
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'].toString().toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () => _openUserProfile(user['_id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
