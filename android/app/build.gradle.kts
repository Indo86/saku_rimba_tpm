plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace    = "com.example.saku_rimba"
    compileSdk   = flutter.compileSdkVersion
    ndkVersion   = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.saku_rimba"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    compileOptions {
        sourceCompatibility        = JavaVersion.VERSION_11
        targetCompatibility        = JavaVersion.VERSION_11
        // ─────────┬──────────────┬──────────────────────────
        //           ↓              ↓
        // Aktifkan core-library desugaring:
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    
}

dependencies {
    // Tambahkan baris ini di module 'app'!
     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
