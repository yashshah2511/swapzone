// utils/file.js
const fs = require('fs');
const path = require('path');

exports.deleteFilesSafe = (filePaths = []) => {
  filePaths.forEach(fp => {
    try {
      if (fs.existsSync(fp)) fs.unlinkSync(fp);
    } catch (err) {
      console.error("delete error:", err.message);
    }
  });
};
