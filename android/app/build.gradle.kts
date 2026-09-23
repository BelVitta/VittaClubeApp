plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val mercadoPagoPublicKey = providers.gradleProperty("MERCADOPAGO_PUBLIC_KEY")
    .orElse(providers.environmentVariable("MERCADOPAGO_PUBLIC_KEY"))
    .getOrElse("")

android {
    namespace = "com.example.vita_clube"
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
        applicationId = "com.example.vita_clube"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Mercado Pago Core Methods requires 23; the current Flutter
        // integration_test plugin requires 24, so the effective floor is 24.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField(
            "String",
            "MERCADOPAGO_PUBLIC_KEY",
            "\"${mercadoPagoPublicKey.replace("\"", "\\\"")}\"",
        )
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.mercadopago.android.sdk:sdk-android-bom:1.0.0"))
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("com.mercadopago.android.sdk:core-methods")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
}

flutter {
    source = "../.."
}
