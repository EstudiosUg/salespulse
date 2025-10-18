# Google Play Store Deployment Guide - SalesPulse

This guide will walk you through deploying the SalesPulse Android app to the Google Play Store.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [App Icon Configuration](#app-icon-configuration)
3. [Creating a Signing Key](#creating-a-signing-key)
4. [Building the Release APK/AAB](#building-the-release-apkaab)
5. [Play Store Listing](#play-store-listing)
6. [Uploading to Play Store](#uploading-to-play-store)
7. [Version Management](#version-management)

---

## Prerequisites

Before you begin, ensure you have:
- Flutter SDK installed and configured
- Android Studio or Android SDK command-line tools
- A Google Play Console developer account ($25 one-time fee)
- Your app's custom icons (already configured in `assets/AppIcons/`)

---

## App Icon Configuration

✅ **Already Configured!**

Your app is already configured to use custom icons:
- Android icons: Generated from `assets/AppIcons/playstore.png`
- Adaptive icons with white background
- Multiple resolutions for different devices

The icons have been generated using `flutter_launcher_icons` package and are ready for deployment.

**App Details:**
- **App Name:** SalesPulse
- **Package Name:** com.estudios.ug.salespulse
- **Version:** 1.0.0 (Build 1)

---

## Creating a Signing Key

To publish your app, you need to create a signing key. This is a one-time process.

### Step 1: Generate Upload Keystore

Run the following command in your terminal:

#### On Mac/Linux:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### On Windows:
```powershell
keytool -genkey -v -keystore %userprofile%\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Answer the Prompts

You'll be asked for:
- Keystore password (remember this!)
- Key password (can be the same as keystore password)
- Your name, organization, city, state, country code

### Step 3: Move the Keystore

Move the generated `upload-keystore.jks` file to your project's android directory:

```bash
mv ~/upload-keystore.jks ./android/
```

### Step 4: Create key.properties File

Copy the template and fill in your details:

```bash
cd android
cp key.properties.template key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

⚠️ **IMPORTANT:** Never commit `key.properties` or `upload-keystore.jks` to version control!

---

## Building the Release APK/AAB

### Building App Bundle (Recommended for Play Store)

The App Bundle (.aab) is the recommended format for Google Play Store. It allows Google to optimize the app for different device configurations.

```bash
cd salespulse
flutter build appbundle --release
```

The bundle will be created at:
`build/app/outputs/bundle/release/app-release.aab`

### Building APK (Alternative)

If you need a standalone APK:

```bash
flutter build apk --release
```

The APK will be created at:
`build/app/outputs/flutter-apk/app-release.apk`

### Testing the Release Build

Before uploading, test the release build:

```bash
# Install the APK on a device
flutter install --release

# Or use adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Play Store Listing

### Required Assets

Before uploading, prepare these assets:

1. **App Icon** (Already done! ✓)
   - 512x512 PNG (use `assets/AppIcons/playstore.png`)

2. **Feature Graphic**
   - 1024x500 PNG
   - Promotional banner for Play Store

3. **Screenshots** (at least 2, up to 8)
   - Phone: 1080x1920 or similar
   - 7-inch tablet: 1536x2048 or similar
   - 10-inch tablet: 2048x1536 or similar

4. **Short Description**
   - Maximum 80 characters
   - Example: "Track sales and expenses with ease. Manage your business on the go."

5. **Full Description**
   - Maximum 4000 characters
   - Explain features, benefits, and how to use the app

6. **Privacy Policy**
   - Required if your app collects user data
   - Must be hosted on a publicly accessible URL

---

## Uploading to Play Store

### Step 1: Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in app details:
   - **App name:** SalesPulse
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free (or Paid)
4. Accept the declarations and click **Create app**

### Step 2: Set Up Store Listing

1. Navigate to **Store presence** → **Main store listing**
2. Fill in all required fields:
   - App name
   - Short description
   - Full description
   - App icon (512x512)
   - Feature graphic (1024x500)
   - Screenshots (at least 2)
3. Set the **App category** and **Contact details**
4. Click **Save**

### Step 3: Content Rating

1. Navigate to **Policy** → **App content** → **Content rating**
2. Fill out the questionnaire
3. Submit and apply ratings

### Step 4: Target Audience

1. Navigate to **Policy** → **App content** → **Target audience**
2. Select age groups
3. Click **Save**

### Step 5: Privacy Policy

1. Navigate to **Policy** → **App content** → **Privacy policy**
2. Enter your privacy policy URL
3. Click **Save**

### Step 6: Upload Release

1. Navigate to **Release** → **Production**
2. Click **Create new release**
3. Upload your `app-release.aab` file
4. Enter **Release name**: Version 1.0.0
5. Enter **Release notes** describing what's new
6. Click **Review release**
7. Review and click **Start rollout to Production**

### Step 7: Review and Publish

- Google will review your app (typically takes 1-3 days)
- You'll receive an email when the review is complete
- If approved, your app will be live on the Play Store!

---

## Version Management

### Updating Version Numbers

When releasing updates, increment version numbers in `build.gradle.kts`:

```kotlin
defaultConfig {
    applicationId = "com.salespulse.app"
    minSdk = 21
    targetSdk = 34
    versionCode = 2        // Increment this for each release
    versionName = "1.0.1"  // Update this with new version
}
```

**Version Code Rules:**
- Must be an integer
- Must be higher than the previous version
- Cannot be reused

**Version Name:**
- User-facing version (e.g., "1.0.1", "1.1.0", "2.0.0")
- Follow semantic versioning: MAJOR.MINOR.PATCH

### Release Workflow

1. Make changes to your app
2. Update version numbers in `build.gradle.kts`
3. Update version in `pubspec.yaml` (optional but recommended)
4. Build new release: `flutter build appbundle --release`
5. Test the release build
6. Upload to Play Console → Production → Create new release
7. Add release notes describing changes
8. Submit for review

---

## Troubleshooting

### Common Issues

**"App not installed" error:**
- Uninstall the previous version first
- Make sure you have enough storage space
- Check that the signing key matches

**Build fails:**
- Run `flutter clean` and rebuild
- Check that `key.properties` exists and is correct
- Verify that `upload-keystore.jks` is in the android directory

**Play Store rejects upload:**
- Make sure version code is incremented
- Check that target SDK is up to date (currently 34)
- Verify app bundle is signed with the correct key

**ProGuard issues:**
- Check `proguard-rules.pro` for any needed keep rules
- Test the release build thoroughly before uploading

---

## Security Best Practices

1. ✅ Never commit `key.properties` to version control
2. ✅ Never commit `upload-keystore.jks` to version control
3. ✅ Store backup of keystore in a secure location
4. ✅ Use different keys for debug and release builds
5. ✅ Enable two-factor authentication on Play Console account
6. ✅ Keep your keystore password secure (use a password manager)

---

## Additional Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Bundle Documentation](https://developer.android.com/guide/app-bundle)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)

---

## Quick Reference Commands

```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Build app bundle for Play Store
flutter build appbundle --release

# Build APK for testing
flutter build apk --release

# Install release build on device
flutter install --release

# Clean build cache
flutter clean

# Get app size analysis
flutter build appbundle --analyze-size
```

---

## Contact & Support

If you encounter any issues during deployment, refer to:
- Flutter documentation: https://docs.flutter.dev
- Play Console support: https://support.google.com/googleplay/android-developer

Good luck with your deployment! 🚀

