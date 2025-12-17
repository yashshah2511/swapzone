const Cart = require("../models/cart");
const Product = require("../models/product");


exports.addToCart = async (req, res) => {
  try {
    const { userId, productId } = req.body;

    let cart = await Cart.findOne({ userId });

    if (!cart) {
      // Create new cart for user
      cart = new Cart({ userId, productId: [productId] });
      await cart.save();
      return res.json({ success: true, message: "✅ Product added to cart", cart });
    } else {
      // Check if product already exists
      if (cart.productId.includes(productId)) {
        return res.json({ success: false, message: "⚠️ Product already in cart" });
      }

      // Add product if not exists
      cart.productId.push(productId);
      await cart.save();
      return res.json({ success: true, message: "✅ Product added to cart", cart });
    }
  } catch (err) {
    console.error("❌ AddToCart Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Get cart items by user
exports.getCart = async (req, res) => {
  try {
    const { userId } = req.params;

    const cart = await Cart.findOne({ userId }).populate("productId");

    if (!cart || !cart.productId.length) {
      return res.json({ success: true, data: [] });
    }

    const host = req.get("host");
    const protocol = req.protocol;

    const cartProducts = cart.productId.map((prod) => {
      const images = (prod.images || []).map(
        (img) =>
          `${protocol}://${host}/uploads/productpictures/${prod.sellerId}/${img}`
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
        createdAt: prod.createdAt,
      };
    });

    res.json({ success: true, data: cartProducts });
  } catch (err) {
    console.error("❌ GetCart Error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ✅ Remove single product from cart
exports.removeFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.body;

    const cart = await Cart.findOne({ userId });
    if (!cart) return res.status(404).json({ message: "Cart not found" });

    cart.productId = cart.productId.filter(
      (id) => id.toString() !== productId
    );

    await cart.save();

    res.json({ message: "✅ Product removed from cart", cart });
  } catch (err) {
    console.error("❌ RemoveFromCart Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ✅ Clear entire cart for a user
exports.clearCart = async (req, res) => {
  try {
    const { userId } = req.params;

    await Cart.findOneAndDelete({ userId });

    res.json({ message: "✅ Cart cleared" });
  } catch (err) {
    console.error("❌ ClearCart Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};
