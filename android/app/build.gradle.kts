plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bmt.app"
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
        applicationId = "com.bmt.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"

    productFlavors {
        create("client") {
            dimension = "app"
            applicationId = "com.bmt.client"
            resValue("string", "app_name", "EasyWay")
            manifestPlaceholders["appName"] = "EasyWay"
            manifestPlaceholders["appIcon"] = "@mipmap/launcher_icon"
        }

        create("captain") {
            dimension = "app"
            applicationId = "com.bmt.captain"
            resValue("string", "app_name", "EasyWay Captain")
            manifestPlaceholders["appName"] = "EasyWay Captain"
            manifestPlaceholders["appIcon"] = "@mipmap/launcher_icon"
        }

        create("dashboard") {
            dimension = "app"
            applicationId = "com.bmt.dashboard"
            resValue("string", "app_name", "BMT Dashboard")
            manifestPlaceholders["appName"] = "BMT Dashboard"
            manifestPlaceholders["appIcon"] = "@mipmap/launcher_icon"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
