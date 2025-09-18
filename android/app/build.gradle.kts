import java.util.Properties

plugins {
    id("com.android.application")
    // (Google Services plugin applied conditionally below to allow placeholder builds)
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply Google Services plugin ONLY if a real google-services.json is present (not a placeholder)
// This prevents build failures ("Missing project_info object") when using a dummy file.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    val text = googleServicesFile.readText()
    val looksPlaceholder = listOf("placeholder-project", "AIplaceholderKEY1234567890").any { text.contains(it) }
    if (!looksPlaceholder) {
        apply(plugin = "com.google.gms.google-services")
        println("Applying Google Services plugin (real google-services.json detected)")
    } else {
        println("Skipping Google Services plugin: placeholder google-services.json detected")
    }
} else {
    println("Skipping Google Services plugin: no google-services.json file found")
}

android {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }
    val mapsApiKey = localProperties.getProperty("MAPS_API_KEY")
    
    namespace = "com.artfolio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        // Suppress deprecation warnings
        freeCompilerArgs += "-Xsuppress-version-warnings"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.artfolio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey ?: ""
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
