const User = require('../models/user');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/sendemail');
const fs = require('fs');
const path = require('path');

exports.createUser = async (req, res) => {
  try {
    const { name, email, password,phoneno } = req.body;

    // 🔍 Validate required fields
    if (!name || !email || !password|| !phoneno) {
      return res.status(400).json({ message: "Name, email, and password are required." });
    }

    // 🔄 Check if the email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: "Email already exists. Please use a different email." });
    }

    // 🔄 Check if the phoneno already exists
    const existingphoneno = await User.findOne({ phoneno });
    if (existingphoneno) {
      return res.status(409).json({ message: "phone no already exists. Please use a different phone no" });
    }

    // 🔐 Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // ✅ Create and save new user
    const user = new User({ name, email, password: hashedPassword,phoneno });
    const savedUser = await user.save();

    res.status(201).json({
      success: true,
      message: "User created successfully",
      user: {
        id: savedUser._id,
        name: savedUser.name,
        email: savedUser.email,
        phoneno: savedUser.phoneno,
        role: savedUser.role
      }
    });
  } catch (err) {
    console.error("Error while creating user:", err);
    res.status(500).json({
      message: "Something went wrong while creating the user",
      error: err.message
    });
  }
};


// ✅ Get all users (with optional role filter)
exports.getAllUsers = async (req, res) => {
  try {
    const { role } = req.query; // 👈 role comes from frontend (query param)

    let filter = {};
    if (role) {
      filter.role = role; // if role=user/admin → apply filter
    }

    const users = await User.find(filter);

    if (users.length === 0) {
      return res.status(404).json({ message: 'No users found.' });
    }

    res.status(200).json({
      message: 'Users retrieved successfully',
      count: users.length,
      data: users
    });
  } catch (error) {
    console.error('❌ Error while fetching users:', error);
    res.status(500).json({
      message: 'Something went wrong while fetching users',
      error: error.message
    });
  }
};

// Login Route
exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate fields
    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    
    // Check if the user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: "email is invalid" });
    }

     // Ensure user registered with local auth
    if (user.authProvider !== 'local') {
      return res.status(400).json({
        message: `Please login using ${user.authProvider}`
      });
    }

    // Compare the password
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ message: "password is incorrect" });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role }, // Payload with user info
      process.env.JWT_SECRET,  // Secret key from .env file
      { expiresIn: '1h' } // Token expires in 1 hour
    );
    console.log(token)

    // Send the response with the token and user data
    res.status(201).json({
      success: true,
      message: "Login successful",
      data: {
        userId: user._id,
        name: user.name,
        email: user.email,
        phoneno: user.phoneno,
        role: user.role,
        token: token
      }
    });

  } catch (err) {
    console.error("Error while logging in:", err);
    res.status(500).json({
      success: false,
      message: "Something went wrong while logging in",
      error: err.message
    });
  }
};



exports.sendOTP = async (req, res) => {
  const { email } = req.body;
  console.log("🔐 OTP Request Received for:", email);

  if (!email) {
    console.log("❌ Email not provided");
    return res.status(400).json({ message: "Email is required" });
  }

  const user = await User.findOne({ email });
  if (!user) {
    console.log("❌ User not found for email:", email);
    return res.status(404).json({ message: "User not found" });
  }

  // 🚫 Prevent OTP reset if account was created via Google
  if (user.authProvider === "google") {
    console.log("⚠️ Google account detected. Password reset not allowed for:", email);
    return res.status(400).json({
      message: "This account was created with Google. Please log in using Google Sign-In."
    });
  }

  // ⏱️ Check if there's already a valid OTP
  if (user.otp && user.otpExpiresAt > Date.now()) {
    const remaining = Math.ceil((user.otpExpiresAt - Date.now()) / 1000); // in seconds
    console.log(`⏳ OTP already sent to ${email}. Remaining time: ${remaining} seconds`);
    return res.status(429).json({
      message: `OTP already sent. Please wait ${remaining} seconds before requesting a new one.`
    });
  }

  // 🔢 Generate OTP and expiry (not saved yet)
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

  // 📧 Try sending the email first
  try {
    await sendEmail(email, 'Your OTP Code', `Your OTP is: ${otp}`);
    console.log(`📧 OTP email sent to ${email}`);

    // 📝 Save OTP only if email is sent
    user.otp = otp;
    user.otpExpiresAt = expiry;
    user.isOtpVerified = false; // reset verification
    await user.save();

    res.json({ message: "OTP sent to your email" });

  } catch (error) {
    console.error("❌ Failed to send OTP email:", error);
    res.status(500).json({ message: "Failed to send OTP email" });
  }
};





