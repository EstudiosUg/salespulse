# Verify Permissions Removed

After building your app bundle, you can verify that READ_MEDIA_IMAGES and READ_MEDIA_VIDEO are NOT in the final build:

## Method 1: Check in Google Play Console
1. Upload the new app bundle
2. Go to: Release → Production → [Your Release] → App Bundle Explorer
3. Click on your AAB file
4. Go to "Permissions" tab
5. Verify READ_MEDIA_IMAGES and READ_MEDIA_VIDEO are NOT listed

## Method 2: Use bundletool (Command Line)
```bash
# Extract the APK from AAB
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=output.apks --mode=universal

# Unzip and check manifest
unzip output.apks -d output
aapt dump permissions output/universal.apk
```

## Method 3: Android Studio
1. Open build/app/outputs/bundle/release/app-release.aab
2. Drag into Android Studio
3. Check the merged manifest for permissions

## Expected Result
✅ android.permission.INTERNET - SHOULD BE PRESENT
✅ android.permission.POST_NOTIFICATIONS - SHOULD BE PRESENT  
✅ android.permission.VIBRATE - SHOULD BE PRESENT
❌ android.permission.READ_MEDIA_IMAGES - SHOULD BE REMOVED
❌ android.permission.READ_MEDIA_VIDEO - SHOULD BE REMOVED
❌ android.permission.READ_EXTERNAL_STORAGE - SHOULD BE REMOVED

If they're still showing up, Google Play will show the warning and you'll need to use the justification text provided.

