const express = require("express");
const orderController = require("../controllers/orderController.js");
const { verifyToken } = require("../middlewares/authmiddleware.js");

const router = express.Router();

// ✅ Place order & create Razorpay order
router.post("/create", verifyToken, orderController.createOrder);

// // ✅ Verify payment after success
// router.post("/verify", verifyToken, orderController.verifyPayment);

// // ✅ Get all orders for a user (buyer)
// router.get("/buyer/:buyerId", verifyToken, orderController.getOrdersByBuyer);

// // ✅ Get all orders for a seller
// router.get("/seller/:sellerId", verifyToken, orderController.getOrdersBySeller);

router.post("/create-razorpay", orderController.createRazorpayOrder);
router.post("/verify-payment", orderController.verifyPayment);
// router.get("/buyer/:buyerId", orderController.getOrdersByBuyer);
// router.get("/seller/:sellerId", orderController.getOrdersBySeller);
// ✅ Get Orders by Buyer
router.get("/buyer/:buyerId", verifyToken, orderController.getOrdersByBuyer);

// ✅ Get Orders by Seller
router.get("/seller/:sellerId", verifyToken, orderController.getOrdersBySeller);

// ✅ Get order by ID (with product, buyer, and seller details)
router.get("/:orderId", verifyToken, orderController.getOrderById);

// ✅ Fetch all orders
router.get("/", orderController.getAllOrders);

// ✅ Delete an order
router.delete("/:id", orderController.deleteOrder);

module.exports = router;
