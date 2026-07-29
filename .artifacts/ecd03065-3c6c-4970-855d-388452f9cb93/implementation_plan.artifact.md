# Upgrade Android Build Tools and Fix SDK Compatibility

The build is failing due to a combination of outdated build tools (Gradle, AGP, Kotlin) and a specific SDK version requirement (`2147483647`) from modern Firebase/Geolocator plugins.

## Proposed Changes

### 1. Upgrade Build Tools
We will upgrade the build tools to the versions recommended by the Flutter tool to ensure compatibility with the latest Android SDKs.

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/gradle/wrapper/gradle-wrapper.properties)
- Upgrade Gradle from `8.14` to `9.1.0`.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/settings.gradle.kts)
- Upgrade Android Gradle Plugin (AGP) from `8.11.1` to `9.0.1`.
- Upgrade Kotlin Gradle Plugin (KGP) from `2.2.20` to `2.3.20`.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/build.gradle.kts) (root)
- Upgrade Google Services plugin from `4.3.15` to `4.4.2`.

### 2. Fix SDK Versioning
We will attempt to use the `Baklava` preview codename or the specific `36` SDK with the upgraded tools.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/app/build.gradle.kts)
- Set `compileSdkPreview = "Baklava"` (or `compileSdk = 36`) and `targetSdkPreview = "Baklava"`.
- We will avoid `2147483647` as a literal number since it caused path resolution issues previously, unless the upgraded AGP handles it differently.

## Verification Plan

### Automated Tests
- Run `flutter clean` to ensure a fresh build state.
- Run `flutter run --flavor staging -t lib/main_staging.dart`.

### Manual Verification
- Verify that the app launches on the emulator.
