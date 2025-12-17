const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: String,
    email: { type: String, unique: true },
    password: String,
    phoneno:String,

    profileImage: String, // Store image file name or full URL
    googlePicture: String,    
    
    dob: Date,
    gender: String,
    street: String,
    city: String,
    state: String,
    pincode: String,
    role: {
        type: String,
        enum: ['admin', 'user'],
        default: 'user' // default role
    },
     // for google
    googleId: { type: String, index: true },
    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },
    
    otp: String,
    otpExpiresAt: Date,
    isOtpVerified: {
    type: Boolean,
    default: false
    }

}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
