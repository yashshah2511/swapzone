const User = require("../models/user");
const Product = require("../models/product");
const Order = require("../models/order");

exports.getAnalytics = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalProducts = await Product.countDocuments();
    const totalOrders = await Order.countDocuments();

    // Calculate total revenue (sum of totalAmount of all orders)
    const orders = await Order.find();
    const totalRevenue = orders.reduce((sum, o) => sum + (o.appCharge || 0), 0);

    // Optional: monthly sales data for graph
    const monthlySales = Array(12).fill(0);
    orders.forEach((order) => {
      const month = new Date(order.createdAt).getMonth();
      monthlySales[month] += order.totalAmount || 0;
    });

    res.json({
      success: true,
      data: {
        totalUsers,
        totalProducts,
        totalOrders,
        totalRevenue,
        monthlySales,
      },
    });
  } catch (err) {
    console.error("Analytics Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};
