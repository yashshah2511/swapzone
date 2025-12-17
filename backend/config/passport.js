const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const User = require('../models/user');

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails && profile.emails[0] && profile.emails[0].value;
        if (!email) return done(new Error('No email returned by Google'), null);

        let user = await User.findOne({ email });

        const payload = {
          name: profile.displayName,
          givenName: profile.name?.givenName,
          familyName: profile.name?.familyName,
          email,
          emailVerified: profile.emails[0]?.verified ?? true, // Google usually verifies email
          googleId: profile.id,
          googlePicture: profile.photos?.[0]?.value,
          profileImage: profile.photos?.[0]?.value,
          authProvider: 'google',
        };

        if (!user) {
          user = await User.create(payload);
        } else {
          // keep user info fresh
          await User.updateOne({ _id: user._id }, { $set: payload });
          user = await User.findById(user._id);
        }

        return done(null, user);
      } catch (err) {
        return done(err, null);
      }
    }
  )
);

// Optional when session=false (kept for completeness)
passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (err) {
    done(err, null);
  }
});

module.exports = passport;
