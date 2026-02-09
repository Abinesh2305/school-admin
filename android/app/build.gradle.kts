import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.clasteq.admin"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
    applicationId = "com.clasteq.admin"

    minSdk = flutter.minSdkVersion
    targetSdk = 34

    versionCode = flutter.versionCode
    versionName = flutter.versionName

    multiDexEnabled = true
    manifestPlaceholders["appName"] = "ClasteqSMS"
}


    signingConfigs {
        create("release") {
            storeFile = file(project.property("MY_KEYSTORE_FILE") as String)
            storePassword = project.property("MY_STORE_PASSWORD") as String
            keyAlias = project.property("MY_KEY_ALIAS") as String
            keyPassword = project.property("MY_KEY_PASSWORD") as String
        }
    }


    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // debug uses default signing config
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
