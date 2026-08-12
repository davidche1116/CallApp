allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.configureEach {
        if (name.matches(Regex("extract.*Annotations"))) {
            onlyIf {
                val variant = name.removePrefix("extract").removeSuffix("Annotations").lowercase()
                val recipe = project.layout.buildDirectory
                    .dir("intermediates/annotations_typedef_file/$variant/$name/typedefs.txt")
                    .get().asFile
                recipe.parentFile.mkdirs()
                recipe.writeText("")
                false
            }
        } else if (name.contains("lint", ignoreCase = true)) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
