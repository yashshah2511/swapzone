const express = require('express');
const router = express.Router();
const { uploadProfile } = require('../middlewares/multer');
const { verifyToken } = require("../middlewares/authmiddleware");

// Import all controllers (make sure usercontroller.js exports functions like: exports.createUser = ...)
const userController = require('../controllers/usercontroller');

// User routes
router.get('/users', userController.getAllUsers);
router.post('/signup', userController.createUser);
router.post('/login', userController.loginUser);
router.post('/send-otp', userController.sendOTP);
router.post('/verify-otp', userController.verifyOTP);
router.post('/change-password', userController.changePassword);
router.get('/get-profile/:id', verifyToken, userController.getProfileById);
router.put('/update-profile/:id', verifyToken, uploadProfile, userController.updateProfile);

module.exports = router;
