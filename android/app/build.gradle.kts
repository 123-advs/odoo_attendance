plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tcs.odoo_attendance"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tcs.odoo_attendance"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // tflite_flutter requires that the .tflite model asset is NOT
    // compressed, otherwise the interpreter can't mmap it at runtime.
    androidResources {
        noCompress.add("tflite")
    }

    // Some Android distributions can't load TFLite's native .so when
    // packed in legacy mode. Forcing legacy packaging keeps the .so
    // files extractable so dlopen() finds them.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    // Force the bundled native libtensorflowlite_jni.so. tflite_flutter
    // 0.11.0 should pull this transitively, but on some Gradle setups
    // the native artifact isn't picked up — declaring it explicitly is
    // a safe redundancy.
    implementation("org.tensorflow:tensorflow-lite:2.16.1")
}

flutter {
    source = "../.."
}