exports.verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (!user.otp || user.otp !== otp)
      return res.status(400).json({ message: "Invalid OTP" });

    if (user.otpExpiresAt < Date.now())
      return res.status(400).json({ message: "OTP expired" });

    // ✅ Mark OTP as verified
    user.isOtpVerified = true;
    await user.save();

    res.json({ message: "OTP verified successfully" });
  } catch (error) {
    console.error("Verify OTP Error:", error);
    res.status(500).json({ message: "Server error" });
  }
};





exports.changePassword = async (req, res) => {
  const { email, newPassword } = req.body;

  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: "User not found" });

  // ✅ Check if OTP was verified earlier
  if (!user.isOtpVerified)
    return res.status(400).json({ message: "OTP not verified or session expired" });

  // 🔒 Hash the new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);
  user.password = hashedPassword;

  // 🔁 Clear OTP-related fields
  user.otp = undefined;
  user.otpExpiresAt = undefined;
  user.isOtpVerified = false;

  await user.save();

  res.json({ message: "Password changed successfully" });
};


exports.getProfileById = async (req, res) => {
  try {
    const userId = req.params.id;
    console.log("🔎 Fetching profile for user ID:", userId);

    const user = await User.findById(userId);

    if (!user) {
      console.log("❌ User not found");
      return res.status(404).json({ message: "User not found" });
    }

    // Convert Mongoose document to plain JS object
    const userObj = user.toObject();

    // Build full image URL if profileImage exists
    if (userObj.profileImage) {
      userObj.profileImage = `${req.protocol}://${req.get('host')}/uploads/images/${userObj.profileImage}`;
    }

    console.log("✅ User data with image path:", userObj);
    res.status(200).json({ message: "User data fetched", user: userObj });

  } catch (error) {
    console.error("❌ Error fetching user:", error);
    res.status(500).json({ message: "Server error" });
  }
};




exports.updateProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    console.log("🔍 Updating profile for user ID:", userId);

    const updateData = {};

    // Basic fields
    if (req.body.name) updateData.name = req.body.name;
    if (req.body.phoneno) updateData.phoneno = req.body.phoneno;
    if (req.body.dob) updateData.dob = req.body.dob;
    if (req.body.gender) updateData.gender = req.body.gender;

    // Address fields
    if (req.body.street) updateData.street = req.body.street;
    if (req.body.city) updateData.city = req.body.city;
    if (req.body.state) updateData.state = req.body.state;
    if (req.body.pincode) updateData.pincode = req.body.pincode;

    // 👉 Check if user exists before updating
    const user = await User.findById(userId);
    if (!user) {
      console.log("⚠️ User not found");
      return res.status(404).json({ message: "User not found" });
    }

    // ✅ Handle image upload
    if (req.file) {
      console.log("🖼️ New image uploaded:", req.file.filename);

      // ✅ If old image exists, delete it
      if (user.profileImage) {
        const oldImagePath = path.join(__dirname, '../uploads/images/', user.profileImage);
        fs.unlink(oldImagePath, (err) => {
          if (err) {
            console.warn("⚠️ Failed to delete old image:", err.message);
          } else {
            console.log("🗑️ Old image deleted:", user.profileImage);
          }
        });
      }

      // ✅ Save new image filename
      updateData.profileImage = req.file.filename;
    } else {
      console.log("❌ No image uploaded");
    }

    console.log("📦 Final update data to be saved:", updateData);

    // Update user in DB
    const updatedUser = await User.findByIdAndUpdate(userId, updateData, { new: true });

    console.log("✅ Profile successfully updated:", updatedUser);
    res.json({ message: "Profile updated", user: updatedUser });

  } catch (error) {
    console.error("❌ Update Error:", error);
    res.status(500).json({ message: "Server error" });
  }
};