const multer = require('multer');
const path = require('path');
const fs = require("fs");



// ✅ Profile image storage
const profileStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/images'); // Profile images folder
  },
  filename: function (req, file, cb) {
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueName + path.extname(file.originalname));
  }
});

// ✅ Product image storage per seller
const productStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const sellerId = req.params.sellerId; // ✅ get from URL param
    if (!sellerId) return cb(new Error("Seller ID not provided"), null);

    const dir = `uploads/productpictures/${sellerId}`;
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueName + path.extname(file.originalname));
  }
});

// Middlewares
const uploadProfile = multer({ storage: profileStorage }).single('profileImage');
const uploadProduct = multer({ storage: productStorage }).array('productImages', 5); // up to 5 images

module.exports = { uploadProfile, uploadProduct };
