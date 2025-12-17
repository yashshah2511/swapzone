const express = require("express");
const router = express.Router();
const analytics = require("../controllers/adminController");

router.get("/analytics", analytics.getAnalytics);

module.exports = router;
