const crypto = require("crypto");
const Order = require("../models/order.js");
const razorpay = require("../config/razorpay"); // import Razorpay instance
const Product = require("../models/product")

// ✅ Create order (COD or Online)
// ✅ Create Razorpay order only (before payment)
exports.createRazorpayOrder = async (req, res) => {
  try {
    const { basePrice, deliveryCharge, appCharge } = req.body;
    const totalAmount = basePrice + deliveryCharge + appCharge;

    const options = {
      amount: totalAmount * 100, // in paise
      currency: "INR",
      receipt: `order_rcptid_${Date.now()}`,
    };

    const razorpayOrder = await razorpay.orders.create(options);

    res.json({
      success: true,
      razorpayOrder,
      key: process.env.RAZORPAY_KEY_ID,
    });
  } catch (err) {
    console.error("❌ Razorpay Order Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
// ✅ Verify Razorpay payment and create order in DB
exports.verifyPayment = async (req, res) => {
  try {
    const {
      orderId,        // from Razorpay
      paymentId,      // from Razorpay
      signature,      // from Razorpay
      buyerId,
      sellerId,
      productId,
      basePrice,
      deliveryCharge,
      appCharge,
    } = req.body;

    // 🔹 Verify Razorpay signature
    const generatedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(orderId + "|" + paymentId)
      .digest("hex");

    if (generatedSignature !== signature) {
      return res.status(400).json({ success: false, message: "❌ Payment verification failed" });
    }

    // 🔹 Create order in DB (only after successful payment)
    const totalAmount = basePrice + deliveryCharge + appCharge;

    const newOrder = new Order({
      buyerId,
      sellerId,
      productId,
      basePrice,
      deliveryCharge,
      appCharge,
      totalAmount,
      paymentMethod: "Online",
      paymentId,
      paymentStatus: "Paid",
      orderStatus: "Placed",
    });

    await newOrder.save();

     // 🔹 Update Product isActive field to false
    await Product.findByIdAndUpdate(productId, { isActive: false });
    
    res.json({
      success: true,
      message: "✅ Payment verified and order placed successfully",
      order: newOrder,
    });
  } catch (err) {
    console.error("❌ Verify Payment Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Get orders by Buyer
exports.getOrdersByBuyer = async (req, res) => {
  try {
    const { buyerId } = req.params;
    const orders = await Order.find({ buyerId })
      .populate("productId")
      .populate("sellerId", "name email");

    res.json(orders);
  } catch (err) {
    console.error("❌ Get Buyer Orders Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Get orders by Seller
exports.getOrdersBySeller = async (req, res) => {
  try {
    const { sellerId } = req.params;
    const orders = await Order.find({ sellerId })
      .populate("productId")
      .populate("buyerId", "name email");

    res.json(orders);
  } catch (err) {
    console.error("❌ Get Seller Orders Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Create normal COD order
exports.createOrder = async (req, res) => {
  try {
    const {
      buyerId,
      sellerId,
      productId,
      basePrice,
      deliveryCharge,
      appCharge,
      paymentMethod,
      paymentId,
    } = req.body;

    const totalAmount = basePrice + deliveryCharge + appCharge;

    const newOrder = new Order({
      buyerId,
      sellerId,
      productId,
      basePrice,
      deliveryCharge,
      appCharge,
      totalAmount,
      paymentMethod, // "COD"
      paymentStatus: paymentMethod === "COD" ? "Pending" : "Paid",
      paymentId,
      orderStatus: "Placed",
    });

    await newOrder.save();

     // 🔹 Update Product isActive field to false
    await Product.findByIdAndUpdate(productId, { isActive: false });

    res.status(201).json({
      success: true,
      message: "✅ COD order placed successfully",
      order: newOrder,
    });
  } catch (err) {
    console.error("❌ COD Order Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

exports.getOrdersByBuyer = async (req, res) => {
  try {
    const { buyerId } = req.params;

    const orders = await Order.find({ buyerId })
      .populate("productId")
      .populate("sellerId", "name email");

    const protocol = req.protocol;
    const host = req.get("host");

    const ordersWithImages = orders.map((order) => {
      const product = order.productId;
      let images = [];

      if (product && product.images && product.images.length > 0) {
        // Use product.sellerId._id if populated, else fallback to product.sellerId
        const sellerId = product.sellerId?._id || product.sellerId;
        images = product.images.map(
          (img) => `${protocol}://${host}/uploads/productpictures/${sellerId}/${img}`
        );
      }

      return {
        ...order.toObject(),
        productId: {
          ...product.toObject(),
          images, // now will have URLs
        },
      };
    });

    console.log("Orders with images:", JSON.stringify(ordersWithImages, null, 2));

    res.json({ success: true, data: ordersWithImages });
  } catch (err) {
    console.error("❌ Get Buyer Orders Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};


exports.getOrdersBySeller = async (req, res) => {
  try {
    const { sellerId } = req.params;

    const orders = await Order.find({ sellerId })
      .populate("productId")
      .populate("buyerId", "name email");

    const protocol = req.protocol;
    const host = req.get("host");

    const ordersWithImages = orders.map((order) => {
      const product = order.productId;
      let images = [];

      if (product && product.images && product.images.length > 0) {
        images = product.images.map(
          (img) => `${protocol}://${host}/uploads/productpictures/${product.sellerId}/${img}`
        );
      }

      return {
        ...order.toObject(),
        productId: {
          ...product.toObject(),
          images, // replace with full URLs
        },
      };
    });

    res.json({ success: true, data: ordersWithImages });
  } catch (err) {
    console.error("❌ Get Seller Orders Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Get single order by ID with product, buyer, and seller details
exports.getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findById(orderId)
      .populate({
        path: "productId",
        populate: { path: "sellerId", select: "name email" },
      })
      .populate("buyerId", "name email")
      .populate("sellerId", "name email");

    if (!order) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }

    // 🔹 Construct full product image URLs
    const host = req.get("host");
    const protocol = req.protocol;

    const product = order.productId;
    let productImages = [];

    if (product?.images && product?.sellerId?._id) {
      productImages = product.images.map(
        (img) =>
          `${protocol}://${host}/uploads/productpictures/${product.sellerId._id}/${img}`
      );
    }

    const orderData = {
      _id: order._id,
      buyer: order.buyerId,
      seller: order.sellerId,
      product: {
        _id: product?._id,
        title: product?.title,
        price: product?.price,
        category: product?.category,
        subcategory: product?.subcategory,
        description: product?.description,
        images: productImages,
      },
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      orderStatus: order.orderStatus,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt,
    };

    res.json({ success: true, data: orderData });
  } catch (err) {
    console.error("❌ Get Order by ID Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};


exports.getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find()
      .populate("buyerId", "name email")
      .populate("sellerId", "name email")
      .populate("productId");

    const protocol = req.protocol;
    const host = req.get("host");

    const ordersWithImages = orders.map((order) => {
      const product = order.productId;
      let images = [];

      if (product && product.images && product.images.length > 0) {
        // ✅ Use product.sellerId._id if populated, else fallback to product.sellerId
        const sellerId = product.sellerId?._id || product.sellerId;
        images = product.images.map(
          (img) => `${protocol}://${host}/uploads/productpictures/${sellerId}/${img}`
        );
      }

      return {
        ...order.toObject(),
        productId: {
          ...product?.toObject(),
          images, // ✅ now contains absolute URLs
        },
      };
    });

    console.log("📦 All Orders with images:", JSON.stringify(ordersWithImages, null, 2));

    res.json({ success: true, data: ordersWithImages });
  } catch (err) {
    console.error("❌ Get All Orders Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Delete an order
exports.deleteOrder = async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }
    res.status(200).json({ success: true, message: "Order deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};








