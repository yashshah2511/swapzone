const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema({
  buyerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
  
  basePrice: { type: Number, required: true },
  deliveryCharge: { type: Number, required: true },
  appCharge: { type: Number, required: true },
  totalAmount: { type: Number, required: true },

  paymentMethod: { type: String, enum: ["COD", "Online"], required: true },
  paymentStatus: { type: String, enum: ["Pending", "Paid"], default: "Pending" },

  orderStatus: { type: String, enum: ["Placed", "Shipped", "Delivered", "Cancelled"], default: "Placed" },

  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Order", orderSchema);
