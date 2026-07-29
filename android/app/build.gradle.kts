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
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.example.nearcart"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    defaultConfig {
        applicationId = "com.example.nearcart"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions.add("app")

    productFlavors {
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
        }
        create("production") {
            dimension = "app"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}