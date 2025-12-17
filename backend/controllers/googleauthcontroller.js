const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/user');
const path = require("path");
const fs = require("fs");
const axios = require("axios");


const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const signJwt = (user) =>
  jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });

/**
 * Web-browser OAuth (Passport) -> success JSON
 */
exports.googleLoginSuccess = async (req, res) => {
  if (!req.user) {
    console.log("❌ No user found in request object");
    return res.status(401).json({ success: false, message: 'Authentication failed' });
  }

  console.log("✅ Google Login Success User:", req.user);

  const token = signJwt(req.user);

  res.status(200).json({
    success: true,
    message: 'Google login successful',
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      googleId: req.user.googleId,
      givenName: req.user.givenName,
      familyName: req.user.familyName,
      emailVerified: req.user.emailVerified,
      picture: req.user.googlePicture || req.user.profileImage,
    },
    token,
  });
};

exports.googleLoginFailure = (req, res) => {
  console.log("❌ Google Login Failure");
  res.status(401).json({ success: false, message: 'Google login failed' });
};

/**
 * Mobile/Flutter: POST /auth2/google/mobile
 * Body: { token: <idToken from GoogleSignIn using WEB CLIENT ID> }
 */
exports.mobileGoogleLogin = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ success: false, message: "Missing token" });

    // ✅ Verify Google token
    const ticket = await googleClient.verifyIdToken({
      idToken: token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();

    const { sub: googleId, email, name, picture } = payload;
    if (!email) return res.status(400).json({ success: false, message: "No email in Google token" });

    // ✅ Check if user already exists
    let user = await User.findOne({ email });

    if (!user) {
      // first time login → download Google profile picture & save locally
      const uploadDir = path.join(__dirname, "../uploads/images");
      if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

      const fileName = `${Date.now()}-${googleId}.jpg`; // ✅ filename only
      const filePath = path.join(uploadDir, fileName);

      const response = await axios.get(picture, { responseType: "arraybuffer" });
      fs.writeFileSync(filePath, response.data);

      // Save only filename in DB
      const dbImageName = fileName;

      // create new user
      user = await User.create({
        name,
        email,
        googleId,
        profileImage: dbImageName,
        authProvider: "google",
      });
    } else {
      // ✅ user exists → update basic details but keep existing profileImage
      await User.updateOne(
        { _id: user._id },
        { $set: { name, googleId, authProvider: "google" } }
      );
      user = await User.findById(user._id);
    }

    // ✅ Generate JWT
    const jwtToken = signJwt(user);

    // ✅ Send consistent response
    res.status(200).json({
      success: true,
      message: "Google login successful",
      data: {
        userId: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        profileImage: user.profileImage, // only filename
        token: jwtToken,
      },
    });
  } catch (err) {
    console.error("❌ Google Mobile Login Error:", err);
    res.status(401).json({ success: false, message: "Google login failed", error: err.message });
  }
};
