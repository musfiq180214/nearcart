import kotlin.text.contains
import kotlin.text.filter
import kotlin.text.forEach
import kotlin.text.lowercase
import kotlin.text.startsWith
import kotlin.text.substringAfter

project.afterEvaluate {
    tasks.filter { it.name.startsWith("compileFlutterBuild") }.forEach { task ->
        val flavor = task.name.substringAfter("compileFlutterBuild").lowercase()
        if (flavor.contains("staging")) {
            (task as? com.flutter.gradle.tasks.FlutterTask)?.let { it.targetPath = "lib/main_staging.dart" }
        } else if (flavor.contains("production")) {
            (task as? com.flutter.gradle.tasks.FlutterTask)?.let { it.targetPath = "lib/main_production.dart" }
        }
    }
}
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))


    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")


    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}

android {
    namespace = "com.example.nearcart"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nearcart"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Changed "default" to "app" to match the flavors below
    flavorDimensions.add("app")

    productFlavors {
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Near Cart Staging")
        }
        create("production") {
            dimension = "app"
            resValue("string", "app_name", "Near Cart")
        }
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}