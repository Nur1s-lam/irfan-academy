import java.io.File

// Use plain File paths to avoid potential compatibility issues with Gradle/Kotlin layout APIs
val sharedBuildDir: File = rootProject.projectDir.resolve("../build")
rootProject.buildDir = sharedBuildDir

subprojects {
    repositories {
        google()
        mavenCentral()
    }

    buildDir = File(rootProject.buildDir, project.name)
}
