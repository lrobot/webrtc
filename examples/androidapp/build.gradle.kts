import org.jetbrains.kotlin.cli.jvm.main

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.jetbrains.kotlin.android)
}

android {
    namespace = "org.appspot.apprtc"
    compileSdk = 34

    defaultConfig {
        applicationId = "org.appspot.apprtc"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
	sourceSets {
		getByName("main") {
			java.srcDirs("src")
			res.srcDirs("res", "extraRes1") // 添加额外的res目录
			jniLibs.srcDirs("_jniLibs")
			manifest.srcFile("AndroidManifest.xml")
		}
	}
}


// _jniLibs/arm64-v8a
// _jniLibs/armeabi-v7a
// _jniLibs/x86
// _libs/libwebrtc.jar


tasks.register<Copy>("prepareCopylibs") {

	from(file("../../out/debug/android/_libout/") ) // when src dir not exist, task just resport "NO-SOURCE" status and go on
	into(file(".")) // 指定目标目录

	include("_jniLibs/**")
	include("_libs/**")
	// exclude("**/*.md") // 例如，可以排除某些文件
	doFirst {
		println("CopyFile start")
	}

	doLast {
		println("CopyFile Done")
	}
}
// 确保prepareCopylibs任务在assemble任务之前执行
tasks.named("preBuild") {
	dependsOn("prepareCopylibs")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
	implementation(fileTree(mapOf("include" to listOf("*.aar", "*.jar"),"dir" to "_libs/")))
	implementation(fileTree(mapOf("include" to listOf("*.aar", "*.jar"),"dir" to "third_party/autobanh/lib")))
	testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
