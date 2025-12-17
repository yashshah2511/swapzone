const express = require('express');
const cors = require('cors');              // ✅ Import cors
require('dotenv').config(); 
const app = express();
const connectDB = require('./config/db');
const user = require('./routes/userroutes');
const googleAuthRoutes = require("./routes/googleauthrotes");
const path = require('path');
const passport = require("passport");
const productRoutes = require("./routes/productroutes")
const cartRoutes = require("./routes/cartroutes")
const orderRoutes = require("./routes/orderRoutes");
const analyticsRoutes = require("./routes/analyticsRoutes")

require("./config/passport"); // load Google strategy

// 🔌 DB Connection
connectDB();

// ✅ Use Middlewares
app.use(cors());                           // ✅ Enable CORS for all origins
app.use(express.json());                   // ✅ Parse incoming JSON


app.use(passport.initialize());


// 🛣️ Routes
app.use('/auth', user);
app.use("/auth2", googleAuthRoutes); // Google auth routes
app.use("/api", productRoutes);     // ✅ Product Routes
app.use("/cart", cartRoutes);
app.use("/orders", orderRoutes);
app.use("/api/admin", analyticsRoutes);




app.use('/uploads', express.static('uploads'));
// Serve static files from uploads
app.use('/uploads/images', express.static(path.join(__dirname, 'uploads/images')));

module.exports = app;
