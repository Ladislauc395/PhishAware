plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")  // nome completo, como no novo
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.phishing"  // mude para o seu pacote real se quiser

    compileSdk = flutter.compileSdkVersion     // ← volte para isso!
    ndkVersion = flutter.ndkVersion            // mantenha se tiver

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {                            // correto, como você já tem
        jvmTarget = "17"                       // ou JavaVersion.VERSION_17.toString() se preferir
    }

    defaultConfig {
        applicationId = "com.example.phishing" // mude para único seu

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {                 // ou release { ... } se for Groovy
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
