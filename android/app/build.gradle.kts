import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.estudios.ug.salespulse"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Unique Application ID for Play Store
        applicationId = "com.estudios.ug.salespulse"
        // Minimum SDK version for modern Android features (Android 5.0+)
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 6
        versionName = "1.0.5"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists() && keystoreProperties.getProperty("storeFile") != null) {
                val keystoreFile = file(keystoreProperties.getProperty("storeFile"))
                if (keystoreFile.exists()) {
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                    storeFile = keystoreFile
                    storePassword = keystoreProperties.getProperty("storePassword")
                }
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore exists and is valid, otherwise use debug for testing
            signingConfig = if (keystorePropertiesFile.exists() && 
                               keystoreProperties.getProperty("storeFile") != null &&
                               file(keystoreProperties.getProperty("storeFile")).exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Enable code minification and resource shrinking to reduce APK size
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
