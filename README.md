# SwapZone

<p>
  <img src="./images/logo.png" alt="SwapZone Logo" width="200"/>
</p>
## 📋 Description

SwapZone is a comprehensive full-stack e-commerce application that enables users to buy and sell products seamlessly. Built with a modern tech stack, it offers a robust platform for online trading with features like user authentication, product management, shopping cart, order processing, payment integration, and an admin dashboard for analytics and management.

The application consists of:
- **Backend**: Node.js/Express API server with MongoDB database
- **Frontend**: Flutter mobile application for iOS and Android
- **Features**: User registration/login, Google OAuth, product listings, cart management, secure payments via Razorpay, order tracking, and admin analytics

## 🎯 Objective

To create an intuitive and secure e-commerce platform that connects buyers and sellers, fostering a community-driven marketplace where users can easily list, discover, and purchase products.

## 🏆 Goal

- Provide a user-friendly interface for buying and selling goods
- Ensure secure transactions and data protection
- Offer comprehensive admin tools for platform management
- Deliver a scalable and maintainable codebase for future enhancements
- Create an engaging experience that encourages user retention and growth

## ✨ Features

- 🔐 **User Authentication**: Email/password and Google OAuth login
- 📱 **Cross-Platform Mobile App**: Flutter-based app for iOS and Android
- 🛒 **Shopping Cart**: Add, remove, and manage cart items
- 💳 **Secure Payments**: Integrated Razorpay for payment processing
- 📦 **Product Management**: List, update, and categorize products
- 📊 **Admin Dashboard**: Analytics, user management, and order oversight
- 📧 **Email Notifications**: OTP verification and order confirmations
- 🖼️ **Image Uploads**: Product images and user profiles
- 📈 **Order Tracking**: Real-time order status updates
- 🎨 **Modern UI**: Beautiful, responsive design with smooth animations

## 🛠️ Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: Passport.js with JWT and Google OAuth 2.0
- **Payments**: Razorpay API
- **File Uploads**: Multer
- **Email**: Nodemailer
- **Security**: bcrypt for password hashing

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider (implied from structure)
- **Networking**: HTTP and Dio packages
- **UI Components**: Custom widgets with Google Fonts
- **Charts**: FL Chart for analytics
- **Payments**: Razorpay Flutter SDK

## 📋 Prerequisites

Before running this project, ensure you have the following installed:

- **Node.js** (v14 or higher)
- **MongoDB** (local or cloud instance)
- **Flutter** (latest stable version)
- **Dart** SDK
- **Android Studio** or **Xcode** for mobile development
- **Git**

## 🚀 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/swapzone.git
   cd swapzone
   ```

2. **Backend Setup**:
   ```bash
   cd backend
   npm install
   ```

3. **Frontend Setup**:
   ```bash
   cd ../swapzone
   flutter pub get
   ```

## ⚙️ Environment Configuration

Create `.env` files in both `backend/` and `swapzone/` directories.

### Backend (.env)
Create `backend/.env` with the following variables:

```env
# Server Configuration
PORT=5000

# Database
MONGO_URI=mongodb://localhost:27017/swapzone
# Or for MongoDB Atlas: MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/swapzone

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key_here

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=http://localhost:5000/auth2/google/callback

# Razorpay Payment Gateway
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Email Configuration (Gmail)
EMAIL_ID=your_email@gmail.com
EMAIL_PASS=your_app_password
```

**Note**: For Gmail, use an "App Password" instead of your regular password. Enable 2FA and generate an app password from your Google Account settings.

### Frontend (.env)
Create `swapzone/.env` with:

```env
# API Base URL
API_BASE_URL=http://localhost:5000

# Razorpay Key (Public)
RAZORPAY_KEY_ID=your_razorpay_key_id
```

## 🏃‍♂️ Running the Project

### Backend
1. Ensure MongoDB is running locally or your cloud instance is accessible.
2. From the `backend/` directory:
   ```bash
   npm start
   ```
   The server will start on `http://localhost:5000`

### Frontend
1. Ensure you have Android/iOS emulator or physical device connected.
2. From the `swapzone/` directory:
   ```bash
   flutter run
   ```
   This will build and run the app on your connected device/emulator.

## 📱 Mobile App Usage

- **Login/Signup**: Create account or login with Google
- **Browse Products**: Explore categories like Electronics, Fashion, Books, etc.
- **Add to Cart**: Select items and manage your shopping cart
- **Checkout**: Secure payment via Razorpay integration
- **Track Orders**: View order history and status
- **Sell Products**: List your items for sale
- **Admin Features**: Manage users, products, and view analytics (admin role required)

## 🔧 Development

### Backend Scripts
- `npm start`: Start the development server with nodemon

### Flutter Commands
- `flutter pub get`: Install dependencies
- `flutter run`: Run the app
- `flutter build apk`: Build Android APK
- `flutter build ios`: Build iOS app

## 🧪 Testing

Currently, the project includes basic widget tests for Flutter. To run tests:

```bash
cd swapzone
flutter test
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [Your GitHub](https://github.com/your-username)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Express.js community
- MongoDB for the database
- Razorpay for payment integration
- All contributors and users

## 📞 Support

If you have any questions or need help, please open an issue on GitHub or contact the maintainers.

---

**Happy coding! 🚀**