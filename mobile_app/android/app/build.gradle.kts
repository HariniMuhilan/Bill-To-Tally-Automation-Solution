import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

fun signingProp(propName: String, envName: String): String? {
    val fromFile = keystoreProperties.getProperty(propName)?.trim()
    if (!fromFile.isNullOrEmpty()) return fromFile
    val fromEnv = System.getenv(envName)?.trim()
    return if (!fromEnv.isNullOrEmpty()) fromEnv else null
}

val releaseStoreFilePath = signingProp("storeFile", "KEYSTORE_FILE")
val releaseStorePassword = signingProp("storePassword", "KEYSTORE_PASSWORD")
val releaseKeyAlias = signingProp("keyAlias", "KEY_ALIAS")
val releaseKeyPassword = signingProp("keyPassword", "KEY_PASSWORD")
val releaseStoreFile = releaseStoreFilePath?.let { rootProject.file(it) }
val hasReleaseSigning =
    releaseStoreFile != null &&
        releaseStoreFile.exists() &&
        !releaseStorePassword.isNullOrEmpty() &&
        !releaseKeyAlias.isNullOrEmpty() &&
        !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "com.origentech.billtotally.mobile_app"
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
        applicationId = "com.origentech.billtotally.mobile_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Fail-closed: never fall back to debug signing on Play Store release builds.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

gradle.taskGraph.whenReady {
    val runningReleasePackaging = allTasks.any { task ->
        task.path.endsWith(":assembleRelease") ||
            task.path.endsWith(":bundleRelease") ||
            task.path.endsWith(":packageRelease") ||
            task.path.endsWith(":packageReleaseBundle")
    }
    if (runningReleasePackaging && !hasReleaseSigning) {
        throw GradleException(
            "Android release signing is not configured. Copy android/key.properties.example to " +
                "android/key.properties (or set KEYSTORE_FILE, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD) " +
                "before building a Play Store release."
        )
    }
}

flutter {
    source = "../.."
}
