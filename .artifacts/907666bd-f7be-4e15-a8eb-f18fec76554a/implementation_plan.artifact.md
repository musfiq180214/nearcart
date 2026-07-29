# Update Gradle, AGP, Kotlin, and Android SDK versions

The project is running on Flutter's `master` channel, which requires newer versions of build tools and SDKs than those currently configured. This plan updates the project to meet the requirements reported by the Flutter tool.

## User Review Required

> [!IMPORTANT]
> The `compileSdk` version is being set to `2147483647` (Integer.MAX_VALUE) as specifically recommended by the Flutter tool on the `master` channel. This is likely used to support the latest preview Android SDKs.

## Proposed Changes

### Android Build Configuration

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/gradle/wrapper/gradle-wrapper.properties)
- Upgrade Gradle version from `8.14` to `9.1.0`.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/settings.gradle.kts)
- Upgrade Android Gradle Plugin (AGP) from `8.11.1` to `9.0.1`.
- Upgrade Kotlin Gradle Plugin (KGP) from `2.2.20` to `2.3.20`.

#### [MODIFY] [app/build.gradle.kts](file:///C:/Users/Admin/Desktop/Projects/nearcart/android/app/build.gradle.kts)
- Update `compileSdk` to `2147483647` to resolve plugin compatibility issues.

## Verification Plan

### Manual Verification
- Run `flutter run --flavor staging -t lib/main_staging.dart` and verify that the warnings and errors regarding Gradle, AGP, Kotlin, and SDK versions are gone.
