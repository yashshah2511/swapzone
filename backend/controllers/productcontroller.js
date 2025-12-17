const Product = require("../models/product");
const path = require("path");
const fs = require("fs");
const mongoose = require("mongoose");


// ✅ Create product
exports.createProduct = async (req, res) => {
  try {
    const { title, category, subcategory,price, description, extraDetails } = req.body;
    const sellerId = req.params.sellerId;


    // Store file names (only filename, not full path)
    const images = req.files ? req.files.map(file => file.filename) : [];

    const product = new Product({
      title,
      category,
      subcategory,
      price,
      description,
      images,
      sellerId,
      extraDetails: extraDetails ? JSON.parse(extraDetails) : {} // ⚡ parse dynamic fields
    });

    await product.save();
    res.json({ message: "✅ Product created", product });
  } catch (err) {
    console.error("❌ Create Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Read all products


// ✅ Read all products (excluding current user's)
exports.getAllProducts = async (req, res) => {
  try {
    const currentUserId = req.query.userId;
    console.log(currentUserId)
    const userObjectId = new mongoose.Types.ObjectId(currentUserId);

    // 🔥 Exclude products where sellerId equals current user
    const products = await Product.find({ sellerId: { $ne: userObjectId },isActive: true, })
      .populate("sellerId", "name email");

    const host = req.get("host");
    const protocol = req.protocol;

    const updatedProducts = products.map((prod) => {
      const images = prod.images.map(
        (img) =>
          `${protocol}://${host}/uploads/productpictures/${prod.sellerId._id}/${img}`
      );

      return {
        _id: prod._id,
        title: prod.title,
        category: prod.category,
        subcategory: prod.subcategory,
        price: prod.price,
        description: prod.description,
        images,
        seller: prod.sellerId,
        extraDetails: prod.extraDetails,
         isActive: prod.isActive,
        createdAt: prod.createdAt,
      };
    });

    res.json(updatedProducts);
  } catch (err) {
    console.error("❌ Error fetching products:", err);
    res.status(500).json({ message: "Server error" });
  }
};


// ✅ Read products by category
exports.getProductsByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const products = await Product.find({ category });
    res.json(products);
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Read product by ID
exports.getProductById = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findById(id).populate("sellerId", "name email");

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const protocol = req.protocol;
    const host = req.get("host");

    const images = product.images.map((img) => {
      // ✅ If already contains "http" or "https", return as it is
      if (img.startsWith("http://") || img.startsWith("https://")) {
        return img;
      }
      // ✅ Otherwise, prepend server URL
      return `/productpictures/${product.sellerId._id}/${img}`;
    });

    const productWithUrls = {
      _id: product._id,
      title: product.title,
      category: product.category,
      subcategory: product.subcategory,
      price: product.price,
      description: product.description,
      images,
      seller: product.sellerId,
      extraDetails: product.extraDetails,
      createdAt: product.createdAt,
    };

    res.json(productWithUrls);
  } catch (err) {
    console.error("❌ Error fetching product:", err);
    res.status(500).json({ message: "Server error" });
  }
};



// ✅ Update product
exports.updateProduct = async (req, res) => {
  try {
     const { sellerId, id } = req.params;
     console.log(sellerId)
     console.log(id)

    let product = await Product.findById(id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    if (product.sellerId.toString() !== sellerId) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    // Update basic fields
    product.title = req.body.title || product.title;
    product.category = req.body.category || product.category;
    product.subcategory = req.body.subcategory || product.subcategory;
    product.price = req.body.price || product.price;
    product.description = req.body.description || product.description;

    // Update dynamic category fields
    if (req.body.extraDetails) {
  try {
    product.extraDetails = JSON.parse(req.body.extraDetails);
  } catch (err) {
    console.error("⚠️ Invalid extraDetails JSON:", req.body.extraDetails);
  }
}

    if (req.files && req.files.length > 0) {
  console.log("🟡 Old images:", product.images);
  console.log("🟡 New uploaded files:", req.files);

  // Delete old images safely
  product.images.forEach(img => {
    try {
      const imgName = path.basename(img); // ✅ extract filename only
      const imgPath = path.join(__dirname, `../uploads/productpictures/${sellerId}/`, imgName);
      if (fs.existsSync(imgPath)) {
        fs.unlinkSync(imgPath);
        console.log("🗑️ Deleted:", imgPath);
      }
    } catch (err) {
      console.error("⚠️ Error deleting image:", err.message);
    }
  });

  // Save new images
  product.images = req.files.map(file => file.filename);
}

    await product.save();
    res.json({ message: "✅ Product updated", product });
  } catch (err) {
    console.error("❌ Update Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Delete product
exports.deleteProduct = async (req, res) => {
  try {
    const { sellerId, id } = req.params;

    const product = await Product.findById(id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    if (product.sellerId.toString() !== sellerId) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    // Delete only this product's images
    if (product.images && product.images.length > 0) {
      product.images.forEach((imgUrl) => {
        // Get relative path
        const filePath = path.join(__dirname, '../uploads', imgUrl.replace(`${req.protocol}://${req.get('host')}/`, ''));
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      });
    }

    // Delete the product from DB
    await product.deleteOne();
    res.json({ message: "✅ Product deleted and related images removed" });

  } catch (err) {
    console.error("❌ Delete Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Fetch all products for admin
exports.getAllProductsadmin = async (req, res) => {
  try {
    const products = await Product.find().populate("sellerId", "name email");

    // Convert image paths into full URLs
    const protocol = req.protocol;
    const host = req.get("host");

    const formatted = products.map((p) => ({
      _id: p._id,
      title: p.title,
      description: p.description,
      price: p.price,
      category: p.category,
      images: p.images
        ? p.images.map(
            (img) =>
              `${protocol}://${host}/uploads/productpictures/${p.sellerId?._id}/${img}`
          )
        : [],
      seller: p.sellerId,
      isActive: p.isActive,
      createdAt: p.createdAt,
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    console.error("❌ Admin getAllProducts Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Delete a product
exports.deleteProductadmin = async (req, res) => {
  try {
    const { id } = req.params;
    const product = await Product.findByIdAndDelete(id);

    if (!product)
      return res
        .status(404)
        .json({ success: false, message: "Product not found" });

    res.json({ success: true, message: "Product deleted successfully" });
  } catch (err) {
    console.error("❌ Admin deleteProduct Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};


// ✅ Get products uploaded by a specific seller (using userId)
exports.getProductsBySeller = async (req, res) => {
  try {
    const { userId } = req.query; // or req.params if you prefer
    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }

    const sellerObjectId = new mongoose.Types.ObjectId(userId);

    // ✅ Find products where sellerId matches the given userId
    const products = await Product.find({ sellerId: sellerObjectId })
      .populate("sellerId", "name email");

    if (products.length === 0) {
      return res.status(404).json({ message: "No products found for this user" });
    }

    const host = req.get("host");
    const protocol = req.protocol;

    const updatedProducts = products.map((prod) => {
      const images = prod.images.map(
        (img) =>
          `${protocol}://${host}/uploads/productpictures/${prod.sellerId._id}/${img}`
      );

      return {
        _id: prod._id,
        title: prod.title,
        category: prod.category,
        subcategory: prod.subcategory,
        price: prod.price,
        description: prod.description,
        images,
        seller: prod.sellerId,
        extraDetails: prod.extraDetails,
        isActive: prod.isActive,
        createdAt: prod.createdAt,
      };
    });

    res.json(updatedProducts);
  } catch (err) {
    console.error("❌ Error fetching seller products:", err);
    res.status(500).json({ message: "Server error" });
  }
};
