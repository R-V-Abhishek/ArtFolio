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
        applicationId = "com.artfolio"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey ?: ""
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
