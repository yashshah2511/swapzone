const express = require("express");
const cartController = require("../controllers/cartController.js");
const { verifyToken } = require("../middlewares/authmiddleware.js");

const router = express.Router();

router.post("/add", verifyToken, cartController.addToCart);
router.get("/show/:userId", cartController.getCart);
router.delete("/remove", cartController.removeFromCart);
router.delete("/clear/:userId", cartController.clearCart);

module.exports = router;
