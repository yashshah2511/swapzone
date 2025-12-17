const jwt = require("jsonwebtoken");

exports.verifyToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    // ✅ Check if authorization header exists and starts with Bearer
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, message: "Unauthorized: No token provided" });
    }

    // ✅ Extract token
    const token = authHeader.split(" ")[1];

    // ✅ Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // ✅ Attach user payload to request
    req.user = decoded;
    req.userId = decoded.id;
    // console.log(userId)

    next(); // Continue to controller
  } catch (error) {
    return res.status(401).json({ success: false, message: "Invalid or expired token" });
  }
};
