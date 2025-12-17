import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:4000';
  // static const String baseUrl = 'http://192.168.1.73:4000';



  static Future<Map<String, dynamic>> signupUser(
      String name, String email, String phoneno, String password) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phoneno': phoneno,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      final body = jsonDecode(response.body);
      return {'success': false, 'message': body['message'] ?? 'Signup failed'};
    }
  }


  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        final userData = json['data'];
        final user = UserModel.fromJson(userData);

        // Save in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', user.token);
        await prefs.setString('role', user.role);
        await prefs.setString('name', user.name);
        await prefs.setString('email', user.email);
        await prefs.setString('userId', user.userId);

        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': json['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print("Login error: $e");
      return {'success': false, 'message': 'Something went wrong. Try again later.'};
    }
  }

  // ✅ Correct Google login endpoint and payload key
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/auth2/google/mobile');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": idToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {"success": false, "message": "Google login failed"};
      }
    }
  }


  static Future<UserModel?> getProfileById() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('userId');
      final String? token = prefs.getString('token');

      print("📦 Retrieved from SharedPreferences:");
      print("  👉 userId: $userId");
      print("  👉 token: $token");

      if (userId == null || token == null) {
        print(" Missing userId or token in SharedPreferences");
        return null;
      }

      final url = Uri.parse('$baseUrl/auth/get-profile/$userId');
      print(" Making GET request to: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(" Response Status Code: ${response.statusCode}");
      print(" Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ User data parsed successfully");
        return UserModel.fromJson(data['user']);
      } else {
        print(" Failed to fetch profile. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print(" Exception in getProfileById: $e");
      return null;
    }
  }



  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ OTP sent
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully.',
        };
      } else if (response.statusCode == 429) {
        // ⏳ OTP already sent, still valid
        return {
          'success': false,
          'message': data['message'] ?? 'OTP already sent. Please wait.',
        };
      } else if (response.statusCode == 404) {
        // ❌ User not found
        return {
          'success': false,
          'message': data['message'] ?? 'User not found with this email.',
        };
      } else if (response.statusCode == 400) {
        // 🚫 Google account (or other bad request)
        return {
          'success': false,
          'message': data['message'] ??
              'This account uses Google Sign-In. Please log in with Google.',
        };
      } else {
        // ❗ Other error
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP.',
        };
      }
    } catch (e) {
      // ⚠️ Exception occurred
      return {
        'success': false,
        'message': 'Something went wrong: $e',
      };
    }
  }



  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      final otp = prefs.getString('otp');

      if (email == null || otp == null) {
        return {
          'success': false,
          'message': 'Missing email or OTP in local storage.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Clear OTP from local storage after successful password reset
        prefs.remove('otp');
        return {'success': true, 'message': data['message'] ?? 'Password changed successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Function to update user profile using MultipartRequest
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? phoneno,
    String? dob,
    String? gender,
    String? street,
    String? city,
    String? state,
    String? pincode,
    File? imageFile,
  }) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId'); // Ensure this is stored during login
    final url = Uri.parse('$baseUrl/auth/update-profile/$userId');

    print(" Preparing to send update request...");
    print(" URL: $url");
    print(" User ID: $userId");
    print(" Token: $token");

    try {
      final request = http.MultipartRequest('PUT', url) // POST instead of PUT
        ..headers['Authorization'] = 'Bearer $token';

      // Add fields (log only if present)
      if (name != null) {
        request.fields['name'] = name;
        print(" Name: $name");
      }
      if (phoneno != null) {
        request.fields['phoneno'] = phoneno;
        print(" Phone No: $phoneno");
      }
      if (dob != null) {
        request.fields['dob'] = dob;
        print(" DOB: $dob");
      }
      if (gender != null) {
        request.fields['gender'] = gender;
        print(" Gender: $gender");
      }
      if (street != null) {
        request.fields['street'] = street;
        print(" Street: $street");
      }
      if (city != null) {
        request.fields['city'] = city;
        print(" City: $city");
      }
      if (state != null) {
        request.fields['state'] = state;
        print(" State: $state");
      }
      if (pincode != null) {
        request.fields['pincode'] = pincode;
        print(" Pincode: $pincode");
      }

      // Attach image if provided
      if (imageFile != null) {
        print(" Attaching image: ${imageFile.path}");
        final imageStream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'profileImage',
          imageStream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      } else {
        print(" No image file attached.");
      }

      // Send request
      print(" Sending request to server...");
      final streamedResponse = await request.send();

      print(" Status Code: ${streamedResponse.statusCode}");

      final response = await http.Response.fromStream(streamedResponse);

      print(" Raw Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print(" Profile update successful!");
        return {'success': true, 'user': data['user']};
      } else {
        print(" Server responded with an error: ${data['message']}");
        return {'success': false, 'message': data['message'] ?? 'Failed to update'};
      }
    } catch (e) {
      print(" Exception occurred: $e");
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }


  static Future<Map<String, dynamic>> createProduct({
    required String token,
    required String sellerId,
    required String title,
    required String category,
    required String subcategory,
    required double price,
    required String description,
    required List<File> images,
    required Map<String, dynamic> extraDetails,
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/api/products/create/$sellerId");
      var request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = title;
      request.fields["category"] = category;
      request.fields["subcategory"]=subcategory;
      request.fields["price"] = price.toString();
      request.fields["description"] = description;
      request.fields["extraDetails"] = jsonEncode(extraDetails);

      for (var img in images) {
        request.files.add(await http.MultipartFile.fromPath("productImages", img.path));
      }

      var response = await request.send();
      var resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resBody)};
      } else {
        return {"success": false, "message": resBody};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🟢 Get all products
  static Future<Map<String, dynamic>> getAllProducts(String token,String userId) async {
    try {
      var url = Uri.parse("$baseUrl/api/products/read?userId=$userId");
      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": "Failed to fetch products: ${response.body}"
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  // ✅ Add to cart
  static Future<Map<String, dynamic>> addToCart(String productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('userId');

      if (token == null || userId == null) {
        return {"success": false, "message": "User not logged in"};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/cart/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "userId": userId,
          "productId": productId,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "message": jsonDecode(response.body)["message"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  static Future<Map<String, dynamic>> getCart(String token, String userId) async {
    try {
      var url = Uri.parse("$baseUrl/cart/show/$userId");
      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Now 'data' already contains the cart products
        List<dynamic> products = data['data'] ?? [];
        return {"success": true, "data": products};
      } else {
        return {"success": false, "message": "Failed to fetch cart"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

// 🔴 Remove from Cart
  static Future<Map<String, dynamic>> removeFromCart(
      String productId, String token, String userId) async {
    try {
      var url = Uri.parse("$baseUrl/cart/remove"); // ✅ corrected route

      var response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "productId": productId,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Removed from cart"};
      } else {
        return {
          "success": false,
          "message": "Failed to remove: ${response.body}"
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
  // 🟢 Get product by ID
  static Future<Map<String, dynamic>> getProductById(String token, String id) async {
    try {
      var url = Uri.parse("$baseUrl/api/products/$id");
      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to fetch product"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllUsers(String role) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/users?role=$role"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data['data']};
      } else {
        return {"success": false, "message": "Failed to fetch users"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  static Future<Map<String, dynamic>> getUserProfile(String id, String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/get-profile/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "user": data['user']};
      } else {
        final data = jsonDecode(response.body);
        return {"success": false, "message": data['message']};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }


  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> product,
    required String paymentMethod, // COD / Online
    required String token,
    required String userId,
    String? paymentId, // for online payment
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/orders/create"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "buyerId": userId,
          "sellerId": product['seller'] is Map
              ? product['seller']['_id']
              : product['seller'],

          "productId": product['_id'],
          "basePrice": product['price'],
          "deliveryCharge": product['deliveryCharge'] ?? (product['price'] * 0.2),
          "appCharge": product['appCharge'] ?? (product['price'] * 0.1),
          "paymentMethod": paymentMethod,
          "paymentId": paymentId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "order": data['order'],
          "razorpayOrder": data['razorpayOrder'],
          "key": data['key']
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? 'Failed to create order'
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔹 Create Razorpay Order
  static Future<Map<String, dynamic>> createRazorpayOrder({
    required Map<String, dynamic> product,
    required String token,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/orders/create-razorpay"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "basePrice": product['price'],
          "deliveryCharge": product['price'] * 0.2,
          "appCharge": product['price'] * 0.1,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

// 🔹 Verify Razorpay Payment
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required Map<String, dynamic> product,
    required String token,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/orders/verify-payment"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "orderId": orderId,
          "paymentId": paymentId,
          "signature": signature,
          "buyerId": userId,
          "sellerId": product['seller'] is Map ? product['seller']['_id'] : product['seller'],
          "productId": product['_id'],
          "basePrice": product['price'],
          "deliveryCharge": product['price'] * 0.2,
          "appCharge": product['price'] * 0.1,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBuyerOrders(String token, String buyerId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders/buyer/$buyerId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      return {'success': true, 'data': data['data'] ?? []};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch buyer orders'};
    }
  }

  static Future<Map<String, dynamic>> getSellerOrders(String token, String sellerId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders/seller/$sellerId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      return {'success': true, 'data': data['data'] ?? []};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch seller orders'};
    }
  }


  static Future<Map<String, dynamic>> getOrderDetails(String token, String orderId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      return {'success': true, 'data': data['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch order details'};
    }
  }


  // Fetch all products for admin
  static Future<Map<String, dynamic>> getAdminProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/products"));
      if (response.statusCode == 200) {
        return json.decode(response.body); // returns Map {success: true, data: [...]}
      } else {
        throw Exception('Failed to fetch products');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

// Delete product by ID
  static Future<bool> deleteAdminProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/api/product/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ✅ Fetch all orders for admin
  static Future<Map<String, dynamic>> getAllOrders() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/orders"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch orders'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

// ✅ Delete an order
  static Future<Map<String, dynamic>> deleteOrder(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/orders/$id"));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/analytics'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'success': false, 'message': 'Failed to fetch analytics'};
    }
  }

  static Future<Map<String, dynamic>> getProductsBySeller(String userId) async {
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/api/seller-products?userId=$userId"),

      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to load seller products"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  static Future<Map<String, dynamic>> updateProduct(
      String sellerId, String productId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/products/$sellerId/$productId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return {"success": true, "data": json.decode(response.body)};
      } else {
        return {"success": false, "message": "Failed to update product"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ✅ Delete product by sellerId and productId
  static Future<Map<String, dynamic>> deleteProduct(String sellerId, String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.delete(
        Uri.parse("$baseUrl/api/products/$sellerId/$productId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ send token
        },
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Product deleted successfully"};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static final Dio _dio = Dio(BaseOptions(baseUrl: "http://192.168.1.73:4000"));

  static Future<Map<String, dynamic>> updateProductWithImages(
      String sellerId,
      String productId,
      Map<String, dynamic> data,
      List<XFile> newImages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // ✅ stored after login

      FormData formData = FormData.fromMap({
        "title": data["title"],
        "price": data["price"],
        "description": data["description"],
        "category": data["category"],
        "subcategory": data["subcategory"],
        "extraDetails": data["extraDetails"] != null
            ? data["extraDetails"].toString()
            : "{}",
        "oldImages": data["oldImages"], // remaining image URLs
        "productImages": [
          for (var img in newImages)
            await MultipartFile.fromFile(img.path, filename: img.name)
        ]
      });

      Response response = await _dio.put(
        "/api/products/$sellerId/$productId", // ✅ correct route
        data: formData,
        options: Options(headers: {
          "Authorization": "Bearer $token", // ✅ send token
          "Content-Type": "multipart/form-data",
        }),
      );

      return {"success": true, "data": response.data};
    } catch (e) {
      print("❌ Update error: $e");
      return {"success": false, "message": e.toString()};
    }
  }

}
