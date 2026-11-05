import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter sends --dart-define[-from-file] values to Gradle as base64 entries.
// Only public client configuration belongs here; keep Facebook App Secret on the backend.
val socialDefines = (project.findProperty("dart-defines") as? String)
    ?.split(',')
    ?.filter { it.isNotBlank() }
    ?.mapNotNull {
        val pair = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
            .split('=', limit = 2)
        if (pair.size == 2) pair[0] to pair[1] else null
    }?.toMap() ?: emptyMap()
val localSocialJson = project.file("../../social-auth.local.json")
val localSocialDefines = if (localSocialJson.exists()) {
    try {
        @Suppress("UNCHECKED_CAST")
        (groovy.json.JsonSlurper().parseText(localSocialJson.readText(Charsets.UTF_8)) as? Map<String, String>) ?: emptyMap()
    } catch (_: Exception) {
        emptyMap()
    }
} else emptyMap()
val facebookAppId = (socialDefines["FACEBOOK_APP_ID"]
    ?: localSocialDefines["FACEBOOK_APP_ID"]
    ?: "1753843223411204").ifBlank { "1753843223411204" }
val facebookClientToken = (socialDefines["FACEBOOK_CLIENT_TOKEN"]
    ?: localSocialDefines["FACEBOOK_CLIENT_TOKEN"]
    ?: "4f8754f686ed5593e176ff3219dc98e6").ifBlank { "4f8754f686ed5593e176ff3219dc98e6" }
val facebookConfigured = facebookAppId.matches(Regex("[1-9][0-9]+")) &&
    facebookClientToken.isNotBlank()

android {
    namespace = "com.example.cstore_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
buildFeatures {
        resValues = true
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.cstore_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Nonempty placeholders let the SDK register without real provider credentials.
        // Dart blocks Facebook login until real client configuration is present.
        resValue("string", "facebook_app_id", if (facebookConfigured) facebookAppId else "0")
        resValue("string", "facebook_client_token", if (facebookConfigured) facebookClientToken else "not-configured")
        resValue("string", "fb_login_protocol_scheme", "fb${if (facebookConfigured) facebookAppId else "0"}")
        manifestPlaceholders["facebookAutoInitEnabled"] = facebookConfigured.toString()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
