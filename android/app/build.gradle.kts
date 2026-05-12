import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties if it exists (local builds)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.vallejoj.megavital"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // CI (Codemagic) takes priority via env vars; fallback to key.properties for local builds
            val ciKeystoreFile = System.getenv("CM_KEYSTORE_PATH")
            val ciKeystorePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            val ciKeyAlias = System.getenv("CM_KEY_ALIAS")
            val ciKeyPassword = System.getenv("CM_KEY_PASSWORD")

            if (ciKeystoreFile != null && ciKeystorePassword != null && ciKeyAlias != null && ciKeyPassword != null) {
                storeFile = file(ciKeystoreFile)
                storePassword = ciKeystorePassword
                this.keyAlias = ciKeyAlias
                this.keyPassword = ciKeyPassword
            } else if (keyPropertiesFile.exists()) {
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                this.keyAlias = keyProperties["keyAlias"] as String
                this.keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.vallejoj.megavital"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val hasReleaseSigning = System.getenv("CM_KEYSTORE_PATH") != null || keyPropertiesFile.exists()
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
