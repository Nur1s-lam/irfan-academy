allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.projectDirectory.dir("../build").asFile
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
