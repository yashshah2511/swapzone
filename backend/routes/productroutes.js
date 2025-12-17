const express = require("express");
const router = express.Router();
const productController = require("../controllers/productcontroller");
const {verifyToken} = require("../middlewares/authmiddleware");
const { uploadProduct } = require("../middlewares/multer"); // only product image uploads

// 🟢 Create product (protected, with images)
router.post("/products/create/:sellerId",verifyToken, uploadProduct, productController.createProduct);

// 🟢 Get all products
router.get("/products/read", verifyToken,productController.getAllProducts);

// 🟢 Get products by category
router.get("/products/category/:category", productController.getProductsByCategory);

// 🟢 Get single product by ID
router.get("/products/:id", productController.getProductById);

    // 🟢 Update product (protected, with images)
    router.put("/products/:sellerId/:id",verifyToken, uploadProduct, productController.updateProduct);

// 🟢 Delete product (protected)
router.delete("/products/:sellerId/:id",verifyToken, productController.deleteProduct);


router.get("/products", productController.getAllProductsadmin);
router.delete("/product/:id", productController.deleteProductadmin);

router.get("/seller-products", productController.getProductsBySeller);
module.exports = router;
