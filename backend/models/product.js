const mongoose = require("mongoose");

const productSchema = new mongoose.Schema({
  title: { type: String, required: true },
  category: { type: String, required: true },
  subcategory: { type: String, required: true },
  price: { type: Number, required: true },
  description: { type: String },
  images: [{ type: String }],
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

  // 🔑 Dynamic category-based details
  extraDetails: {
    type: mongoose.Schema.Types.Mixed, // Flexible JSON object
    default: {},
  },

  isActive: { type: Boolean, default: true },

  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Product", productSchema);
