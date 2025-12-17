const express = require('express');
const passport = require('passport');
const {
  googleLoginSuccess,
  googleLoginFailure,
  mobileGoogleLogin,
} = require('../controllers/googleauthcontroller');

const router = express.Router();

// Start Google login (web)
router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'], session: false }));

// Google callback (web)
router.get(
  '/google/callback',
  passport.authenticate('google', { failureRedirect: '/auth2/google/failure', session: false }),
  googleLoginSuccess
);

// Failure (web)
router.get('/google/failure', googleLoginFailure);

// Flutter mobile login (idToken exchange)
router.post('/google/mobile', mobileGoogleLogin);

module.exports = router;
