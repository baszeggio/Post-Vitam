plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

android {
    namespace = "com.example.pou_application_1"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pou_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
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

// Copia o APK gerado para um nome amigável (sem remover o original)
// Ex.: build/app/outputs/flutter-apk/PostVitam-release.apk
tasks.register<Copy>("copyReleaseApkAsPostVitam") {
    from(layout.buildDirectory.file("outputs/apk/release/app-release.apk"))
    into(layout.buildDirectory.dir("outputs/flutter-apk"))
    rename { _ -> "PostVitam-release.apk" }
    onlyIf { layout.buildDirectory.file("outputs/apk/release/app-release.apk").get().asFile.exists() }
}

// Também para debug
tasks.register<Copy>("copyDebugApkAsPostVitam") {
    from(layout.buildDirectory.file("outputs/apk/debug/app-debug.apk"))
    into(layout.buildDirectory.dir("outputs/flutter-apk"))
    rename { _ -> "PostVitam-debug.apk" }
    onlyIf { layout.buildDirectory.file("outputs/apk/debug/app-debug.apk").get().asFile.exists() }
}

// Encadeia apenas após todas as tasks estarem criadas
afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("copyReleaseApkAsPostVitam")
    tasks.findByName("assembleDebug")?.finalizedBy("copyDebugApkAsPostVitam")
}