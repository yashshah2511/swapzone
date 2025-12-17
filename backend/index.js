require('dotenv').config(); // Load .env variables
const app = require('./app')

// Use variables from .env
const PORT = process.env.PORT || 5000;

// Simple route
app.get('/', (req, res) => {
    res.send('Server is running!');
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});